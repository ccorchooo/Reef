pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
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

    signal failed

    function lock() {
        if (locked)
            return;
        preview = false;
        unlocking = false;
        locked = true;
    }

    function showPreview(on) {
        if (locked)
            return;
        unlocking = false;
        previewScreen = Hyprland.focusedMonitor?.name ?? "";
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
        lift.restart();
    }

    Timer {
        id: lift
        interval: Tokens.unlockDelay / Math.max(0.1, Config.options.motion.speed)
        onTriggered: {
            root.locked = false;
            root.preview = false;
            root.unlocking = false;
        }
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
