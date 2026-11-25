import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.services
import qs.components
import qs.modules
import qs.modules.controlcenter
import qs.modules.bar

// Edit mode (SURFACES.md → Edit mode; screens/EditMode). A Tide panel on the left edge:
// full height, edit-panel-width wide, surface-container-low, concave fillets on its right
// edge, sliding in with spatial-default and pushing the bar and the home widgets aside.
// Four cards: the header with Done; home widget thumbnails (click to add, or drag one
// onto the desktop); the control center's quick toggles, which drag to rearrange; and
// the bar (move it to the left, the Spotlight cay, the bar on other monitors).
// Done, Escape or Super+E leave. It holds the keyboard while open; the desktop and the
// Island stay usable beside it.
PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    anchors {
        top: true
        bottom: true
        left: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "reef-editmode"
    implicitWidth: Tokens.editPanelWidth + Tokens.radiusXl

    readonly property string screenName: modelData.name
    readonly property bool open: PanelState.panel === "editMode" && PanelState.screenName === screenName

    Spring {
        id: slide
        spec: Motion.spatialDefault
        target: root.open ? 0 : -root.implicitWidth
    }
    visible: open || slide.value > -root.implicitWidth + 0.5
    mask: Region { item: panel }

    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onOpenChanged: if (open) focusFirst.restart()
    Timer {
        id: focusFirst
        interval: 1
        onTriggered: done.forceActiveFocus()
    }
    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: PanelState.closeAll()
    }

    // ── panel ───────────────────────────────────────────────────
    Item {
        id: panel
        x: slide.value
        width: root.width
        height: root.height

        EdgeFillet {
            anchors.top: parent.top
            anchors.left: body.right
            corner: "topLeft"
            color: Colors.surfaceContainerLow
        }
        EdgeFillet {
            anchors.bottom: parent.bottom
            anchors.left: body.right
            corner: "bottomLeft"
            color: Colors.surfaceContainerLow
        }

        Rectangle {
            id: body
            width: Tokens.editPanelWidth
            height: parent.height
            color: Colors.surfaceContainerLow

            Accessible.role: Accessible.Pane
            Accessible.name: "Edit mode"

            Column {
                id: cards
                anchors.fill: parent
                anchors.margins: Tokens.space3
                spacing: Tokens.space2_5

                // ── header ──
                Card {
                    id: headerCard
                    width: parent.width
                    title: "Edit mode"
                    header: [
                        Chip {
                            id: done
                            tone: "accent"
                            text: "Done"
                            onClicked: PanelState.closeAll()
                        }
                    ]
                }

                // ── home widgets ──
                Card {
                    id: widgetsCard
                    width: parent.width
                    title: "Home widgets"

                    // Two per row; Media takes a row of its own.
                    Flow {
                        id: thumbs
                        width: parent.width
                        spacing: Tokens.space2
                        readonly property real cell: (width - spacing) / 2

                        Repeater {
                            model: Home.kinds
                            WidgetThumb {
                                required property string modelData
                                kind: modelData
                                width: modelData === "media" ? thumbs.width : thumbs.cell
                            }
                        }
                    }
                }

                // ── control center layout ──
                Card {
                    id: tilesCard
                    width: parent.width
                    title: "Control center"

                    TileLayout {
                        width: parent.width
                    }
                }

                // ── bar ──
                Card {
                    id: barCard
                    width: parent.width
                    height: Math.max(implicitHeight, parent.height - headerCard.height - widgetsCard.height - tilesCard.height - parent.spacing * 3)
                    title: "Bar"

                    readonly property bool barLeft: Config.monitor(root.screenName).barPosition === "left"
                    readonly property var others: Quickshell.screens.map(s => s.name).filter(n => n !== root.screenName)

                    RowButton {
                        width: parent.width
                        icon: barCard.barLeft ? "dock_to_bottom" : "dock_to_left"
                        trailingIcon: barCard.barLeft ? "arrow_downward" : "arrow_back"
                        text: barCard.barLeft ? "Move bar to bottom" : "Move bar to left"
                        onClicked: Config.setMonitor(root.screenName, "barPosition", barCard.barLeft ? "bottom" : "left")
                    }
                    CayOrder {
                        width: parent.width
                    }
                    SwitchRow {
                        width: parent.width
                        text: "Workspaces in their own cay"
                        checked: Config.options.bar.workspacesCay
                        onToggled: Config.options.bar.workspacesCay = !checked
                    }
                    SwitchRow {
                        width: parent.width
                        text: "Show Spotlight cay"
                        checked: Config.options.bar.showSpotlight
                        onToggled: Config.options.bar.showSpotlight = !Config.options.bar.showSpotlight
                    }
                    SwitchRow {
                        width: parent.width
                        text: "Bar on other monitors"
                        enabled: barCard.others.length > 0
                        checked: barCard.others.length > 0 && barCard.others.every(n => Config.monitor(n).showBar)
                        onToggled: {
                            const on = !checked;
                            for (const n of barCard.others)
                                Config.setMonitor(n, "showBar", on);
                        }
                    }
                }
            }
        }
    }

    // ── pieces ──────────────────────────────────────────────────

    // A home widget thumbnail: a small picture of the widget and its name. Click (or
    // Enter) adds it; dragging it onto the desktop adds it there.
    component WidgetThumb: Item {
        id: thumb
        property string kind
        height: Tokens.editThumbHeight

        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: "Add " + Home.labels[kind] + " widget"
        Keys.onReturnPressed: Home.place(root.screenName, kind)
        Keys.onSpacePressed: Home.place(root.screenName, kind)

        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.CopyAction
        Drag.mimeData: ({ "application/x-reef-widget": kind })
        Drag.active: thumbDrag.active
        Drag.hotSpot.x: thumbDrag.centroid.pressPosition.x
        Drag.hotSpot.y: thumbDrag.centroid.pressPosition.y
        DragHandler {
            id: thumbDrag
            target: null
            onActiveChanged: if (active) face.grabToImage(r => thumb.Drag.imageSource = r.url)
        }

        Spring {
            id: thumbCorner
            spec: Motion.spatialFast
            target: thumbMouse.pressed ? Tokens.radiusMd : Tokens.radiusTile
        }
        Rectangle {
            id: face
            anchors.fill: parent
            radius: thumbCorner.value
            color: Colors.surfaceContainerHigh
            border.width: thumb.activeFocus ? 2 : 0
            border.color: Colors.primary

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Colors.on.surface
                opacity: thumbMouse.pressed ? Tokens.statePressedOpacity : thumbMouse.containsMouse ? Tokens.stateHoverOpacity : 0
            }

            Column {
                anchors.centerIn: parent
                spacing: Tokens.cayPaddingTight

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: thumb.kind === "media" ? Tokens.editThumbMediaWidth : thumb.kind === "system" ? Tokens.editThumbBarsWidth : Tokens.editThumbGlyph
                    height: thumb.kind === "media" ? Tokens.editThumbMediaHeight : Tokens.editThumbGlyph

                    // clock: the glyph on a circle
                    Rectangle {
                        anchors.fill: parent
                        visible: thumb.kind === "clock"
                        radius: width / 2
                        color: Colors.surfaceContainerHighest
                        Icon {
                            anchors.centerIn: parent
                            name: "schedule"
                            size: Tokens.editThumbIcon
                            color: Colors.primary
                        }
                    }
                    // weather: its cookie
                    ShapeItem {
                        anchors.fill: parent
                        visible: thumb.kind === "weather"
                        radii: Shapes.sample("cookie12", width, height)
                        color: Colors.tertiaryContainer
                    }
                    // media: its pill
                    Rectangle {
                        anchors.fill: parent
                        visible: thumb.kind === "media"
                        radius: height / 2
                        color: Colors.primaryContainer
                    }
                    // system: three meters
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        visible: thumb.kind === "system"
                        spacing: Tokens.space1
                        Repeater {
                            model: [0.4, 0.8, 0.6]
                            Rectangle {
                                required property real modelData
                                width: parent.width * modelData
                                height: Tokens.editThumbBar
                                radius: height / 2
                                color: Colors.primary
                            }
                        }
                    }
                    // calendar: the glyph
                    Icon {
                        anchors.centerIn: parent
                        visible: thumb.kind === "calendar"
                        name: "calendar_month"
                        size: Tokens.editThumbCalendarIcon
                        color: Colors.secondary
                    }
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    style: "tileSublabel"
                    color: Colors.on.surfaceVariant
                    text: Home.labels[thumb.kind]
                }
            }
        }
        MouseArea {
            id: thumbMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Home.place(root.screenName, thumb.kind)
        }
    }

    // The control center's quick toggles as small tiles in their four-column layout.
    // Drag one to a new place (the others make room as it moves), or move the focused
    // one with the arrow keys. Saved when let go.
    component TileLayout: Item {
        id: layout
        readonly property real gap: Tokens.cayPaddingTight
        readonly property real cell: (width - gap * (QuickTiles.columns - 1)) / QuickTiles.columns
        // While dragging: the order with the dragged tile moved to where it would land.
        property string dragging: ""
        property int dropIndex: -1
        readonly property var shown: {
            const o = QuickTiles.order.slice();
            if (dragging === "" || dropIndex < 0)
                return o;
            o.splice(o.indexOf(dragging), 1);
            o.splice(Math.min(dropIndex, o.length), 0, dragging);
            return o;
        }
        readonly property var slots: QuickTiles.slots(shown)
        implicitHeight: QuickTiles.pack(shown).length * (Tokens.editTileHeight + gap) - gap

        function slotX(id) { const s = slots[id]; return s ? s.col * (cell + gap) : 0; }
        function slotY(id) { const s = slots[id]; return s ? s.row * (Tokens.editTileHeight + gap) : 0; }
        function slotW(id) { const s = slots[id]; return s ? s.span * cell + (s.span - 1) * gap : 0; }

        // The index in the order whose slot is nearest to (x, y).
        function nearest(id, x, y) {
            const others = QuickTiles.order.filter(t => t !== id);
            let best = 0, bestD = Infinity;
            for (let i = 0; i <= others.length; i++) {
                const trial = others.slice();
                trial.splice(i, 0, id);
                const s = QuickTiles.slots(trial)[id];
                const cx = s.col * (cell + gap) + (s.span * cell + (s.span - 1) * gap) / 2;
                const cy = s.row * (Tokens.editTileHeight + gap) + Tokens.editTileHeight / 2;
                const d = (cx - x) * (cx - x) + (cy - y) * (cy - y);
                if (d < bestD) {
                    bestD = d;
                    best = i;
                }
            }
            return best;
        }

        function moveBy(id, step) {
            const o = QuickTiles.order.slice();
            const i = o.indexOf(id), j = Math.max(0, Math.min(o.length - 1, i + step));
            if (i === j)
                return;
            o.splice(i, 1);
            o.splice(j, 0, id);
            QuickTiles.setOrder(o);
        }

        Repeater {
            model: QuickTiles.all

            Item {
                id: mini
                required property string modelData
                readonly property bool on: QuickTiles.checked(modelData)
                readonly property bool held: tileDrag.active

                width: layout.slotW(modelData)
                height: Tokens.editTileHeight
                z: held ? 1 : 0

                Spring { id: mx; spec: Motion.spatialDefault; target: layout.slotX(mini.modelData) }
                Spring { id: my; spec: Motion.spatialDefault; target: layout.slotY(mini.modelData) }
                // Where the drag started and its offset, kept here: the others reflow under
                // it while it moves, and DragHandler zeroes its translation as it lets go.
                property real startX: 0
                property real startY: 0
                property real dx: 0
                property real dy: 0
                x: held ? startX + dx : mx.value
                y: held ? startY + dy : my.value
                scale: held && !Motion.reduceMotion ? 1.05 : 1

                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: `${QuickTiles.label(modelData)}, ${QuickTiles.order.indexOf(modelData) + 1} of ${QuickTiles.order.length}`
                Keys.onLeftPressed: layout.moveBy(modelData, -1)
                Keys.onRightPressed: layout.moveBy(modelData, 1)
                Keys.onUpPressed: layout.moveBy(modelData, -2)
                Keys.onDownPressed: layout.moveBy(modelData, 2)

                DragHandler {
                    id: tileDrag
                    target: null
                    cursorShape: Qt.ClosedHandCursor
                    onActiveChanged: {
                        if (active) {
                            mini.startX = mx.value;
                            mini.startY = my.value;
                            mini.dx = 0;
                            mini.dy = 0;
                            layout.dragging = mini.modelData;
                        } else {
                            // Spring from where it was let go into its new place.
                            mx.restartFrom(mini.startX + mini.dx);
                            my.restartFrom(mini.startY + mini.dy);
                            const order = layout.shown;
                            layout.dragging = "";
                            layout.dropIndex = -1;
                            QuickTiles.setOrder(order);
                        }
                    }
                    onActiveTranslationChanged: {
                        if (!active)
                            return;
                        mini.dx = activeTranslation.x;
                        mini.dy = activeTranslation.y;
                        layout.dropIndex = layout.nearest(mini.modelData, mini.startX + mini.dx + mini.width / 2, mini.startY + mini.dy + mini.height / 2);
                    }
                }
                HoverHandler {
                    cursorShape: Qt.OpenHandCursor
                }

                Rectangle {
                    anchors.fill: parent
                    radius: mini.on ? height / 2 : Tokens.radiusMd
                    color: mini.on ? Colors.primaryContainer : Colors.surfaceContainerHigh
                    border.width: mini.activeFocus || mini.held ? 2 : 0
                    border.color: Colors.primary
                }
                Icon {
                    anchors.centerIn: parent
                    name: QuickTiles.icon(mini.modelData)
                    filled: true
                    size: Tokens.iconSm
                    color: mini.on ? Colors.on.primaryContainer : Colors.on.surfaceVariant
                }
            }
        }
    }

    // A full-width pill button with a leading icon (Move bar to left).
    component RowButton: Item {
        id: rowButton
        property string icon
        property string trailingIcon
        property string text
        signal clicked

        implicitHeight: Tokens.editRowHeight
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: text
        Keys.onReturnPressed: clicked()
        Keys.onSpacePressed: clicked()

        Spring {
            id: rowCorner
            spec: Motion.spatialFast
            target: rowMouse.pressed ? Tokens.radiusMd : rowButton.height / 2
        }
        Rectangle {
            anchors.fill: parent
            radius: rowCorner.value
            color: Colors.surfaceContainerHigh
            border.width: rowButton.activeFocus ? 2 : 0
            border.color: Colors.primary
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Colors.on.surface
                opacity: rowMouse.pressed ? Tokens.statePressedOpacity : rowMouse.containsMouse ? Tokens.stateHoverOpacity : 0
            }
        }
        Row {
            x: Tokens.space4
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Tokens.space4 * 2
            spacing: Tokens.space2_5
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: rowButton.icon
                size: Tokens.iconMd
                color: Colors.primary
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - Tokens.iconMd - Tokens.iconSm - parent.spacing * 2
                style: "tileLabel"
                elide: Text.ElideRight
                text: rowButton.text
            }
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: rowButton.trailingIcon
                size: Tokens.iconSm
                color: Colors.on.surfaceVariant
            }
        }
        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: rowButton.clicked()
        }
    }
}
