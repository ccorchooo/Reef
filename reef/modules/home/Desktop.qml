import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.services
import qs.components
import qs.modules

// The desktop layer (screens/Home, screens/EditMode): home widgets on a bottom-layer
// surface over the wallpaper, inside the free desktop (it keeps clear of the bar's
// exclusive zone). In edit mode the edit panel pushes it aside like the bar, an
// edit-scrim of black dims the wallpaper, every widget gets its dashed outline and
// remove badge and wiggles, and a widget thumbnail dropped here adds that widget.
// Edit mode shows the home screen: if the monitor's workspace has windows, it goes to an
// empty one (Workspaces.goHome) and comes back when edit mode ends. While a widget is
// dragged, dots show the home-grid it snaps to.
PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "reef-home"

    readonly property string screenName: (modelData?.name ?? "")
    readonly property bool editing: PanelState.panel === "editMode" && PanelState.screenName === screenName
    readonly property var layout: Home.layout(screenName)

    onEditingChanged: editing ? Workspaces.goHome(screenName) : Workspaces.leaveHome(screenName)

    property int _dragging: 0
    readonly property bool anyDragging: _dragging > 0

    // Only the widgets take input, except while editing (drops land anywhere).
    mask: Region {
        item: root.editing ? everything : widgetBounds
    }
    Item {
        id: everything
        anchors.fill: parent
    }
    Item {
        id: widgetBounds
        x: widgets.x + widgets.childrenRect.x
        y: widgets.y + widgets.childrenRect.y
        width: widgets.childrenRect.width
        height: widgets.childrenRect.height
    }

    // ── edit mode ───────────────────────────────────────────────
    Spring {
        id: push
        spec: Motion.spatialDefault
        target: root.editing && Config.options.bar.panelsPushBar ? Tokens.editPanelWidth : 0
    }
    Spring {
        id: scrim
        spec: Motion.effectsSlow
        target: root.editing ? 1 : 0
    }
    Spring {
        id: wiggle
        spec: Motion.effectsDefault
        target: root.editing && Config.options.home.wiggle && Performance.idleMotion && !Motion.reduceMotion ? 1 : 0
    }
    property real phase: 0
    FrameAnimation {
        running: wiggle.value > 0.001
        onTriggered: root.phase = (root.phase + frameTime * Motion.speed / (Tokens.editWigglePeriod / 1000)) % 1
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.scrim
        opacity: scrim.value * Tokens.editScrimOpacity
        visible: opacity > 0.001
    }

    // The snapping grid, in the widgets' own coordinates (it moves with the push).
    Spring {
        id: gridFade
        spec: Motion.effectsDefault
        target: root.anyDragging ? 1 : 0
    }
    Canvas {
        id: grid
        x: push.value
        width: root.width
        height: root.height
        opacity: gridFade.value * Tokens.homeGridDotsOpacity
        visible: opacity > 0.001
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = Colors.on.surface;
            const g = Tokens.homeGrid, d = Tokens.homeGridDot;
            for (let x = 0; x <= width; x += g)
                for (let y = 0; y <= height; y += g)
                    ctx.fillRect(x - d / 2, y - d / 2, d, d);
        }
        Connections {
            target: Colors
            function onRolesChanged() { if (grid.visible) grid.requestPaint(); }
        }
    }

    // A thumbnail dragged out of the edit panel adds its widget where it's dropped,
    // centered on the pointer.
    DropArea {
        anchors.fill: parent
        enabled: root.editing
        keys: ["application/x-reef-widget"]
        onDropped: drop => {
            const kind = drop.getDataAsString("application/x-reef-widget");
            if (!Home.kinds.includes(kind))
                return;
            const size = Home.sizeOf(kind);
            Home.add(root.screenName, kind, drop.x - push.value - size.width / 2, drop.y - size.height / 2);
            drop.accept(Qt.CopyAction);
        }
    }

    Item {
        id: widgets
        x: push.value
        width: root.width
        height: root.height
        visible: Config.monitor(root.screenName).showWidgets

        Repeater {
            model: ScriptModel {
                values: root.layout.map(w => w.id)
            }
            HomeWidget {
                required property string modelData
                widgetId: modelData
                entry: root.layout.find(w => w.id === modelData) ?? null
                screenName: root.screenName
                editing: root.editing
                wigglePhase: root.phase
                wiggleAmount: wiggle.value
                boundsWidth: root.width
                boundsHeight: root.height
                onDraggingChanged: root._dragging += dragging ? 1 : -1
            }
        }
    }
}
