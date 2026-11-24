import QtQuick
import qs.theme
import qs.services
import qs.components
import qs.modules
import qs.modules.menus

// Status cay (SURFACES.md → Bar, Quick menus): the clock on the left, then a gap, then
// the controls (notifications bell, network, volume, battery) on the right.
//
// Clicking anywhere on the row opens the control center. Resting the pointer on the
// clock, network or volume opens its quick menu *in the cay*: the cay grows up and out
// (spatial-default) into a card that holds the menu above the row, and the chosen
// control slides to the right end on its own while the others close up on the left
// (the clock never moves). Leaving the cay closes it after menu-close-delay.
// Scrolling over the row changes the volume. The bell fills when there are
// notifications and shows Do not disturb.
Cay {
    id: root

    required property string screenName
    // The bar is in keyboard mode (Super+B): menus then stay until Escape.
    property bool keyboardActive: false

    leftPadding: Tokens.cayPadding
    rightPadding: Tokens.cayPadding
    color: bg.value

    readonly property bool panelOpen: PanelState.screenName === screenName && PanelState.panel === "controlCenter"
    readonly property string menu: PanelState.barMenu(screenName)
    readonly property bool menuOpen: menu !== ""
    readonly property bool hoverMenus: Config.options.bar.statusMenusOnHover
    // A busy menu (typing a Wi-Fi password) holds the cay open.
    readonly property bool holdOpen: menuOpen && content.holdOpen

    // ── the menu ────────────────────────────────────────────────
    // The menu being shown; kept while the cay shrinks back so it can fade out.
    property string shown: ""
    onMenuChanged: {
        if (menu === "")
            return;
        if (shown === "" || Motion.reduceMotion)
            shown = menu;
        else
            swap.restart();
    }
    onGrownChanged: if (!grown && !menuOpen) shown = ""
    Timer {
        id: swap
        interval: Motion.contentFadeDelay
        onTriggered: root.shown = root.menu
    }

    readonly property real menuWidth: content.item ? content.item.width + Tokens.space4 * 2 : 0
    readonly property real menuHeight: content.item ? content.item.height + Tokens.space4 + Tokens.space2 : 0

    targetHeight: menuOpen && content.item ? Tokens.cayHeight + menuHeight : Tokens.cayHeight
    targetRadius: menuOpen ? Tokens.radiusXl : Tokens.cayHeight / 2
    contentWidth: layout.width

    ColorSpring {
        id: bg
        spec: Motion.effectsFast
        target: root.panelOpen ? Colors.surfaceContainerHighest
            : rowMouse.containsMouse && !root.menuOpen && !(rowMouse.under?.menu) ? Colors.surfaceContainerHigh
            : Colors.surfaceContainer
    }

    Spring {
        id: contentFade
        spec: Motion.effectsDefault
        target: root.menuOpen && root.shown === root.menu ? 1 : 0
    }

    MenuContent {
        id: content
        menu: root.shown
        live: root.menuOpen
        x: Tokens.space4 - root.leftPadding
        // Sits on the row and is uncovered as the cay grows upward.
        y: row.y - Tokens.space2 - height
        opacity: contentFade.value
        visible: opacity > 0.01
        enabled: root.menuOpen
        Accessible.role: Accessible.Dialog
        Accessible.name: title
    }

    // ── the row ─────────────────────────────────────────────────
    // x of every item (holder coordinates) and the row's width.
    readonly property var layout: {
        const gap = Tokens.cayGapStatus;
        const controls = [bell, net, vol, battery].filter(i => i.visible);
        const selected = controls.find(i => i.menu !== "" && i.menu === root.menu) ?? null;
        const inner = root.menuOpen ? root.menuWidth - root.leftPadding - root.rightPadding : 0;
        const xs = { clock: 0 };
        if (selected) {
            // The others close up after the clock; the chosen one goes to the end alone.
            let x = clock.implicitWidth;
            for (const i of controls) {
                if (i === selected)
                    continue;
                x += gap;
                xs[i.key] = x;
                x += i.implicitWidth;
            }
            const w = Math.max(x + Tokens.cayStatusSplit + selected.implicitWidth, inner);
            xs[selected.key] = w - selected.implicitWidth;
            return { xs: xs, width: w };
        }
        const controlsWidth = controls.reduce((s, i, n) => s + i.implicitWidth + (n > 0 ? gap : 0), 0);
        const w = Math.max(clock.implicitWidth + Tokens.cayStatusSplit + controlsWidth, inner);
        let x = w - controlsWidth;
        for (const i of controls) {
            xs[i.key] = x;
            x += i.implicitWidth + gap;
        }
        return { xs: xs, width: w };
    }

    Item {
        id: row
        width: parent.width
        height: Tokens.cayHeight
        y: parent.height - height

        StatusItem {
            id: clock
            screenName: root.screenName
            menu: "calendar"
            key: "clock"
            label: `${Time.time}. Calendar`
            targetX: root.layout.xs[key] ?? 0
            hovered: rowMouse.under === clock
            StyledText {
                style: "barTitle"
                text: Time.time
            }
        }

        StatusItem {
            id: bell
            screenName: root.screenName
            key: "bell"
            targetX: root.layout.xs[key] ?? 0
            Icon {
                name: Notifications.dnd ? "notifications_off" : Notifications.count > 0 ? "notifications_unread" : "notifications"
                filled: Notifications.count > 0
                size: Tokens.iconSm
                color: Notifications.count > 0 && !Notifications.dnd ? Colors.on.surface : Colors.on.surfaceVariant
            }
        }

        StatusItem {
            id: net
            screenName: root.screenName
            menu: "wifi"
            label: Network.label
            targetX: root.layout.xs[key] ?? 0
            hovered: rowMouse.under === net
            Icon {
                name: Network.icon
                size: Tokens.iconSm
                color: net.hovered || net.active ? Colors.on.surface : Colors.on.surfaceVariant
            }
        }

        StatusItem {
            id: vol
            screenName: root.screenName
            menu: "audio"
            label: Audio.label
            targetX: root.layout.xs[key] ?? 0
            hovered: rowMouse.under === vol
            Icon {
                name: Audio.icon
                size: Tokens.iconSm
                color: vol.hovered || vol.active ? Colors.on.surface : Colors.on.surfaceVariant
            }
        }

        StatusItem {
            id: battery
            screenName: root.screenName
            key: "battery"
            visible: Battery.present
            targetX: root.layout.xs[key] ?? 0
            Icon {
                name: Battery.icon
                size: Tokens.iconSm
                color: Battery.low ? Colors.error : Colors.on.surfaceVariant
            }
        }
    }

    // ── pointer ─────────────────────────────────────────────────
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: `Control center. ${Notifications.count} notifications${Notifications.dnd ? ", do not disturb" : ""}. ${Battery.present ? Battery.label : ""}`
    Keys.onReturnPressed: PanelState.toggle("controlCenter", screenName)
    Keys.onSpacePressed: PanelState.toggle("controlCenter", screenName)

    // The row: click → control center, rest on an item → its menu, scroll → volume.
    MouseArea {
        id: rowMouse
        parent: root
        z: 1
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Tokens.cayHeight
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        // The item under the pointer. Only real pointer movement updates it, so items
        // sliding under a resting pointer (the row re-forming) don't switch menus.
        property Item under: null
        property point last: Qt.point(-1, -1)

        function itemAt(px) {
            const half = Tokens.cayGapStatus / 2;
            for (const i of [clock, bell, net, vol, battery]) {
                const left = root.leftPadding + i.x;
                if (i.visible && px >= left - half && px <= left + i.width + half)
                    return i;
            }
            return null;
        }

        // Compared in window coordinates: the cay itself moves as it re-forms.
        function track(x, y) {
            const p = mapToItem(null, x, y);
            if (Math.abs(p.x - last.x) < 1 && Math.abs(p.y - last.y) < 1)
                return;
            last = p;
            under = itemAt(x);
        }
        onEntered: track(mouseX, mouseY)
        onPositionChanged: mouse => track(mouse.x, mouse.y)
        onExited: {
            under = null;
            last = Qt.point(-1, -1);
        }
        onClicked: {
            if (!root.hoverMenus && under && under.menu !== "")
                PanelState.toggleBarMenu(under.menu, root.screenName);
            else
                PanelState.toggle("controlCenter", root.screenName);
        }
        onWheel: event => {
            const d = event.angleDelta.y || -event.angleDelta.x;
            if (Math.abs(d) >= 1)
                Audio.setVolume(Audio.volume + (d > 0 ? 0.05 : -0.05));
        }
    }

    readonly property Item pointed: rowMouse.under
    onPointedChanged: {
        if (pointed && pointed.menu !== "" && pointed.menu !== menu && hoverMenus && !panelOpen)
            hoverOpen.restart();
        else
            hoverOpen.stop();
    }
    Timer {
        id: hoverOpen
        interval: Tokens.menuHoverDelay
        onTriggered: {
            const i = root.pointed;
            if (i && i.menu !== "" && !root.panelOpen)
                PanelState.openBarMenu(i.menu, root.screenName);
        }
    }

    // Leaving the grown cay closes its menu, unless it's busy or the keyboard drives it.
    // (The row's MouseArea takes hover from the handler beneath it, so count both.)
    readonly property bool pointerInside: cayHover.hovered || rowMouse.containsMouse
    Item {
        parent: root
        anchors.fill: parent
        HoverHandler {
            id: cayHover
        }
    }
    onPointerInsideChanged: updateClose()
    onMenuOpenChanged: updateClose()
    onHoldOpenChanged: updateClose()
    onKeyboardActiveChanged: updateClose()
    function updateClose() {
        if (menuOpen && !pointerInside && !holdOpen && !keyboardActive)
            hoverClose.restart();
        else
            hoverClose.stop();
    }
    Timer {
        id: hoverClose
        interval: Tokens.menuCloseDelay
        onTriggered: {
            if (root.menuOpen && !root.pointerInside && !root.holdOpen && !root.keyboardActive)
                PanelState.closeAll();
        }
    }
}
