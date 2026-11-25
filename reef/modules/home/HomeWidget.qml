import QtQuick
import QtQuick.Shapes
import qs.theme
import qs.services
import qs.components

// One home widget on the desktop, with its edit-mode chrome (screens/EditMode): a dashed
// primary outline edit-outline-gap outside its shape, a remove badge on the outline's
// top-left, and a slight wiggle (off with Reduce motion or home.wiggle). While editing,
// drag it anywhere: it follows the pointer, a tinted outline shows the home-grid cell it
// will land in, and when let go it springs there (spatial-default) and is saved.
Item {
    id: root

    required property string widgetId
    required property var entry          // { id, kind, x, y }
    required property string screenName
    required property int index
    property bool editing: false
    property real wigglePhase: 0
    property real wiggleAmount: 0        // 0..1, eases in and out with edit mode
    // Bounds the widget is kept inside (the free desktop, not pushed by the panel).
    property real boundsWidth: 0
    property real boundsHeight: 0

    readonly property Item content: loader.item
    readonly property real outlineRadius: content?.outlineRadius ?? Tokens.radiusXl
    readonly property bool dragging: drag.active

    implicitWidth: content?.implicitWidth ?? 0
    implicitHeight: content?.implicitHeight ?? 0
    width: implicitWidth
    height: implicitHeight

    // Kept inside the free desktop; snapped to home-grid (the last cell may be short so a
    // widget can still reach the edge).
    function clampX(v) { return Math.max(0, Math.min(boundsWidth - width, v)); }
    function clampY(v) { return Math.max(0, Math.min(boundsHeight - height, v)); }
    function snapX(v) { return clampX(Math.round(v / Tokens.homeGrid) * Tokens.homeGrid); }
    function snapY(v) { return clampY(Math.round(v / Tokens.homeGrid) * Tokens.homeGrid); }

    // Where the pointer has it, and the cell it would land in.
    // The drag's offset, kept here: DragHandler resets activeTranslation as it lets go,
    // before onActiveChanged runs.
    property real dx: 0
    property real dy: 0
    readonly property real freeX: clampX((entry?.x ?? 0) + dx)
    readonly property real freeY: clampY((entry?.y ?? 0) + dy)
    readonly property real landX: snapX(freeX)
    readonly property real landY: snapY(freeY)

    Spring { id: px; spec: Motion.spatialDefault; target: root.clampX(root.entry?.x ?? 0) }
    Spring { id: py; spec: Motion.spatialDefault; target: root.clampY(root.entry?.y ?? 0) }
    x: dragging ? freeX : px.value
    y: dragging ? freeY : py.value
    z: dragging ? 1 : 0
    rotation: dragging ? 0 : Tokens.editWiggle * wiggleAmount * Math.sin(wigglePhase * 2 * Math.PI + index * 1.7)
    scale: dragging && !Motion.reduceMotion ? 1.02 : 1

    Loader {
        id: loader
        source: {
            switch (root.entry?.kind) {
            case "clock": return "ClockWidget.qml";
            case "weather": return "WeatherWidget.qml";
            case "media": return "MediaWidget.qml";
            case "system": return "SystemWidget.qml";
            case "calendar": return "CalendarWidget.qml";
            }
            return "";
        }
    }
    // Widgets don't take clicks while they're being arranged.
    Binding {
        when: loader.item !== null
        target: loader.item
        property: "interactive"
        value: !root.editing
    }

    // ── edit chrome ─────────────────────────────────────────────
    // While dragging: the cell it will land in, tinted primary with a dashed edge.
    Rectangle {
        x: root.landX - root.x
        y: root.landY - root.y
        width: root.width
        height: root.height
        z: -1
        visible: root.dragging
        radius: Math.min(root.outlineRadius, width / 2, height / 2)
        color: Qt.alpha(Colors.primary, Tokens.dropTargetOpacity)
        border.width: Tokens.editOutline
        border.color: Qt.alpha(Colors.primary, Tokens.homeGridDotsOpacity)
    }

    Spring {
        id: chrome
        spec: Motion.effectsDefault
        target: root.editing ? 1 : 0
    }

    readonly property real _gap: Tokens.editOutlineGap
    Shape {
        x: -root._gap
        y: -root._gap
        width: root.width + root._gap * 2
        height: root.height + root._gap * 2
        opacity: chrome.value
        visible: opacity > 0.01
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: Colors.primary
            strokeWidth: Tokens.editOutline
            strokeStyle: ShapePath.DashLine
            dashPattern: [Tokens.editDash / Tokens.editOutline, Tokens.editDash / Tokens.editOutline]
            PathRectangle {
                x: Tokens.editOutline / 2
                y: Tokens.editOutline / 2
                width: root.width + root._gap * 2 - Tokens.editOutline
                height: root.height + root._gap * 2 - Tokens.editOutline
                radius: Math.min(root.outlineRadius + root._gap, Math.min(width, height) / 2)
            }
        }
    }

    // Moving: the whole widget is the handle while editing.
    DragHandler {
        id: drag
        enabled: root.editing
        target: null
        cursorShape: Qt.ClosedHandCursor
        onActiveTranslationChanged: {
            if (active) {
                root.dx = activeTranslation.x;
                root.dy = activeTranslation.y;
            }
        }
        onActiveChanged: {
            if (active) {
                root.dx = 0;
                root.dy = 0;
                return;
            }
            // Spring from where it was let go into its cell.
            const fx = root.freeX, fy = root.freeY;
            px.restartFrom(fx);
            py.restartFrom(fy);
            Home.move(root.screenName, root.widgetId, root.snapX(fx), root.snapY(fy));
            root.dx = 0;
            root.dy = 0;
        }
    }
    HoverHandler {
        enabled: root.editing
        cursorShape: Qt.OpenHandCursor
    }

    // Remove badge
    Item {
        id: badge
        x: -root._gap - Tokens.editBadge / 2 + Tokens.editOutline
        y: x
        width: Tokens.editBadge
        height: Tokens.editBadge
        opacity: chrome.value
        scale: 0.6 + 0.4 * chrome.value
        visible: opacity > 0.01
        enabled: root.editing

        activeFocusOnTab: root.editing
        Accessible.role: Accessible.Button
        Accessible.name: "Remove " + (Home.labels[root.entry?.kind] ?? "widget")
        Keys.onReturnPressed: Home.remove(root.screenName, root.widgetId)
        Keys.onSpacePressed: Home.remove(root.screenName, root.widgetId)

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: badgeMouse.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
            border.width: Tokens.editOutline
            border.color: Colors.primary
        }
        Icon {
            anchors.centerIn: parent
            name: "remove"
            size: Tokens.editBadgeIcon
            color: Colors.primary
        }
        MouseArea {
            id: badgeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Home.remove(root.screenName, root.widgetId)
        }
    }
}
