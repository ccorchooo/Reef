pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.theme

// Reef is the notification server (org.freedesktop.Notifications).
// New notifications pop into the Island unless Do not disturb is on (critical ones
// always do), then stay in the control center until dismissed.
//
// Only one notification server can own the name: while another shell (Caelestia)
// runs, this one receives nothing.
Singleton {
    id: root

    // Newest first.
    readonly property var list: server.trackedNotifications.values.slice().reverse()
    readonly property int count: list.length

    // Settings → Notifications → Do not disturb (also driven by focus sessions).
    readonly property bool dnd: Config.options.notifications.dnd
    function setDnd(on) {
        Config.options.notifications.dnd = on;
    }

    // The one showing in the Island right now, and the ones waiting.
    property var popup: null
    property var _queue: []

    // When each notification arrived (id → ms), for "now", "4 min", "2 h".
    property var _received: ({})

    // Notifications reporting progress (hint "value", 0–100), newest first.
    readonly property var inProgress: list.filter(n => {
        const v = n.hints?.value;
        return v !== undefined && v !== null && Number(v) >= 0 && Number(v) < 100;
    })

    signal arrived(var notification)

    function receivedAt(n) {
        return _received[n?.id] ?? Date.now();
    }

    function ago(n, now) {
        const s = Math.max(0, ((now ?? Date.now()) - receivedAt(n)) / 1000);
        if (s < 60)
            return "now";
        if (s < 3600)
            return `${Math.floor(s / 60)} min`;
        if (s < 86400)
            return `${Math.floor(s / 3600)} h`;
        return `${Math.floor(s / 86400)} d`;
    }

    function dismiss(n) {
        if (popup === n)
            closePopup();
        n?.dismiss();
    }

    function clearAll() {
        closePopup();
        for (const n of list.slice())
            n.dismiss();
    }

    function invoke(n, action) {
        action.invoke();
        if (!n.resident)
            dismiss(n);
    }

    function reply(n, text) {
        if (n?.hasInlineReply && text.trim() !== "") {
            n.sendInlineReply(text);
            dismiss(n);
        }
    }

    function closePopup() {
        popupTimer.stop();
        popup = null;
        if (_queue.length > 0) {
            const next = _queue[0];
            _queue = _queue.slice(1);
            Qt.callLater(() => root._show(next));
        }
    }

    // Keep the popup up while the pointer is on it or a reply is being typed.
    function holdPopup(hold) {
        if (hold)
            popupTimer.stop();
        else if (popup)
            popupTimer.restart();
    }

    function _show(n) {
        if (!n || !n.tracked)
            return closePopup();
        popup = n;
        if (n.urgency !== NotificationUrgency.Critical)
            popupTimer.restart();
    }

    Timer {
        id: popupTimer
        interval: Tokens.notificationPopupTimeout
        onTriggered: root.closePopup()
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        inlineReplySupported: true
        imageSupported: true
        bodyMarkupSupported: false
        persistenceSupported: true
        extraHints: ["value"]

        onNotification: n => {
            n.tracked = true;
            const r = Object.assign({}, root._received);
            r[n.id] = Date.now();
            root._received = r;
            root.arrived(n);
            // Progress updates replace the notification in place; don't pop them again.
            if (n.hints?.value !== undefined && root.inProgress.some(p => p.id === n.id && p !== n))
                return;
            if (root.dnd && n.urgency !== NotificationUrgency.Critical)
                return;
            if (n.transient && root.dnd)
                return;
            if (!root.dnd)
                Sounds.play("notification");
            if (root.popup)
                root._queue = root._queue.concat([n]);
            else
                root._show(n);
        }
    }

    // A popup whose notification was closed elsewhere goes away.
    Connections {
        target: server
        function onTrackedNotificationsChanged() {
            if (root.popup && !root.popup.tracked)
                root.closePopup();
        }
    }
}
