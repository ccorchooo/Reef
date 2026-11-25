import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.components
import qs.modules

// The app menu (SURFACES.md → Bar → Dock; Search): right-click a Dock tile or an app in
// search, or press the Menu key (Shift+F10) on one. A surface-container-high radius-xl
// card with shadow-menu, drawn in the bar's surface: the app's icon and name, then Open /
// New window, the app's own actions, Pin to Dock / Unpin from Dock, Hide from search (from
// search) and Close window. It pops from its anchor (spatial-fast scale, effects-fast
// fade). Up/Down move, Enter picks, Escape or a click anywhere else closes it.
Item {
    id: root

    property bool barLeft: false
    readonly property bool open: _open
    // The app: { id, entry } (entry may be null for a window without a desktop entry).
    property var app: null
    property string source: "dock"          // dock | search
    // After the menu closes (the bar hands the keyboard back).
    signal dismissed

    property bool _open: false
    // The anchor in the parent's coordinates: a tile (rect) or the pointer (w = h = 0).
    property rect _anchor: Qt.rect(0, 0, 0, 0)

    readonly property string appId: app?.entry?.id ?? app?.id ?? ""
    readonly property var windows: _open || opacity > 0 ? Apps.windowsOf(appId) : []

    readonly property var actions: {
        const out = [];
        const e = app?.entry;
        if (!app)
            return out;
        const leaving = () => { if (root.source === "search") PanelState.closeAll(); };
        if (e)
            out.push({ icon: windows.length > 0 ? "add" : "open_in_new", text: windows.length > 0 ? "New window" : "Open", run: () => { Apps.launch(e); leaving(); } });
        for (const a of Array.from(e?.actions ?? []))
            out.push({ icon: "arrow_forward", text: a.name, run: () => { a.execute(); leaving(); } });
        if (e) {
            const pinned = Apps.isPinned(e.id);
            out.push({ icon: pinned ? "keep_off" : "keep", text: pinned ? "Unpin from Dock" : "Pin to Dock", run: () => Apps.togglePin(e.id) });
        }
        if (e && root.source === "search")
            out.push({ icon: "visibility_off", text: "Hide from search", run: () => Apps.setHidden(e.id, true) });
        if (windows.length > 0)
            out.push({ icon: "close", text: windows.length > 1 ? `Close ${windows.length} windows` : "Close window", run: () => Apps.closeWindows(root.appId) });
        return out;
    }

    // Opens for `app` next to `item` (a Dock tile), or at `point` in `item` (the pointer).
    function show(app, source, item, point) {
        root.app = app;
        root.source = source;
        const p = point ? item.mapToItem(parent, point.x, point.y) : item.mapToItem(parent, 0, 0);
        _anchor = point ? Qt.rect(p.x, p.y, 0, 0) : Qt.rect(p.x, p.y, item.width, item.height);
        _open = true;
        pop.restartFrom(Motion.reduceMotion ? 1 : 0.85);
        focusFirst.restart();
    }

    function hide() {
        if (!_open)
            return;
        _open = false;
        dismissed();
    }

    Timer {
        id: focusFirst
        interval: 1
        onTriggered: rows.itemAt(0)?.forceActiveFocus()
    }

    // ── placement ───────────────────────────────────────────────
    readonly property bool _atPointer: _anchor.width === 0 && _anchor.height === 0
    readonly property real _maxX: parent ? parent.width - width - Tokens.space2 : 0
    readonly property real _maxY: parent ? parent.height - height - Tokens.space2 : 0
    function _clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }

    width: Tokens.appMenuWidth
    height: column.implicitHeight + Tokens.space2 * 2
    x: _atPointer ? _clamp(_anchor.x, Tokens.space2, _maxX)
        : barLeft ? _anchor.x + _anchor.width + Tokens.space2
        : _clamp(_anchor.x + _anchor.width / 2 - width / 2, Tokens.space2, _maxX)
    y: _atPointer ? (_anchor.y - height >= Tokens.space2 ? _anchor.y - height : _clamp(_anchor.y, Tokens.space2, _maxY))
        : barLeft ? _clamp(_anchor.y + _anchor.height / 2 - height / 2, Tokens.space2, _maxY)
        : _anchor.y - height - Tokens.space2
    transformOrigin: _atPointer ? Item.BottomLeft : barLeft ? Item.Left : Item.Bottom

    opacity: fade.value
    scale: pop.value
    visible: opacity > 0.01
    enabled: _open

    Spring {
        id: fade
        spec: Motion.effectsFast
        target: root._open ? 1 : 0
    }
    Spring {
        id: pop
        spec: Motion.spatialFast
        target: root._open ? 1 : 0.92
    }

    Accessible.role: Accessible.PopupMenu
    Accessible.name: (app?.entry?.name ?? app?.id ?? "App") + " menu"

    RectangularShadow {
        anchors.fill: card
        radius: card.radius
        offset.x: Colors.shadowMenu.x
        offset.y: Colors.shadowMenu.y
        blur: Colors.shadowMenu.blur
        color: Colors.shadowMenu.color
        cached: true
    }
    Rectangle {
        id: card
        anchors.fill: parent
        radius: Tokens.radiusXl
        color: Colors.surfaceContainerHigh
    }

    Column {
        id: column
        x: Tokens.space2
        y: Tokens.space2
        width: parent.width - Tokens.space2 * 2
        spacing: Tokens.spaceHalf

        // Header: the app's icon and name.
        Row {
            x: Tokens.space2
            height: Tokens.appMenuRow + Tokens.space1
            spacing: Tokens.space3
            IconImage {
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: Tokens.appMenuIcon
                source: root.app ? Apps.iconFor(root.app) : ""
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                width: column.width - Tokens.appMenuIcon - Tokens.space3 - Tokens.space4
                style: "tileLabel"
                elide: Text.ElideRight
                text: root.app ? Apps.nameFor(root.app) : ""
            }
        }

        Repeater {
            id: rows
            model: root.actions

            Item {
                id: row
                required property var modelData
                required property int index
                width: column.width
                height: Tokens.appMenuRow

                activeFocusOnTab: root._open
                Accessible.role: Accessible.MenuItem
                Accessible.name: modelData.text
                function pick() {
                    const run = modelData.run;
                    root.hide();
                    run();
                }
                Keys.onReturnPressed: pick()
                Keys.onEnterPressed: pick()
                Keys.onSpacePressed: pick()
                Keys.onUpPressed: rows.itemAt((index - 1 + rows.count) % rows.count)?.forceActiveFocus()
                Keys.onDownPressed: rows.itemAt((index + 1) % rows.count)?.forceActiveFocus()
                Keys.onEscapePressed: root.hide()

                Rectangle {
                    anchors.fill: parent
                    radius: Tokens.radiusLg
                    color: Qt.alpha(Colors.on.surface, rowMouse.pressed ? Tokens.statePressedOpacity : rowMouse.containsMouse ? Tokens.stateHoverOpacity : 0)
                    border.width: row.activeFocus ? 2 : 0
                    border.color: Colors.primary
                }
                Row {
                    x: Tokens.space3
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.space3
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: row.modelData.icon
                        size: Tokens.iconSm
                        color: Colors.on.surfaceVariant
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        width: row.width - Tokens.iconSm - Tokens.space3 * 3
                        style: "segmentLabel"
                        elide: Text.ElideRight
                        text: row.modelData.text
                    }
                }
                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: row.pick()
                }
            }
        }
    }
}
