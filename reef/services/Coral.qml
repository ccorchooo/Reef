pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

// Coral, the assistant (SURFACES.md → Coral; ARCHITECTURE.md → Coral). Talks to any
// OpenAI-compatible endpoint (Settings → Coral), local ones included, streaming the reply
// with `curl` (server-sent events, one line at a time).
//
//   Coral.ask("How do I make the bar neutral?")   // the Island's Coral tab, search
//   Coral.stop()                                  // stop the reply where it is
//   Coral.clear()                                 // a new conversation
//
// Chat runs locally (coral.local: Ollama, llama.cpp…) or in the cloud (coral.cloud: Groq
// or any OpenAI-compatible service), per coral.chat. The cloud key is saved with saveKey()
// to ~/.config/reef/keys/cloud (mode 600), or read from the variable in coral.cloud.keyEnv,
// and handed to curl on a pipe, never in its arguments (which every process can read).
// Endpoints may be pasted whole (…/v1/chat/completions): curl() trims them to the base.
// With no model set, the first chat model the endpoint lists is used.
//
// Conversations (the Coral app, the Island's Coral tab and voice mode share them) are kept
// in ~/.local/share/reef/coral/chats.json, newest first, each with its own model; the model
// titles a conversation after its first reply. Attachments: images are scaled down and kept
// in coral/files (sent as image_url to models that see), text and code files are inlined
// (200 KB at most) and PDFs become text (pdftotext).
//
//   Coral.newChat(); Coral.openChat(id); Coral.deleteChat(id); Coral.renameChat(id, title)
//   Coral.attach(["/path/a.png"]); Coral.ask("What's in this?")   // sends the attachments
//   Coral.regenerate(); Coral.edit(index, "new question")
//
// Actions: Coral may end a reply with buttons, written as [[Label|action]] or
// [[Label|action:value]]. Only the actions below are shown, values are checked, and an
// action runs only when the user presses its button. They're the same handlers Reef's
// IPC and keybinds use (services/Actions).
Singleton {
    id: root

    readonly property var options: Config.options.coral

    // [{ role: "user" | "assistant", text, time, files: [attachment], actions: [{ label, id,
    //    value }], reasoning, error }]
    property var messages: []
    // idle | thinking (sent, nothing back yet) | replying (streaming)
    property string status: "idle"
    readonly property bool busy: status !== "idle"
    // A reply finished while nobody was looking (the Island shows it as an activity).
    property bool unread: false
    // Where chat runs, and the model in use (the setting, or what the endpoint offered).
    readonly property bool cloudChat: options.chat === "cloud"
    readonly property var target: cloudChat ? options.cloud : options.local
    property string model: target?.model ?? ""
    onTargetChanged: model = chatModel || (target?.model ?? "")
    // This conversation's model ("" = the setting, or the endpoint's first).
    property string chatModel: ""
    function setModel(id) {
        chatModel = id;
        model = id || (target?.model ?? "");
        if (chatId !== "")
            _update(chatId, { model: id });
    }

    // What the endpoint offers for chat (refreshModels() fills it).
    property var models: []
    function refreshModels() {
        modelList._out = "";
        modelList.command = curl(cloudChat, target.endpoint, "models", ["-m", "10"]);
        modelList.running = true;
    }
    function _chatModels(json) {
        try {
            return (JSON.parse(json).data ?? []).map(m => m.id).filter(id => !/whisper|tts|orpheus|guard|embed|playai|distil/i.test(id)).sort();
        } catch (e) {
            return [];
        }
    }
    Process {
        id: modelList
        property string _out: ""
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => modelList._out += data
        }
        onExited: root.models = root._chatModels(_out)
    }
    readonly property string place: cloudChat ? ((target?.endpoint ?? "").match(/^https?:\/\/(?:api\.)?([^/:]+)/)?.[1] ?? "cloud") : "local"

    // ── the cloud key ───────────────────────────────────────────
    readonly property string keyFile: Config.dir + "/keys/cloud"
    property bool hasKey: false          // a key is saved (or keyEnv is set)
    function saveKey(key) {
        key = (key ?? "").trim();
        keyWriter.key = key;
        keyWriter.command = ["sh", "-c", key === "" ? "rm -f \"$1\"" : "umask 077; mkdir -p \"${1%/*}\" && cat > \"$1\"", "sh", keyFile];
        keyWriter.running = true;
    }
    function checkKey() {
        keyCheck.command = ["sh", "-c", "[ -s \"$1\" ] || [ -n \"$(printenv \"$2\" 2>/dev/null)\" ]", "sh", keyFile, keyEnv];
        keyCheck.running = true;
    }
    // Checked again when the setting arrives or changes (on a reload Config can still be
    // filling in when this starts).
    readonly property string keyEnv: options?.cloud?.keyEnv ?? ""
    onKeyEnvChanged: checkKey()
    Component.onCompleted: checkKey()
    Process {
        id: keyWriter
        property string key: ""
        stdinEnabled: true
        onStarted: {
            if (key !== "")
                write(key);
            stdinEnabled = false;
        }
        onExited: {
            stdinEnabled = true;
            key = "";
            root.checkKey();
        }
    }
    Process {
        id: keyCheck
        onExited: code => root.hasKey = code === 0
    }

    // ── curl, for chat and voice ────────────────────────────────
    // The base of an endpoint pasted whole.
    function base(url) {
        return (url ?? "").trim().replace(/\/+$/, "").replace(/\/(chat\/completions|completions|audio\/transcriptions|audio\/speech|models)$/, "");
    }
    // ["sh", "-c", …] running `curl -sS -N <args> <base>/<path>`, with the cloud key (from
    // the saved file, else keyEnv) as a header file on fd 3 when `cloud` is true.
    readonly property string _curl: "f=$1; v=$2; url=$3; shift 3; k=; [ -n \"$f\" ] && k=$(cat \"$f\" 2>/dev/null); "
        + "[ -z \"$k\" ] && [ -n \"$v\" ] && k=$(printenv \"$v\" 2>/dev/null); "
        + "if [ -n \"$k\" ]; then exec 3<<EOF\nAuthorization: Bearer $k\nEOF\nexec curl -sS -N -H @/dev/fd/3 \"$@\" \"$url\"; fi; exec curl -sS -N \"$@\" \"$url\""
    function curl(cloud, endpoint, path, args) {
        return ["sh", "-c", _curl, "sh", cloud ? keyFile : "", cloud ? keyEnv : "", base(endpoint) + "/" + path].concat(args ?? []);
    }

    function ask(text) {
        text = (text ?? "").trim();
        const files = pending.filter(f => f.ready);
        if (text === "" && files.length === 0)
            return;
        stop();
        pending = pending.filter(f => !f.ready);
        messages = messages.concat([{ role: "user", text: text, time: Date.now(), files: files }, { role: "assistant", text: "", actions: [] }]);
        _store();
        _go();
    }

    // Send what's in `messages` (the last one is the empty reply to fill).
    function _go() {
        status = "thinking";
        model = chatModel || (target?.model ?? "") || model;
        if (model === "")
            _listModels();
        else
            _prepare();
    }

    // Ask again for the last reply.
    function regenerate() {
        if (messages.length === 0)
            return;
        stop();
        let m = messages.slice();
        if (m[m.length - 1].role === "assistant")
            m = m.slice(0, -1);
        if (m.length === 0)
            return;
        messages = m.concat([{ role: "assistant", text: "", actions: [] }]);
        _go();
    }

    // Change the question at `index` and ask from there (later messages go).
    function edit(index, text) {
        const q = messages[index];
        if (!q || q.role !== "user" || (text ?? "").trim() === "")
            return;
        stop();
        messages = messages.slice(0, index).concat([Object.assign({}, q, { text: text.trim(), time: Date.now() }), { role: "assistant", text: "", actions: [] }]);
        _store();
        _go();
    }

    function stop() {
        _stopping = true;
        if (_req) {
            const r = _req;
            _req = null;
            r.running = false;
            r.destroy(1000);
        }
        if (models.running)
            models.running = false;
        if (encoder.running)
            encoder.running = false;
        _finish();
        _stopping = false;
    }
    property bool _stopping: false

    function clear() {
        newChat();
    }

    // The Coral app's window (shell.qml builds it only while open).
    property bool appOpen: false
    function openApp() {
        appOpen = true;
    }

    // ── conversations ───────────────────────────────────────────
    readonly property string dataDir: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/reef/coral"
    property var chats: []               // [{ id, title, titled, created, updated, model, messages }], newest first
    property string chatId: ""
    readonly property var chat: chats.find(c => c.id === chatId) ?? null

    function newChat() {
        stop();
        chatId = "";
        messages = [];
        chatModel = "";
        model = target?.model ?? "";
        pending = [];
        unread = false;
    }
    function openChat(id) {
        const c = chats.find(c => c.id === id);
        if (!c || id === chatId)
            return;
        stop();
        chatId = id;
        messages = c.messages ?? [];
        chatModel = c.model ?? "";
        model = chatModel || (target?.model ?? "");
        pending = [];
    }
    function deleteChat(id) {
        if (id === chatId)
            newChat();
        chats = chats.filter(c => c.id !== id);
        cleaner.command = ["rm", "-rf", dataDir + "/files/" + id];
        cleaner.running = true;
        _save();
    }
    function renameChat(id, title) {
        title = (title ?? "").trim();
        if (title !== "")
            _update(id, { title: title, titled: true });
    }

    function _newId() {
        return Date.now().toString(36) + Math.floor(Math.random() * 1e6).toString(36);
    }
    // The first question, cut short (until the model names it).
    function _fallbackTitle(msgs) {
        const q = msgs.find(m => m.role === "user");
        const t = (q?.text || q?.files?.[0]?.name || "New conversation").replace(/\s+/g, " ").trim();
        return t.length > 48 ? t.slice(0, 47).trim() + "…" : t;
    }
    function _update(id, fields) {
        chats = chats.map(c => c.id === id ? Object.assign({}, c, fields) : c);
        _save();
    }
    // Put the current messages into their conversation (making it on the first question),
    // and move it to the top.
    function _store() {
        if (messages.length === 0)
            return;
        const now = Date.now();
        if (chatId === "" || !chats.some(c => c.id === chatId)) {
            chatId = chatId || _newId();
            chats = [{ id: chatId, title: _fallbackTitle(messages), titled: false, created: now, updated: now, model: chatModel, messages: messages }].concat(chats);
        } else {
            const c = Object.assign({}, chats.find(c => c.id === chatId), { updated: now, messages: messages, model: chatModel });
            chats = [c].concat(chats.filter(x => x.id !== chatId));
        }
        _save();
    }

    function _save() {
        saveTimer.restart();
    }
    Timer {
        id: saveTimer
        interval: 400
        onTriggered: store.setText(JSON.stringify({ version: 1, chats: root.chats }))
    }
    FileView {
        id: store
        path: root.dataDir + "/chats.json"
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try {
                root.chats = JSON.parse(text()).chats ?? [];
            } catch (e) {
                console.warn("Coral: couldn't read", path);
            }
        }
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                console.warn("Coral: couldn't read", path, FileViewError.toString(error));
        }
    }
    Process {
        id: cleaner
    }

    // Name a conversation after its first reply, in a few words, quietly.
    function _nameChat() {
        const c = chats.find(c => c.id === chatId);
        if (!c || c.titled || titler.running)
            return;
        const q = messages.find(m => m.role === "user")?.text ?? "";
        const a = messages.find(m => m.role === "assistant" && !m.error)?.text ?? "";
        if (q === "" || a === "")
            return;
        titler._id = chatId;
        titler._out = "";
        titler.body = JSON.stringify({
            model: model,
            stream: false,
            max_tokens: 400,
            messages: [{ role: "system", content: "Name this conversation in 2 to 6 words, in the language of the question. Reply with the name only, no quotes or punctuation at the end." },
                { role: "user", content: "Question: " + q.slice(0, 600) + "\nAnswer: " + a.slice(0, 600) }]
        });
        titler.command = curl(cloudChat, target.endpoint, "chat/completions", ["-m", "30", "-X", "POST", "-H", "Content-Type: application/json", "--data-binary", "@-"]);
        titler.running = true;
    }
    Process {
        id: titler
        property string _id: ""
        property string _out: ""
        property string body: ""
        stdinEnabled: true
        onStarted: {
            write(body);
            stdinEnabled = false;
        }
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => titler._out += data
        }
        onExited: {
            stdinEnabled = true;
            try {
                let t = JSON.parse(_out).choices?.[0]?.message?.content ?? "";
                t = t.replace(/<think>[\s\S]*?<\/think>/g, "").replace(/["“”*#]/g, "").split("\n").filter(l => l.trim() !== "")[0]?.trim() ?? "";
                if (t !== "" && t.length <= 80)
                    root._update(_id, { title: t.replace(/[.。]$/, ""), titled: true });
            } catch (e) {}
        }
    }

    // ── attachments ─────────────────────────────────────────────
    // Waiting to go with the next question: [{ id, name, kind: image|text, path, text,
    // ready, error }]. Images are scaled to 1536 px at most and kept for the conversation.
    property var pending: []
    function attach(paths) {
        for (let path of paths) {
            path = String(path).replace(/^file:\/\//, "");
            path = decodeURIComponent(path);
            const a = { id: _newId(), name: path.split("/").pop(), kind: "", path: path, text: "", ready: false, error: "" };
            pending = pending.concat([a]);
            const job = reader.createObject(root, { att: a.id, chat: chatId || "_draft" });
            job.command = ["sh", "-c", root._readScript, "sh", path, dataDir + "/files/" + (chatId || "_draft"), a.id];
            job.running = true;
        }
    }
    function unattach(id) {
        pending = pending.filter(a => a.id !== id);
    }
    function _setPending(id, fields) {
        pending = pending.map(a => a.id === id ? Object.assign({}, a, fields) : a);
    }
    // Prints "KIND <kind>" then, for text, the text; for images, the kept copy's path.
    readonly property string _readScript: "f=$1; dir=$2; id=$3; [ -r \"$f\" ] || { echo 'KIND error'; echo \"can't read it\"; exit; }; "
        + "mime=$(file -b --mime-type \"$f\"); size=$(stat -c %s \"$f\"); "
        + "case \"$mime\" in "
        + "image/*) mkdir -p \"$dir\" && ffmpeg -v error -nostdin -i \"$f\" -vf \"scale='min(1536,iw)':'min(1536,ih)':force_original_aspect_ratio=decrease\" -frames:v 1 -q:v 3 -y \"$dir/$id.jpg\" && { echo 'KIND image'; echo \"$dir/$id.jpg\"; } || { echo 'KIND error'; echo \"couldn't read the image\"; } ;; "
        + "application/pdf) echo 'KIND text'; pdftotext -layout -l 40 \"$f\" - 2>/dev/null | head -c 200000 ;; "
        + "text/*|application/json|application/xml|application/javascript|application/x-*script*|application/toml|application/x-yaml|inode/x-empty) echo 'KIND text'; head -c 200000 \"$f\" ;; "
        + "*) if [ \"$size\" -lt 400000 ] && LC_ALL=C grep -qI . \"$f\"; then echo 'KIND text'; head -c 200000 \"$f\"; else echo 'KIND error'; echo \"$mime isn't supported\"; fi ;; esac"
    Component {
        id: reader
        Process {
            id: job
            property string att: ""
            property string chat: ""
            property string _out: ""
            stdout: SplitParser {
                splitMarker: ""
                onRead: data => job._out += data
            }
            onExited: {
                const nl = _out.indexOf("\n");
                const kind = (nl < 0 ? _out : _out.slice(0, nl)).replace("KIND ", "").trim();
                const rest = nl < 0 ? "" : _out.slice(nl + 1);
                if (kind === "image")
                    root._setPending(att, { kind: "image", path: rest.trim(), ready: true });
                else if (kind === "text")
                    root._setPending(att, { kind: "text", text: rest, ready: true });
                else
                    root._setPending(att, { error: rest.trim() || "couldn't read it" });
                job.destroy(1000);
            }
        }
    }

    // ── actions ─────────────────────────────────────────────────
    // id → { about (for the model), values (allowed, if it takes one), run }
    readonly property var tools: ({
            colorfulness: { about: "how colorful surfaces are", values: ["monochrome", "neutral", "tinted", "vivid", "deep"], run: v => Config.options.look.colorfulness = v },
            theme: { about: "light or dark look", values: ["dark", "light", "auto"], run: v => Config.options.look.theme = v },
            settings: { about: "open a Settings page", values: ["look", "displays", "bar", "apps", "widgets", "lock", "sound", "network", "bluetooth", "coral", "keyboard", "power", "accessibility", "about"], run: v => Actions.openSettings(v) },
            volume: { about: "set the volume, 0 to 100", number: true, run: v => Audio.setVolume(v / 100) },
            brightness: { about: "set the screen brightness, 0 to 100", number: true, run: v => Brightness.set(v / 100) },
            timer: { about: "start a timer for a number of minutes", number: true, run: v => Countdown.start(v * 60) },
            launch: { about: "open an app by name", text: true, run: v => root._launch(v) },
            dnd: { about: "toggle Do not disturb", run: () => Actions.run("dnd") },
            nightLight: { about: "toggle night light", run: () => Actions.run("nightLight") },
            keepAwake: { about: "toggle keep awake", run: () => Actions.run("keepAwake") },
            focus: { about: "start or stop a focus session", run: () => Actions.run("focus") },
            screenshot: { about: "take a screenshot of a region", run: () => Actions.run("screenshot") },
            overview: { about: "show the workspace overview", run: () => Actions.run("overview") },
            controlCenter: { about: "open the control center", run: () => Actions.run("controlCenter") },
            editMode: { about: "edit the home screen and widgets", run: () => Actions.run("editMode") },
            calendar: { about: "open the calendar", run: () => Actions.run("calendar") },
            wifiMenu: { about: "open the Wi-Fi menu", run: () => Actions.run("wifiMenu") },
            bluetoothMenu: { about: "open the Bluetooth menu", run: () => Actions.run("bluetoothMenu") },
            audioOutput: { about: "choose the audio output", run: () => Actions.run("audioOutput") }
        })

    function runAction(a) {
        const t = tools[a.id];
        if (!t)
            return;
        t.run(t.number ? Number(a.value) : a.value);
    }

    // "Label|id:value" → { label, id, value }, or null when Reef can't do it.
    function _action(label, spec) {
        const i = spec.indexOf(":");
        const id = (i < 0 ? spec : spec.slice(0, i)).trim();
        const value = i < 0 ? "" : spec.slice(i + 1).trim();
        const t = tools[id];
        if (!t || label.trim() === "")
            return null;
        if (t.values && !t.values.includes(value))
            return null;
        if (t.number && !(value !== "" && isFinite(Number(value)) && Number(value) >= 0))
            return null;
        if (t.text && value === "")
            return null;
        if (!t.values && !t.number && !t.text && value !== "")
            return null;
        return { label: label.trim(), id: id, value: value };
    }

    // Splits the raw reply into what's shown and its actions (a half-written [[… at the
    // end of a streaming reply is hidden until it closes).
    function _parse(raw) {
        const actions = [];
        let text = raw.replace(/\[\[([^|\]]*)\|([^\]]*)\]\]/g, (m, label, spec) => {
            const a = Config.options.coral.actions ? _action(label, spec) : null;
            if (a && !actions.some(b => b.id === a.id && b.value === a.value))
                actions.push(a);
            return "";
        });
        text = text.replace(/\[\[[^\]]*$/, "").replace(/\s+$/, "");
        return { text: text, actions: actions };
    }

    function _launch(name) {
        const n = name.toLowerCase();
        const apps = DesktopEntries.applications.values.filter(e => !e.noDisplay);
        const entry = apps.find(e => e.name.toLowerCase() === n) ?? apps.find(e => e.name.toLowerCase().includes(n));
        if (entry)
            Apps.launch(entry);
        else
            Toasts.show({ text: `No app called “${name}”`, icon: "info" });
    }

    // ── the request ─────────────────────────────────────────────
    readonly property string instructions: (options?.instructions ?? "").trim()
    readonly property string _system: [
        "You are Coral, the assistant built into Reef, a desktop shell for Hyprland on Linux.",
        "Speak in the first person, briefly and plainly, without emoji. Prefer a few sentences; use Markdown only when it helps (lists, code).",
        "It is " + Qt.formatDateTime(Time.now, "dddd d MMMM yyyy, hh:mm") + ".",
        "Reef has a Settings app with these pages: look (wallpaper, colors, theme, colorfulness), displays, bar (Bar & Island), apps, widgets, lock (Lock screen), sound, network, bluetooth, coral, keyboard, power (Power & performance), accessibility, about."
    ].concat(Config.options.coral.actions ? [
        "When you can do something for the user right away, end your reply with buttons, each on its own line as [[Label|action]] or [[Label|action:value]]. The user presses one to run it; never claim you already did it. Offer at most three, only when they help. Actions:",
        Object.keys(tools).map(id => {
            const t = tools[id];
            return "- " + id + (t.values ? ":" + t.values.join("|") : t.number ? ":<number>" : t.text ? ":<name>" : "") + " (" + t.about + ")";
        }).join("\n"),
        "Use settings:<page> to open Settings (never launch). Offer buttons only for something the user asked about.",
        "Example: [[Switch to Neutral|colorfulness:neutral]]"
    ] : []).join("\n")

    // The question with its text files inlined, and its images (as data URLs from `images`:
    // path → base64) when there are any.
    function _content(m, images) {
        let text = m.text ?? "";
        for (const f of (m.files ?? []).filter(f => f.kind === "text"))
            text += "\n\nFile: " + f.name + "\n```\n" + f.text + "\n```";
        const pics = (m.files ?? []).filter(f => f.kind === "image" && images[f.path]);
        if (pics.length === 0)
            return text;
        return [{ type: "text", text: text || "(image)" }].concat(pics.map(f => ({ type: "image_url", image_url: { url: "data:image/jpeg;base64," + images[f.path] } })));
    }

    // Read the conversation's images (base64), then send.
    function _prepare() {
        const paths = [];
        for (const m of messages)
            for (const f of (m.files ?? []))
                if (f.kind === "image" && !paths.includes(f.path))
                    paths.push(f.path);
        if (paths.length === 0) {
            _send({});
            return;
        }
        encoder._out = "";
        encoder.command = ["sh", "-c", "for p; do printf '%s\\t' \"$p\"; base64 -w0 \"$p\" 2>/dev/null; echo; done", "sh"].concat(paths);
        encoder.running = true;
    }
    Process {
        id: encoder
        property string _out: ""
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => encoder._out += data
        }
        onExited: {
            if (root.status === "idle")
                return;
            const images = {};
            for (const line of _out.split("\n")) {
                const tab = line.indexOf("\t");
                if (tab > 0 && line.length > tab + 1)
                    images[line.slice(0, tab)] = line.slice(tab + 1);
            }
            _out = "";
            root._send(images);
        }
    }

    function _body(images) {
        const history = messages.slice(0, -1).filter(m => !m.error && (m.text !== "" || (m.files ?? []).length > 0)).map(m => ({
                    role: m.role,
                    content: m.role === "assistant" ? m.raw ?? m.text : root._content(m, images)
                }));
        return JSON.stringify({
            model: model,
            stream: true,
            messages: [{ role: "system", content: _system + (instructions !== "" ? "\nThe user's instructions: " + instructions : "") }].concat(history)
        });
    }

    function _listModels() {
        models._out = "";
        models.command = curl(cloudChat, target.endpoint, "models", ["-m", "10"]);
        models.running = true;
    }

    function _send(images) {
        _raw = "";
        _reasoning = "";
        _junk = "";
        _err = "";
        _status = 0;
        // One process per request: a stopped one's late output and exit are ignored.
        _req = request.createObject(root, {
            body: _body(images ?? {}),
            command: curl(cloudChat, target.endpoint, "chat/completions",
                ["-X", "POST", "-H", "Content-Type: application/json", "--data-binary", "@-",
                "-w", "\n__REEF_STATUS__ %{http_code}\n"])
        });
        _req.running = true;
    }
    property var _req: null

    property string _raw: ""      // the reply as streamed (with action markup)
    property string _reasoning: "" // what reasoning models stream before the reply
    property string _junk: ""     // lines that weren't events (an error body)
    property string _err: ""      // curl's own complaint
    property int _status: 0

    function _setReply(fields) {
        const m = messages.slice();
        m[m.length - 1] = Object.assign({}, m[m.length - 1], fields);
        messages = m;
    }

    // SplitParser leaves the blank line between events stuck to the next one ("\ndata:"),
    // and some servers end lines with \r\n: take each real line on its own.
    function _onLine(chunk) {
        for (const line of chunk.split(/\r?\n/))
            _onEventLine(line.trim());
    }
    function _onEventLine(line) {
        if (line === "")
            return;
        if (line.startsWith("__REEF_STATUS__ ")) {
            _status = parseInt(line.slice(16));
            return;
        }
        if (!line.startsWith("data:")) {
            if (line.trim() !== "")
                _junk += line + "\n";
            return;
        }
        const data = line.slice(5).trim();
        if (data === "[DONE]" || data === "")
            return;
        try {
            const ev = JSON.parse(data);
            if (ev.error) {
                _junk += JSON.stringify(ev);
                return;
            }
            const delta = ev.choices?.[0]?.delta ?? {};
            const thought = delta.reasoning ?? delta.reasoning_content ?? "";
            if (thought !== "") {
                _reasoning += thought;
                _setReply({ reasoning: _reasoning });
            }
            const piece = delta.content ?? "";
            if (piece === "")
                return;
            _raw += piece;
            status = "replying";
            const p = _parse(_raw);
            _setReply({ text: p.text, actions: p.actions, raw: _raw, time: Date.now(), model: model });
        } catch (e) {
            _junk += line + "\n";
        }
    }

    function _errorText() {
        try {
            const body = JSON.parse(_junk);
            const msg = body.error?.message ?? body.error ?? body.message ?? body.detail;
            if (msg)
                return String(msg);
        } catch (e) {}
        if (_err !== "")
            return _err.replace(/^curl: \(\d+\) /, "");
        if (_status === 401)
            return "it didn't accept the key. Save one in Settings → Coral.";
        if (_status >= 400)
            return "The endpoint answered " + _status + ".";
        return _junk.trim().split("\n")[0] || "No reply.";
    }

    function _finish() {
        if (status === "idle")
            return;
        const last = messages[messages.length - 1];
        const empty = _raw === "" && last?.role === "assistant";
        status = "idle";
        // Stopped before a word came back: drop the empty reply.
        if (empty && _stopping) {
            messages = messages.slice(0, -1);
            _store();
            return;
        }
        if (empty)
            _setReply({ text: `I couldn't reach ${base(target.endpoint)}: ${_errorText()}`, error: true, actions: [{ label: "Open Settings", id: "settings", value: "coral" }] });
        else if (!_watching)
            unread = true;
        if (!empty && !_stopping)
            Sounds.play("reply");
        _store();
        if (!empty)
            _nameChat();
    }

    // Whether someone is looking at the conversation (the Island's Coral tab).
    property bool _watching: false
    function watching(on) {
        _watching = on;
        if (on)
            unread = false;
    }

    Component {
        id: request
        Process {
            id: req
            property string body: ""
            stdinEnabled: true
            onStarted: {
                write(body);
                stdinEnabled = false;
            }
            stdout: SplitParser {
                onRead: line => {
                    if (root._req === req)
                        root._onLine(line);
                }
            }
            stderr: SplitParser {
                onRead: line => {
                    if (root._req === req)
                        root._err += (root._err ? " " : "") + line;
                }
            }
            onExited: {
                if (root._req !== req)
                    return;
                root._finish();
                root._req = null;
                req.destroy(1000);
            }
        }
    }

    Process {
        id: models
        property string _out: ""
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => models._out += data
        }
        onExited: {
            if (root.status === "idle")
                return;
            try {
                const list = JSON.parse(_out).data ?? [];
                // The first chat model: not speech, moderation or embeddings.
                const chat = list.map(m => m.id).filter(id => !/whisper|tts|orpheus|guard|embed|playai/i.test(id));
                root.model = chat[0] ?? "";
            } catch (e) {}
            if (root.model === "") {
                root._junk = _out;
                root._err = root._err || "it offered no model. Set one in Settings → Coral.";
                root._finish();
                return;
            }
            root._prepare();
        }
    }
}
