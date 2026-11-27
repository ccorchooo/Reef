pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

// The login greeter's state (SURFACES.md → Login greeter; greeter.qml, modules/greeter).
// Runs as greetd's greeter user inside a small Hyprland (greeter/hyprland.lua).
//
//   users     people who can log in: /etc/passwd, uid 1000–59999 with a real shell
//   sessions  /usr/share/wayland-sessions/*.desktop ("reef" first when it's there)
//   login(password)  greetd: create a session for `user`, answer its prompt, launch
//
// The last user and session are remembered in the greeter's own cache, and the look
// (colors, wallpaper) comes from the config that `reef greeter-sync` copies into the
// greeter's home, so it matches the desktop it opens.
Singleton {
    id: root

    property var users: []          // [{ name, display, avatar }]
    property var sessions: []       // [{ id, name, exec }]
    property string user: ""
    property string session: ""
    readonly property var current: users.find(u => u.name === user) ?? null
    readonly property var currentSession: sessions.find(s => s.id === session) ?? null
    readonly property bool busy: Greetd.state !== GreetdState.Inactive || _pending !== ""
    readonly property bool available: Greetd.available
    property string message: ""     // greetd's info or error text, shown under the field

    signal failed

    property string _pending: ""

    function choose(name) {
        if (busy)
            return;
        user = name;
        adapter.user = name;
        message = "";
    }
    function chooseSession(id) {
        session = id;
        adapter.session = id;
    }

    function login(password) {
        if (!user || busy)
            return;
        message = "";
        _pending = password;
        Greetd.createSession(user);
    }

    Connections {
        target: Greetd
        function onAuthMessage(text, error, responseRequired, echoResponse) {
            if (responseRequired) {
                if (root._pending !== "") {
                    Greetd.respond(root._pending);
                    root._pending = "";
                } else {
                    // A second prompt (a code, a fingerprint fallback) we can't answer here.
                    root.message = text;
                    Greetd.cancelSession();
                }
            } else if (text !== "") {
                root.message = text;
                if (!error)
                    Greetd.respond("");
            }
        }
        function onAuthFailure(text) {
            root._pending = "";
            root.message = "";
            root.failed();
        }
        function onReadyToLaunch() {
            const s = root.currentSession;
            const exec = s ? s.exec : "start-hyprland";
            Greetd.launch(["/bin/sh", "-c", "exec " + exec], ["XDG_SESSION_TYPE=wayland", "XDG_SESSION_DESKTOP=" + (s?.id ?? "hyprland")], true);
        }
        function onError(text) {
            root._pending = "";
            root.message = text;
        }
    }

    // ── users ───────────────────────────────────────────────────
    FileView {
        path: "/etc/passwd"
        onLoaded: {
            const list = [];
            for (const line of text().split("\n")) {
                const f = line.split(":");
                const uid = Number(f[2]);
                if (f.length < 7 || uid < 1000 || uid >= 60000 || /(nologin|false)$/.test(f[6]))
                    continue;
                const display = (f[4] ?? "").split(",")[0] || f[0];
                list.push({ name: f[0], display: display, avatar: "/var/lib/AccountsService/icons/" + f[0] });
            }
            root.users = list;
            root._pickUser();
        }
    }

    // ── sessions ────────────────────────────────────────────────
    Process {
        running: true
        command: ["sh", "-c", `for f in /usr/share/wayland-sessions/*.desktop; do
            [ -f "$f" ] || continue
            grep -qi '^NoDisplay=true' "$f" && continue
            n=$(sed -n 's/^Name=//p' "$f" | head -1); e=$(sed -n 's/^Exec=//p' "$f" | head -1)
            printf '%s\\t%s\\t%s\\n' "$(basename "$f" .desktop)" "$n" "$e"
        done`]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                for (const line of text.split("\n")) {
                    const [id, name, exec] = line.split("\t");
                    if (id && exec)
                        list.push({ id: id, name: name || id, exec: exec.replace(/ %[a-zA-Z]/g, "") });
                }
                list.sort((a, b) => (b.id === "reef") - (a.id === "reef") || a.name.localeCompare(b.name));
                root.sessions = list;
                root._pickSession();
            }
        }
    }

    // ── remembered choices ──────────────────────────────────────
    FileView {
        id: state
        path: Config.cacheDir + "/greeter.json"
        printErrors: false
        onLoaded: { root._pickUser(); root._pickSession(); }
        onLoadFailed: { root._pickUser(); root._pickSession(); }
        onAdapterUpdated: writeAdapter()
        JsonAdapter {
            id: adapter
            property string user: ""
            property string session: ""
        }
    }

    function _pickUser() {
        if (users.length === 0)
            return;
        const saved = adapter.user;
        user = users.some(u => u.name === saved) ? saved : users[0].name;
    }
    function _pickSession() {
        if (sessions.length === 0)
            return;
        const saved = adapter.session;
        session = sessions.some(s => s.id === saved) ? saved : sessions[0].id;
    }
}
