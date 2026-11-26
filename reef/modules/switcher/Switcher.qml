import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.theme
import qs.services
import qs.components
import qs.modules

// Alt+Tab window switcher (SURFACES.md → Window switcher; screens/Switcher).
// A surface-container-low radius-xl card in the middle of the focused monitor holding
// live window thumbnails, most recently used first, each with its app icon and name.
// The selected one has a primary ring.
//
// Alt+Tab opens it on the previous window; each further Tab (Shift+Tab back) moves the
// selection; releasing Alt switches to it. Enter or a click switches too; Escape or a
// click elsewhere cancels.
PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "reef-switcher"

    readonly property real shadowRoom: Colors.shadowMenu.blur + Math.abs(Colors.shadowMenu.y)
    implicitWidth: card.width + shadowRoom * 2
    implicitHeight: card.height + shadowRoom * 2

    property bool open: false
    property int selected: 0
    readonly property var windows: Workspaces.recentWindows

    // Always mapped (the compositor animates layers as they map and unmap, on top of
    // ours); closed, it's transparent and takes no input.
    visible: true
    mask: Region { item: inputArea }
    Item {
        id: inputArea
        anchors.centerIn: parent
        width: root.open ? card.width : 0
        height: root.open ? card.height : 0
    }

    Connections {
        target: Actions
        function onSwitcherRequested(step) {
            if (Monitors.focused !== (root.modelData?.name ?? "")) {
                root.open = false;
                return;
            }
            if (!root.open) {
                Workspaces.refresh();
                if (root.windows.length === 0)
                    return;
                PanelState.closeAll();
                // Start on the window before this one (or the last, going back).
                root.selected = root.windows.length < 2 ? 0 : step > 0 ? 1 : root.windows.length - 1;
                root.open = true;
            } else {
                root.move(step);
            }
        }
    }

    function move(by) {
        const n = windows.length;
        if (n > 0)
            selected = (selected + by + n) % n;
    }

    function commit() {
        const t = windows[selected];
        open = false;
        Workspaces.afterHandoff(() => Workspaces.focusWindow(t));
    }

    // ── motion ──────────────────────────────────────────────────
    Spring {
        id: fade
        spec: Motion.effectsDefault
        target: root.open ? 1 : 0
    }
    Spring {
        id: grow
        spec: Motion.spatialFast
        target: root.open ? 1 : 0
    }

    // ── keyboard and dismissal ──────────────────────────────────
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onOpenChanged: {
        if (open)
            focusFirst.restart();
        else
            grab.armed = false;
    }
    Timer {
        id: focusFirst
        interval: 1
        onTriggered: {
            keys.forceActiveFocus();
            armGrab.restart();
        }
    }
    Timer {
        id: armGrab
        interval: 150
        onTriggered: grab.armed = root.open
    }
    HyprlandFocusGrab {
        id: grab
        property bool armed: false
        windows: [root]
        active: root.open && armed
        onCleared: root.open = false
    }
    Item {
        id: keys
        focus: true
        // Letting go of Alt switches.
        Keys.onReleased: event => {
            if (root.open && (event.key === Qt.Key_Alt || event.key === Qt.Key_AltGr))
                root.commit();
        }
        Keys.onTabPressed: root.move(1)
        Keys.onBacktabPressed: root.move(-1)
        Keys.onRightPressed: root.move(1)
        Keys.onLeftPressed: root.move(-1)
        Keys.onReturnPressed: root.commit()
        Keys.onEnterPressed: root.commit()
        Keys.onEscapePressed: root.open = false
    }

    // ── card ────────────────────────────────────────────────────
    RectangularShadow {
        anchors.fill: card
        radius: card.radius
        offset.x: Colors.shadowMenu.x
        offset.y: Colors.shadowMenu.y
        blur: Colors.shadowMenu.blur
        color: Colors.shadowMenu.color
        opacity: card.opacity
        scale: card.scale
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: list.width + Tokens.space4 * 2
        height: list.height + Tokens.space4 * 2
        radius: Tokens.radiusXl
        color: Colors.surfaceContainerLow
        opacity: fade.value
        scale: 0.92 + 0.08 * grow.value

        Accessible.role: Accessible.List
        Accessible.name: "Windows"

        ListView {
            id: list
            x: Tokens.space4
            y: Tokens.space4
            orientation: ListView.Horizontal
            spacing: Tokens.space3
            width: Math.min(contentWidth, (root.modelData?.width ?? 0) - Tokens.space12 * 2 - Tokens.space4 * 2)
            height: Tokens.switcherThumbHeight + Tokens.space2_5 + Tokens.iconMd + Tokens.overviewRing
            clip: true
            interactive: false
            currentIndex: root.selected
            highlightMoveDuration: Motion.duration(Motion.spatialDefault)
            preferredHighlightBegin: width / 2 - Tokens.switcherThumbWidth / 2
            preferredHighlightEnd: width / 2 + Tokens.switcherThumbWidth / 2
            highlightRangeMode: contentWidth > width ? ListView.ApplyRange : ListView.NoHighlightRange
            model: root.open ? root.windows : []

            delegate: Item {
                id: item
                required property var modelData
                required property int index
                readonly property bool current: index === root.selected
                readonly property var entry: Apps.entryFor(modelData.lastIpcObject?.class ?? "")

                width: Tokens.switcherThumbWidth
                height: list.height

                Accessible.role: Accessible.ListItem
                Accessible.name: (entry?.name ?? modelData.title) + ", " + modelData.title
                Accessible.selected: current

                WindowThumb {
                    id: thumb
                    y: Tokens.overviewRing
                    width: Tokens.switcherThumbWidth
                    height: Tokens.switcherThumbHeight
                    radius: Tokens.radiusLg
                    fit: true
                    toplevel: item.modelData
                    live: root.open
                }

                // The ring around the selected window, just outside its picture.
                Rectangle {
                    anchors.fill: thumb
                    anchors.margins: -Tokens.overviewRing
                    radius: Tokens.radiusLg + Tokens.overviewRing
                    color: "transparent"
                    border.width: Tokens.overviewRing
                    border.color: Colors.primary
                    opacity: ring.value
                    Spring {
                        id: ring
                        spec: Motion.effectsFast
                        target: item.current ? 1 : 0
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: thumb.bottom
                    anchors.topMargin: Tokens.space2_5
                    spacing: Tokens.space2
                    width: Math.min(implicitWidth, parent.width)

                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: Tokens.iconMd
                        source: Quickshell.iconPath(item.entry?.icon ?? item.modelData.lastIpcObject?.class ?? "", "application-x-executable")
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, item.width - Tokens.iconMd - parent.spacing)
                        elide: Text.ElideRight
                        style: item.current ? "searchTitle" : "labelLg"
                        color: item.current ? Colors.on.surface : Colors.on.surfaceVariant
                        text: item.entry?.name ?? item.modelData.lastIpcObject?.class ?? item.modelData.title
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selected = item.index;
                        root.commit();
                    }
                }
            }
        }
    }
}
