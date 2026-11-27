pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.theme

// Coral's voice mode (SURFACES.md → Coral → Voice). Listens, writes down what was said,
// asks Coral, and speaks the reply.
//
//   CoralVoice.start()    // Super+A, the mic in the Coral tab
//   CoralVoice.done()     // Stop while listening: that's all I'm saying
//   CoralVoice.cancel()   // Escape, Stop otherwise
//
//   listening     ffmpeg records the default source (16 kHz mono) and prints its RMS level
//                 about 20 times a second; it stops by itself after silenceMs of quiet
//                 once speech was heard (or noSpeechMs with nothing, or maxListenMs)
//   transcribing  whisper-cli (whisper.cpp), or the cloud's /audio/transcriptions
//                 (coral.listen = "cloud", e.g. Groq's whisper-large-v3-turbo), with the
//                 language detected
//   thinking      Coral.ask(transcript), streaming as in chat
//   speaking      piper (or the cloud's /audio/speech when coral.speech = "cloud" and the
//                 cloud voice speaks that language) renders the reply, ffmpeg
//                 plays it in real time and prints its level again (the Pearl pulses)
//
// Models live in coral.voiceDir (default ~/.local/share/reef/voice): the first ggml-*.bin
// is whisper's; each <lang>_<REGION>-<name>-<quality>.onnx (with its .onnx.json) is a
// piper voice for <lang>. Local parts send nothing anywhere; cloud parts send the
// recording or the reply's text to coral.cloud only.
Singleton {
    id: root

    readonly property var options: Config.options.coral

    // idle | listening | transcribing | thinking | speaking
    property string phase: "idle"
    readonly property bool active: phase !== "idle"
    // The monitor it shows on (the focused one when it started).
    property string screen: ""
    // 0..1, the voice's loudness while listening or speaking.
    property real level: 0
    property bool heard: false
    property string transcript: ""
    property string language: ""

    // ── what's installed ────────────────────────────────────────
    // Settings, with their defaults: a reload that changes Config's shape can leave these
    // unread for a moment, and an undefined threshold would never hear anyone.
    readonly property real silenceDb: options?.silenceDb ?? -42
    readonly property real marginDb: options?.speechMarginDb ?? 10
    readonly property int silenceMs: options?.silenceMs ?? 1400
    readonly property int noSpeechMs: options?.noSpeechMs ?? 8000
    readonly property int maxListenMs: options?.maxListenMs ?? 30000
    readonly property string listenLanguage: options?.listenLanguage || "auto"

    readonly property string voiceDir: (options?.voiceDir ?? "") !== "" ? options.voiceDir
        : (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/reef/voice"
    readonly property string runDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/reef"
    property string sttBin: ""
    property string ttsBin: ""
    property string sttModel: ""
    property string serverBin: ""        // whisper-server, for the wake word
    property string tinyModel: ""        // ggml-tiny*.bin, for the wake word
    property var voices: ({})            // "es" → ".../es_AR-daniela-high.onnx"
    // Local or cloud (coral.listen, coral.speech); the cloud is coral.cloud with Coral's key.
    readonly property bool cloudListen: options?.listen === "cloud"
    readonly property bool cloudSpeech: options?.speech === "cloud"
    readonly property bool localListen: sttBin !== "" && sttModel !== ""
    readonly property bool localSpeak: ttsBin !== "" && Object.keys(voices).length > 0
    readonly property bool canListen: cloudListen ? Coral.hasKey : localListen
    readonly property bool canSpeak: (cloudSpeech && Coral.hasKey) || localSpeak
    readonly property bool available: (options?.voice ?? true) && canListen
    // What's missing, for Settings → Coral.
    readonly property string missing: [
        cloudListen && !Coral.hasKey ? "a cloud API key" : "",
        !cloudListen && sttBin === "" ? "whisper-cli (whisper.cpp)" : "",
        !cloudListen && sttModel === "" ? "a whisper model (ggml-*.bin) in " + voiceDir : "",
        cloudSpeech && !Coral.hasKey ? "a cloud API key" : "",
        !cloudSpeech && ttsBin === "" ? "piper" : "",
        !cloudSpeech && Object.keys(voices).length === 0 ? "a piper voice (*.onnx) in " + voiceDir : ""
    ].filter((s, i, all) => s !== "" && all.indexOf(s) === i).join(", ")

    // whisper's language names (the cloud reports "Spanish") → codes.
    readonly property var _codes: ({ english: "en", spanish: "es", portuguese: "pt", french: "fr", german: "de", italian: "it", catalan: "ca", dutch: "nl", russian: "ru", japanese: "ja", chinese: "zh", korean: "ko", arabic: "ar" })
    function _code(lang) {
        lang = (lang ?? "").toLowerCase();
        return _codes[lang] ?? (lang.length === 2 ? lang : "");
    }

    function rescan() {
        scan._out = "";
        scan.command = ["sh", "-c", "for b in whisper-cli whisper-cpp; do p=$(command -v $b) && { echo \"stt $p\"; break; }; done; "
            // Arch's AUR package calls it piper-tts (extra/piper is a mouse app); a plain
            // `piper` counts only if it takes a voice model.
            + "if p=$(command -v piper-tts); then echo \"tts $p\"; elif p=$(command -v piper) && \"$p\" --help 2>&1 | grep -q -- --model; then echo \"tts $p\"; fi; "
            + "p=$(command -v whisper-server) && echo \"server $p\"; "
            + "for f in \"$1\"/ggml-*.bin; do [ -f \"$f\" ] && echo \"model $f\"; done; "
            + "for f in \"$1\"/*.onnx; do [ -f \"$f\" ] && [ -f \"$f.json\" ] && echo \"voice $f\"; done; true", "sh", voiceDir];
        scan.running = true;
    }
    Component.onCompleted: rescan()
    onVoiceDirChanged: rescan()

    Process {
        id: scan
        property string _out: ""
        stdout: SplitParser {
            onRead: line => scan._out += line + "\n"
        }
        onExited: {
            let stt = "", tts = "", model = "", server = "", tiny = "";
            const v = {};
            for (const line of _out.split("\n")) {
                const i = line.indexOf(" ");
                const kind = line.slice(0, i), path = line.slice(i + 1);
                if (kind === "stt")
                    stt = path;
                else if (kind === "tts")
                    tts = path;
                else if (kind === "server")
                    server = path;
                else if (kind === "model" && /ggml-tiny/.test(path))
                    tiny = path;
                else if (kind === "model" && model === "")
                    model = path;
                else if (kind === "voice") {
                    const lang = path.split("/").pop().split(/[_-]/)[0];
                    if (lang && !v[lang])
                        v[lang] = path;
                }
            }
            root.sttBin = stt;
            root.ttsBin = tts;
            root.sttModel = model || tiny;
            root.serverBin = server;
            root.tinyModel = tiny;
            root.voices = v;
        }
    }

    // Music pauses while Coral listens and talks (it hears you, you hear it), and comes
    // back when it's done, only if it was Coral that paused it.
    property bool _pausedMedia: false
    onActiveChanged: {
        if (active && Media.playing) {
            Media.togglePlaying();
            _pausedMedia = true;
        } else if (!active && _pausedMedia) {
            _pausedMedia = false;
            if (!Media.playing)
                Media.togglePlaying();
        }
    }

    // ── the conversation ────────────────────────────────────────
    function start() {
        if (active)
            return;
        if (!available) {
            if (options.voice)
                Toasts.show({ text: "Coral's voice needs " + missing, icon: "mic_off" });
            Actions.islandRequested("coral");
            return;
        }
        Coral.stop();
        screen = Monitors.focused;
        _listen(noSpeechMs);
    }

    // Record until a pause after speech (or nothing for `wait` ms).
    property bool followingUp: false
    function _listen(wait) {
        transcript = "";
        language = "";
        heard = false;
        level = 0;
        phase = "listening";
        Sounds.play("listen");
        noSpeech.interval = wait;
        rec.command = ["sh", "-c", "mkdir -p \"$1\" && exec setpriv --pdeathsig TERM ffmpeg -nostdin -hide_banner -loglevel error -nostats -f pulse -i default -ac 1 -ar 16000 "
            + "-filter_complex '[0:a]asplit[r][m];[m]astats=metadata=1:reset=1,ametadata=mode=print:key=lavfi.astats.Overall.RMS_level:file=-:direct=1,anullsink' "
            + "-map '[r]' -y \"$1/coral-in.wav\"", "sh", runDir];
        rec.running = true;
        _listenStart = Date.now();
        _room = CoralWake.floor !== undefined ? { floor: CoralWake.floor } : {};
        noSpeech.restart();
        maxListen.restart();
    }

    // The wake word came with the request ("hey Coral, set a timer…"): write the clip down
    // and ask, without the phrase. Nothing left after it: listen as usual.
    property bool _fromWake: false
    function fromClip(path) {
        if (active || !available)
            return;
        Coral.stop();
        screen = Monitors.focused;
        transcript = "";
        language = "";
        heard = true;
        level = 0;
        phase = "transcribing";
        _fromWake = true;
        _listenStart = Date.now() - (options?.wakeMaxMs ?? 7000);
        _transcribe(path);
    }

    // Stop listening and use what was said (nothing heard: cancel).
    function done() {
        if (phase !== "listening")
            return;
        if (!heard) {
            cancel();
            return;
        }
        _stopRecording();
    }

    function cancel() {
        const was = phase;
        followingUp = false;
        phase = "idle";
        level = 0;
        silence.stop();
        noSpeech.stop();
        maxListen.stop();
        if (rec.running)
            rec.signal(15);
        if (stt.running)
            stt.running = false;
        if (synth.running)
            synth.running = false;
        if (play.running)
            play.running = false;
        if (was === "thinking")
            Coral.stop();
    }

    // Type instead: leave voice for the chat.
    function typeInstead() {
        cancel();
        Actions.islandRequested("coral");
    }

    function _stopRecording() {
        silence.stop();
        noSpeech.stop();
        maxListen.stop();
        phase = "transcribing";
        level = 0;
        // SIGINT lets ffmpeg finish the file.
        rec.signal(2);
    }

    // Speech is what stands out from the room: louder than silenceDb and marginDb above the
    // background (music, a fan), which `floor` follows: down at once, up slowly (~10 s), so
    // talking doesn't raise it much. Each listener keeps its own { floor }.
    function isSpeech(db, room, talking) {
        if (room.floor === undefined)
            room.floor = db;
        else if (db < room.floor)
            room.floor += (db - room.floor) * 0.3;
        else
            room.floor += (db - room.floor) * 0.005;
        // Once someone is talking, softer words still count (half the margin), so a quiet
        // syllable doesn't end the sentence.
        return db > Math.max(silenceDb, room.floor + (talking ? marginDb / 2 : marginDb));
    }
    // Readings in dB from an ffmpeg astats line, or NaN.
    function dbOf(line) {
        const m = line.match(/RMS_level=(-?[\d.]+|-inf)/);
        return !m ? NaN : m[1] === "-inf" ? -120 : parseFloat(m[1]);
    }
    property var _room: ({})

    function _onLevel(line) {
        const db = dbOf(line);
        if (isNaN(db))
            return;
        // The pulse shows loudness above the room, so music doesn't keep the Pearl jumping.
        root.level = Math.max(0, Math.min(1, (db - Math.max(silenceDb - 18, (_room.floor ?? -60)) ) / 40));
        if (phase !== "listening")
            return;
        if (isSpeech(db, _room, heard)) {
            heard = true;
            noSpeech.stop();
            silence.stop();
        } else if (heard && !silence.running) {
            silence.restart();
        }
    }

    Timer {
        id: silence
        interval: root.silenceMs
        onTriggered: root.done()
    }
    Timer {
        id: noSpeech
        interval: root.noSpeechMs
        onTriggered: {
            if (root.phase !== "listening" || root.heard)
                return;
            if (root.followingUp) {
                root.followingUp = false;
                root.cancel();
            } else {
                root.cancel();
                Toasts.show({ text: "I didn't hear anything", icon: "hearing" });
            }
        }
    }
    Timer {
        id: maxListen
        interval: root.maxListenMs
        onTriggered: root.done()
    }

    Process {
        id: rec
        stdout: SplitParser {
            onRead: line => root._onLevel(line)
        }
        onExited: {
            if (root.phase === "transcribing")
                root._transcribe();
        }
    }

    property real _listenStart: 0

    function _transcribe(file) {
        file = file ?? runDir + "/coral-in.wav";
        stt._out = "";
        if (cloudListen) {
            const lang = root.listenLanguage;
            stt.command = Coral.curl(true, options.cloud.endpoint, "audio/transcriptions",
                ["-m", "60", "-F", "file=@" + file, "-F", "model=" + options.cloud.listenModel,
                    "-F", "response_format=verbose_json"].concat(lang !== "auto" ? ["-F", "language=" + lang] : []));
            stt.running = true;
            return;
        }
        // whisper encodes a 30 s window by default; a window as long as the clip (50 frames
        // a second, with a margin) is much faster on a CPU. No temperature fallback either.
        const seconds = (Date.now() - _listenStart) / 1000;
        const ctx = Math.max(128, Math.min(1500, Math.ceil(seconds * 50) + 64));
        stt.command = ["sh", "-c", "\"$1\" -m \"$2\" -f \"$4\" -l " + root.listenLanguage
            + " -t $(nproc) -ac " + ctx + " -nf -oj -of \"$3/coral-in\" >/dev/null 2>&1 && cat \"$3/coral-in.json\"", "sh", sttBin, sttModel, runDir, file];
        stt.running = true;
    }

    Process {
        id: stt
        property string _out: ""
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => stt._out += data
        }
        onExited: {
            if (root.phase !== "transcribing")
                return;
            let text = "", lang = "", error = "";
            try {
                const r = JSON.parse(_out);
                // whisper-cli's JSON, or the cloud's verbose_json.
                lang = root._code(r.result?.language ?? r.language ?? "");
                text = r.transcription ? r.transcription.map(t => t.text).join(" ") : (r.text ?? "");
                error = r.error?.message ?? "";
            } catch (e) {
                error = root.cloudListen ? (_out.trim().split("\n")[0] || "no answer") : "";
            }
            if (error !== "") {
                root.cancel();
                Toasts.show({ text: "Couldn't write it down: " + error, icon: "error" });
                return;
            }
            // whisper marks noise as [BLANK_AUDIO], (music) and the like.
            text = text.replace(/\[[^\]]*\]|\([^)]*\)/g, " ").replace(/\s+/g, " ").trim();
            if (root._fromWake) {
                root._fromWake = false;
                text = CoralWake.strip(text);
                if (!/[0-9A-Za-z\u00C0-\u024F]/.test(text)) {
                    root.phase = "idle";
                    root.start();
                    return;
                }
            }
            // Punctuation alone ("." from a cough) isn't something said.
            if (!/[0-9A-Za-z\u00C0-\u024F]/.test(text)) {
                root.cancel();
                Toasts.show({ text: "I didn't catch that", icon: "hearing" });
                return;
            }
            root.transcript = text;
            root.language = lang;
            root.phase = "thinking";
            Coral.ask(text);
        }
    }

    // The reply is in: say it, or hand over to the chat.
    Connections {
        target: Coral
        function onStatusChanged() {
            if (Coral.status !== "idle" || root.phase !== "thinking")
                return;
            const last = Coral.messages[Coral.messages.length - 1];
            if (!last || last.role !== "assistant" || last.error || !root.options.speak || !root.canSpeak) {
                root._finish();
                return;
            }
            root._speak(last.text);
        }
    }

    // Markdown and code don't read aloud well: keep the words.
    function _spoken(text) {
        return text.replace(/```[\s\S]*?```/g, " ")
            .replace(/`([^`]*)`/g, "$1")
            .replace(/!?\[([^\]]*)\]\([^)]*\)/g, "$1")
            .replace(/[*_#>~|]/g, "")
            .replace(/\s+/g, " ").trim();
    }

    // The cloud voice when chosen and it speaks the language, else piper; a cloud error
    // falls back to piper.
    function _speak(text) {
        const words = _spoken(text);
        if (words === "") {
            _finish();
            return;
        }
        const cloudOk = cloudSpeech && Coral.hasKey && (language === "" || options.cloud.speechLanguages.includes(language));
        phase = "speaking";
        if (cloudOk)
            _synthCloud(words);
        else
            _synthLocal(words);
    }

    function _synthLocal(words) {
        const voice = voices[language] ?? voices[options.voiceLanguage] ?? voices[Object.keys(voices)[0]];
        if (!localSpeak || !voice) {
            _finish();
            return;
        }
        synth.cloud = false;
        synth.words = words;
        synth.input = words + "\n";
        synth.command = ["sh", "-c", "\"$1\" -m \"$2\" -f \"$3/coral-out.wav\" >/dev/null 2>&1 && echo 200", "sh", ttsBin, voice, runDir];
        synth.running = true;
    }

    function _synthCloud(words) {
        synth.cloud = true;
        synth.words = words;
        synth.input = JSON.stringify({ model: options.cloud.speechModel, voice: options.cloud.speechVoice, input: words, response_format: "wav" });
        synth.command = Coral.curl(true, options.cloud.endpoint, "audio/speech",
            ["-m", "60", "-X", "POST", "-H", "Content-Type: application/json", "--data-binary", "@-",
                "-o", runDir + "/coral-out.wav", "-w", "%{http_code}\n"]);
        synth.running = true;
    }

    // Renders coral-out.wav (prints 200 when it did), then `play` says it.
    Process {
        id: synth
        property bool cloud: false
        property string words: ""
        property string input: ""
        property string _code: ""
        stdinEnabled: true
        onStarted: {
            _code = "";
            write(input);
            stdinEnabled = false;
        }
        stdout: SplitParser {
            onRead: line => synth._code = line.trim()
        }
        onExited: {
            stdinEnabled = true;
            if (root.phase !== "speaking")
                return;
            if (_code === "200") {
                // ffmpeg's pulse output drops what's still buffered when the file ends (up
                // to ~2 s by default: the last words). Keep its buffer small and end on half a
                // second of silence, so what gets dropped is the silence.
                play.command = ["sh", "-c", "exec setpriv --pdeathsig TERM ffmpeg -nostdin -hide_banner -loglevel error -nostats -re -i \"$1/coral-out.wav\" "
                    + "-filter_complex '[0:a]apad=pad_dur=0.5,asplit[o][m];[m]astats=metadata=1:reset=1,ametadata=mode=print:key=lavfi.astats.Overall.RMS_level:file=-:direct=1,anullsink' "
                    + "-map '[o]' -buffer_duration 150 -f pulse Coral", "sh", root.runDir];
                play.running = true;
                return;
            }
            if (cloud) {
                // The error body landed in the file: show it, then try piper.
                cloudError.command = ["cat", root.runDir + "/coral-out.wav"];
                cloudError.running = true;
                return;
            }
            root._finish();
        }
    }
    Process {
        id: cloudError
        property string _out: ""
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => cloudError._out += data
        }
        onExited: {
            let msg = "";
            try {
                msg = JSON.parse(_out).error?.message ?? "";
            } catch (e) {}
            _out = "";
            Toasts.show({ text: "Cloud voice: " + (msg || "no answer") + (root.localSpeak ? " Using the local voice." : ""), icon: "error" });
            if (root.phase === "speaking")
                root._synthLocal(synth.words);
        }
    }
    Process {
        id: play
        stdout: SplitParser {
            onRead: line => root._onLevel(line)
        }
        onExited: {
            if (root.phase === "speaking")
                root._finish();
        }
    }

    // Voice is over: the Pearl folds back and the Island opens on the conversation.
    // A reply was spoken: listen a little longer for a follow-up (coral.followUp), then
    // fold away. The chat opens only when something went wrong; otherwise the reply waits
    // on the Island as Coral's "Replied" activity, and the keyboard is never taken.
    function _finish() {
        const spoke = phase === "speaking";
        const last = Coral.messages[Coral.messages.length - 1];
        if (spoke && (options?.followUp ?? true)) {
            followingUp = true;
            _listen(options?.followUpMs ?? 5000);
            return;
        }
        phase = "idle";
        level = 0;
        followingUp = false;
        if (last?.error)
            Actions.islandRequested("coral");
    }
}
