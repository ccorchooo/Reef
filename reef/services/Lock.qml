pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pam
import qs.theme

// The session lock (SURFACES.md → Lock screen). modules/lock draws it; this holds the
// state and checks the password with PAM (assets/pam.d/reef: pam_unix, the user's own
// password). If that config can't start, it falls back to the system's "login" stack,
// so a broken setup can never leave you locked out.
//
//   Lock.lock()                  // Super+L, the power actions, `ipc call lock lock`
//   Lock.submit(password)        // the field; `failed` or the unlock follows
//
// `preview` shows the lock screen in an ordinary overlay without locking the session
// (`ipc call lock preview`), to check how it looks; Escape or a correct password closes it.
//
// Lid (lock.onLidClose): logind's LidClosed turning true locks. Closing the lid usually
// suspends too, so Reef holds a logind sleep "delay" inhibitor (systemd-inhibit) and lets
// it go only once the lock is secure (every monitor covered), so the screen never shows
// the desktop on wake; logind still decides whether the lid sleeps (HandleLidSwitch).
// logind is watched with `gdbus monitor` (glib, systemd). Both helpers end with the shell.
Singleton {
    id: root

    property bool locked: false
    property bool preview: false
    // The monitor the preview opens on (the focused one when it was asked for).
    property string previewScreen: ""
    readonly property bool shown: locked || preview
    // A correct password: the Pearl folds back toward the Island, then the lock lifts.
    property bool unlocking: false
    readonly property bool busy: pam.active
    // PAM's own message when it isn't a password prompt (fingerprint, account locked).
    readonly property string message: pam.active && !pam.responseRequired ? pam.message : ""

    // Set by modules/lock: the compositor confirmed every monitor is covered.
    property bool secure: false
    property bool lidClosed: false

    // The Pearl the lock grows out of when one is already out (the power actions):
    // { screen, x, y, w, h } in screen coordinates. Set during aboutToLock.
    property var handoff: null

    signal failed
    // Just before locking, so a Pearl on screen can hand itself over.
    signal aboutToLock

    function lock() {
        if (locked)
            return;
        preview = false;
        unlocking = false;
        handoff = null;
        aboutToLock();
        locked = true;
        Sounds.play("lock");
    }

    function showPreview(on) {
        if (locked)
            return;
        unlocking = false;
        previewScreen = Monitors.focused;
        preview = on;
    }

    function submit(password) {
        if (!shown || unlocking || pam.active || password === "")
            return;
        _password = password;
        if (!_start(true) && !_start(false)) {
            _password = "";
            console.warn("Lock: PAM could not start");
            failed();
        }
    }

    property string _password: ""
    property bool _system: false

    function _start(own) {
        _system = !own;
        pam.configDirectory = own ? Quickshell.shellPath("assets/pam.d") : "/etc/pam.d";
        pam.config = own ? "reef" : "login";
        return pam.start();
    }

    function _unlock() {
        unlocking = true;
        if (locked)
            Sounds.play("unlock");
        lift.restart();
    }

    Timer {
        id: lift
        interval: Tokens.unlockDelay / Math.max(0.1, Config.options.motion.speed)
        onTriggered: {
            root.locked = false;
            root.preview = false;
            root.unlocking = false;
            root.handoff = null;
        }
    }

    // ── lid and sleep (logind) ──────────────────────────────────
    readonly property bool watchLid: Config.options.lock.onLidClose
    // Holding the delay inhibitor; dropped while a sleep is waiting on the lock.
    property bool _inhibit: watchLid
    property bool _sleeping: false

    function _onSleep(start) {
        _sleeping = start;
        if (!start) {
            _inhibit = watchLid;
            return;
        }
        if (lidClosed && watchLid)
            lock();
        // Let the sleep go now, or once the lock is up (see onSecureChanged).
        if (!locked || secure)
            _inhibit = false;
    }
    onSecureChanged: {
        if (secure && _sleeping)
            _inhibit = false;
    }
    onWatchLidChanged: _inhibit = watchLid && !_sleeping

    Process {
        id: logind
        running: root.watchLid
        // Ends with the shell: the kernel signals it when Quickshell goes (even a crash).
        command: ["setpriv", "--pdeathsig", "TERM", "gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1", "--object-path", "/org/freedesktop/login1"]
        stdout: SplitParser {
            onRead: line => {
                const lid = line.match(/'LidClosed': <(true|false)>/);
                if (lid) {
                    root.lidClosed = lid[1] === "true";
                    if (root.lidClosed && root.watchLid)
                        root.lock();
                }
                const sleep = line.match(/PrepareForSleep \((true|false)/);
                if (sleep)
                    root._onSleep(sleep[1] === "true");
            }
        }
        onExited: code => {
            if (root.watchLid)
                console.warn("Lock: gdbus monitor exited (" + code + "); closing the lid won't lock");
        }
    }

    Process {
        running: root._inhibit
        // Held by `cat` on the stdin pipe Quickshell keeps open, so it's released the moment
        // the shell is gone (a crash must never leave sleep waiting on it).
        command: ["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=Reef", "--why=Locking the screen first", "cat"]
    }

    PamContext {
        id: pam
        onResponseRequiredChanged: {
            if (!responseRequired)
                return;
            respond(root._password);
            root._password = "";
        }
        onCompleted: result => {
            root._password = "";
            if (result === PamResult.Success)
                root._unlock();
            else
                root.failed();
        }
        onError: error => {
            console.warn("Lock: PAM error", PamError.toString(error), root._system ? "(login)" : "(reef)");
            // Our own config failed to load: try the system's once, with the same password.
            if (!root._system && root._password !== "" && root._start(false))
                return;
            root._password = "";
            root.failed();
        }
    }
}
