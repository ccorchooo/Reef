pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Coral's wake word: "hey Coral" / "oye Coral" (also "ok", "hola") starts voice mode,
// hands-free.
// Off until Settings → Coral → Wake word (hands-free); never while locked or while voice
// mode runs.
//
// One ffmpeg keeps the microphone (as "Reef wake word", which the mic-in-use activity
// leaves out) in a ring of 0.5 s raw chunks under $XDG_RUNTIME_DIR/reef/wake and prints its
// loudness about 20 times a second. A burst of speech (louder than coral.silenceDb, then
// quiet for wakeGapMs) of wakeMinMs..wakeMaxMs is cut from the ring and written down:
//   local  whisper-server with the tiny model (ggml-tiny*.bin), kept loaded while on,
//          on 127.0.0.1:coral.wakePort, biased toward the phrase with --prompt
//   cloud  coral.cloud's /audio/transcriptions (sends that burst, nothing else)
// If it starts with the phrase, voice mode starts; anything said after it in the same
// breath ("hey Coral, set a timer for ten minutes") goes to Coral straight away.
Singleton {
    id: root

    readonly property var options: Config.options.coral
    readonly property bool cloud: options?.wakeWith === "cloud"
    readonly property bool ready: cloud ? Coral.hasKey : (CoralVoice.serverBin !== "" && CoralVoice.tinyModel !== "")
    // On, and able to (the model stays loaded meanwhile).
    readonly property bool on: (options?.wake ?? false) && (options?.voice ?? true) && ready && !Lock.locked
    // Listening for the phrase now (not during voice mode, which has the mic).
    readonly property bool listening: on && !CoralVoice.active && !_cooling
    readonly property string runDir: CoralVoice.runDir
    readonly property int port: options?.wakePort ?? 39471
    readonly property string missing: cloud ? (Coral.hasKey ? "" : "a cloud API key")
        : [CoralVoice.serverBin === "" ? "whisper-server (whisper.cpp)" : "", CoralVoice.tinyModel === "" ? "the tiny model (ggml-tiny*.bin) in " + CoralVoice.voiceDir : ""].filter(s => s).join(", ")

    // What whisper writes for "Coral", and words that can't be a greeting before it.
    readonly property var _names: ["coral", "corral", "koral", "korral", "choral", "corall", "coraal", "carol", "karol", "carl", "karl"]
    readonly property var _articles: ["the", "a", "an", "my", "this", "that", "el", "la", "los", "las", "un", "una", "de", "del", "mi", "tu", "su", "este", "esta"]

    // A little quiet after voice mode, so Coral's own last words don't wake it.
    property bool _cooling: false
    Timer {
        id: cool
        interval: 1500
        onTriggered: root._cooling = false
    }
    Connections {
        target: CoralVoice
        function onActiveChanged() {
            if (!CoralVoice.active) {
                root._cooling = true;
                cool.restart();
            }
        }
    }

    // Helpers die with the shell: setpriv --pdeathsig has the kernel signal them when their
    // parent (Quickshell) goes, a crash included; a reload stops them directly (each execs
    // into the real program, so stopping the Process stops it).
    readonly property var _tie: ["setpriv", "--pdeathsig", "TERM"]

    // ── the ear ─────────────────────────────────────────────────
    Process {
        id: ear
        running: root.listening
        command: ["sh", "-c", "mkdir -p \"$1/wake\" && rm -f \"$1\"/wake/*.raw; exec setpriv --pdeathsig TERM "
                + "ffmpeg -nostdin -hide_banner -loglevel error -nostats -f pulse -name 'Reef wake word' -i default -ac 1 -ar 16000 "
                + "-filter_complex '[0:a]asplit[r][m];[m]astats=metadata=1:reset=1,ametadata=mode=print:key=lavfi.astats.Overall.RMS_level:file=-:direct=1,anullsink' "
                + "-map '[r]' -c:a pcm_s16le -f segment -segment_time 0.5 -segment_wrap 20 -segment_format s16le \"$1/wake/%02d.raw\"", "sh", root.runDir]
        stdout: SplitParser {
            onRead: line => root._onLevel(line)
        }
    }

    property bool _inBurst: false
    property real _burstStart: 0
    property real _lastLoud: 0

    property var _room: ({})
    // The room's background level (dB), for voice mode to start from.
    readonly property var floor: _floor
    property var _floor: undefined

    function _onLevel(line) {
        const db = CoralVoice.dbOf(line);
        if (isNaN(db) || !listening)
            return;
        const now = Date.now();
        const speech = CoralVoice.isSpeech(db, _room, _inBurst);
        _floor = _room.floor;
        if (speech) {
            if (!_inBurst) {
                _inBurst = true;
                _burstStart = now;
            }
            _lastLoud = now;
            return;
        }
        if (_inBurst && now - _lastLoud > (options?.wakeGapMs ?? 450)) {
            _inBurst = false;
            const length = _lastLoud - _burstStart;
            if (length >= (options?.wakeMinMs ?? 400) && length <= (options?.wakeMaxMs ?? 7000))
                _check(_burstStart);
        }
    }

    // ── writing a burst down ────────────────────────────────────
    function _check(start) {
        if (hear.running)
            return;   // still on the last one
        // The chunks written since a little before the burst began, oldest first.
        const since = ((start - 600) / 1000).toFixed(3);
        const cut = "for f in \"$1\"/wake/*.raw; do echo \"$(stat -c %.9Y \"$f\") $f\"; done | sort -n "
            + "| awk -v t=" + since + " '$1 >= t {print $2}' | xargs -r cat "
            + "| ffmpeg -v error -f s16le -ar 16000 -ac 1 -i - -y \"$1/wake.wav\" && ";
        hear._out = "";
        if (cloud) {
            const args = ["-m", "20", "-F", "file=@" + runDir + "/wake.wav", "-F", "model=" + options.cloud.listenModel,
                "-F", "response_format=verbose_json", "-F", "prompt=Hey Coral. Oye Coral."];
            const req = Coral.curl(true, options.cloud.endpoint, "audio/transcriptions", args);
            // Coral.curl is ["sh", "-c", script, "sh", …args]: run the cut, then it.
            hear.command = ["sh", "-c", cut + "scr=$2; shift 2; exec sh -c \"$scr\" \"$@\"", "sh", runDir, req[2]].concat(req.slice(3));
        } else {
            hear.command = ["sh", "-c", cut + "exec curl -sS -m 20 -F file=@\"$1/wake.wav\" -F response_format=json -F temperature=0 http://127.0.0.1:" + port + "/inference", "sh", runDir];
        }
        hear.running = true;
    }

    Process {
        id: hear
        property string _out: ""
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => hear._out += data
        }
        onExited: {
            if (!root.listening)
                return;
            let text = "", lang = "";
            try {
                const r = JSON.parse(_out);
                text = r.text ?? "";
                lang = CoralVoice._code(r.language ?? "");
            } catch (e) {
                return;
            }
            root._match(text, lang);
        }
    }

    // Lowercase without accents, the same length as the text (so indexes carry over).
    function _plain(text) {
        return text.toLowerCase()
            .replace(/[áàä]/g, "a").replace(/[éèë]/g, "e").replace(/[íìï]/g, "i").replace(/[óòö]/g, "o").replace(/[úùü]/g, "u");
    }
    function _words(text) {
        return text.split(/\s+/).filter(w => /[0-9A-Za-z\u00C0-\u024F]/.test(w)).length;
    }
    // Where the wake phrase ends in `text`, or -1. "Coral" as the first word, or the second
    // after a short word that isn't an article: "hey/oye/ok Coral", what whisper makes of
    // them ("Ajay Coral"), or just "Coral, …"; not "the coral reef" or "la coral".
    function _wakeEnd(text) {
        const plain = _plain(text);
        const re = /[a-zñ']+/g;
        const words = [];
        for (let m; (m = re.exec(plain)) !== null && words.length < 3;)
            words.push({ w: m[0], end: m.index + m[0].length });
        for (let i = 0; i < Math.min(2, words.length); i++) {
            if (!_names.includes(words[i].w))
                continue;
            if (i === 0 || (words[0].w.length <= 6 && !_articles.includes(words[0].w)))
                return words[i].end;
        }
        return -1;
    }
    // The text after the wake phrase (and any repeat of it whisper added).
    function strip(text) {
        let rest = text;
        for (let end; (end = _wakeEnd(rest)) >= 0;)
            rest = rest.slice(end).replace(/^[\s,.!?¡¿;:-]+/, "");
        return rest.replace(/\s+/g, " ").trim();
    }

    function _match(text, lang) {
        if (_wakeEnd(text) < 0)
            return;
        heard(text);
        // More was said in the same breath: the tiny model only spotted the phrase, so the
        // clip goes through the real speech-to-text (cloud or local) for the request.
        if (_words(strip(text)) >= 2)
            CoralVoice.fromClip(runDir + "/wake.wav");
        else
            CoralVoice.start();
    }
    signal heard(string text)

    // ── the local model, loaded while listening ─────────────────
    Process {
        id: server
        running: root.on && !root.cloud
        command: root._tie.concat([CoralVoice.serverBin, "-m", CoralVoice.tinyModel, "--host", "127.0.0.1", "--port", String(root.port),
            "-t", "2", "-l", "auto", "-nf", "-ac", "384", "--prompt", "Hey Coral. Oye Coral."])
    }
}
