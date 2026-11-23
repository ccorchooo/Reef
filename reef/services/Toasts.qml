pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Short confirmations above the bar ("Copied to clipboard · Undo"), one at a time.
//
//   Toasts.show({ text: "Copied to clipboard", icon: "content_copy", action: "Undo", onAction: () => … })
Singleton {
    id: root

    // { text, icon, action, onAction, id } or null
    property var current: null
    property var _queue: []
    property int _nextId: 1

    function show(toast) {
        if (!Config.options.toasts.enabled || !toast?.text)
            return;
        const t = Object.assign({ icon: "", action: "", onAction: null }, toast, { id: _nextId++ });
        if (current) {
            _queue = _queue.concat([t]);
            return;
        }
        _present(t);
    }

    function dismiss() {
        hold.stop();
        current = null;
        if (_queue.length > 0) {
            const next = _queue[0];
            _queue = _queue.slice(1);
            gap.next = next;
            gap.restart();
        }
    }

    function act() {
        const t = current;
        dismiss();
        if (t?.onAction)
            t.onAction();
    }

    function _present(t) {
        current = t;
        hold.interval = t.action ? Tokens.toastActionTimeout : Tokens.toastTimeout;
        hold.restart();
    }

    Timer {
        id: hold
        onTriggered: root.dismiss()
    }

    // Let the previous toast leave before the next one arrives.
    Timer {
        id: gap
        property var next: null
        interval: Tokens.springs.spatialDefault.duration
        onTriggered: root._present(next)
    }
}
