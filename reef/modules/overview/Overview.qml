import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.theme
import qs.services
import qs.components
import qs.modules

// Workspace overview (SURFACES.md → Workspaces overview; screens/Workspaces).
// Like GNOME's: the screen collapses (spatial-slow) into a large radius-xl card with a
// primary ring, the windows shrinking with it into their workspace, and only the
// background (the wallpaper, or the surface color without one) is left around it.
// The neighbouring workspaces peek in at the left and right edges, space-12 away.
// Below the card: the workspace number and its window count. The background is the
// blurred, dimmed wallpaper; the bar stays in front, over the same backdrop.
// Closing grows the card back to the screen; going to another workspace switches it under
// the card and keeps the card over the screen until Hyprland's slide is done.
//
// Scroll, swipe or Left/Right to move between workspaces; Enter or a click on a card
// goes there (growing from where it is), a click on a window focuses it; Escape, Super+Tab or a click on the
// background closes.
PanelWindow {
    id: root

    required property ShellScreen modelData
    property var barWindow: null
    screen: modelData

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    // Beside the bar (out of its reserved zone): the bar stays in front, and draws the same
    // blurred background in its strip while the overview is open (Bar.qml).
    exclusionMode: ExclusionMode.Normal
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "reef-overview"

    readonly property bool open: PanelState.panel === "overview" && PanelState.screenName === modelData.name
    // The surface stays mapped: mapping and unmapping a layer plays the compositor's own
    // layer animation (a slide or fade on top of ours). Closed, it draws nothing and
    // takes no input.
    visible: true
    mask: Region { item: inputArea }
    Item {
        id: inputArea
        width: root.open ? root.width : 0
        height: root.open ? root.height : 0
    }

    // Drawn until the card has grown back to fill the screen; gone the moment it does,
    // so the spring's overshoot past the screen is never seen.
    readonly property bool shown: open || zoom.value > 0.02 || switching
    // Going to another workspace: the card stays over the screen while Hyprland slides.
    property bool switching: false
    Timer {
        id: switchHold
        interval: Tokens.focusHandoffDelay + Workspaces.switchDuration + Motion.contentFadeDelay
        onTriggered: root.switching = false
    }

    // The collapse starts once the surface has its size and the current workspace's
    // windows have their first pictures (or after overview-capture-wait): until then
    // nothing is drawn and the real screen shows, so the first frame is the screen itself.
    property bool started: false
    property int _waited: 0
    Timer {
        id: startPoll
        interval: 16
        repeat: true
        onTriggered: {
            root._waited += interval;
            const sized = root.width > 0 && root.height > 0;
            if (sized && (root.currentReady() || root._waited >= Tokens.overviewCaptureWait)) {
                strip.jump();
                root.started = true;
                stop();
            }
        }
    }
    function currentReady() {
        const card = cards.itemAt(selected);
        return !!card && card.ready();
    }

    readonly property string wallpaper: Config.options.look.wallpaper

    readonly property var ids: Workspaces.ids(Config.options.bar.workspaceCount)
    // Shared with the Navigator cay's workspaces (PanelState.overviewWorkspace).
    readonly property int selected: Math.max(0, ids.indexOf(PanelState.overviewWorkspace))
    function select(index) {
        PanelState.overviewWorkspace = ids[Math.max(0, Math.min(ids.length - 1, index))];
    }

    readonly property real cardWidth: modelData.width * Tokens.overviewScale
    readonly property real cardHeight: modelData.height * Tokens.overviewScale
    readonly property real step: cardWidth + Tokens.space12
    readonly property real blockHeight: cardHeight + Tokens.space4 + labels.implicitHeight
    readonly property real cardTop: (height - blockHeight) / 2

    onOpenChanged: {
        if (open) {
            focusX = Qt.binding(() => root.cardX);
            stripX.target = Qt.binding(() => root.width / 2 - root.cardWidth / 2 - root.selected * root.step);
            started = false;
            _waited = 0;
            startPoll.restart();
            Workspaces.refresh();
            PanelState.overviewWorkspace = Workspaces.activeOn(modelData.name);
            strip.jump();
            focusFirst.restart();
        } else {
            grab.armed = false;
        }
    }

    Connections {
        target: PanelState
        function onOverviewGoRequested(id) {
            const i = root.ids.indexOf(id);
            if (root.open && i >= 0)
                root.goTo(i);
        }
    }

    function move(by) {
        select(selected + by);
    }

    // Where the growing card's corner sits in the strip (see the stage's Translate).
    property real focusX: cardX

    function goTo(index) {
        const id = ids[index];
        // Freeze the strip where it is and grow the picked card from its own place.
        const settledX = stripX.value + index * step;
        stripX.target = stripX.value;
        stripX.velocity = 0;
        focusX = settledX;
        if (id !== undefined && id !== Workspaces.activeOn(modelData.name)) {
            switching = true;
            switchHold.restart();
        }
        PanelState.closeAll();
        if (id !== undefined)
            Workspaces.afterHandoff(() => Workspaces.goTo(id));
    }

    // The bar's strip (its exclusive zone): part of the blurred background.
    readonly property var monitorSettings: Config.monitor(modelData.name)
    readonly property bool hasBar: monitorSettings.showBar
    readonly property bool barLeft: monitorSettings.barPosition === "left"
    readonly property real barZone: hasBar ? Tokens.cayHeight + Tokens.space2 : 0
    // Where this surface starts on the screen (it's beside a left bar).
    readonly property real originX: barLeft ? barZone : 0

    // ── motion ──────────────────────────────────────────────────
    Spring {
        id: zoom
        spec: Motion.spatialSlow
        target: root.open && root.started ? 1 : 0
    }
    Spring {
        id: fade
        spec: Motion.effectsSlow
        target: root.open && root.started ? 1 : 0
    }
    // The zoom as drawn: never past the screen.
    readonly property real z: Math.max(0, zoom.value)

    // The card's place, and how big it is at zoom z: at 0 it covers the screen exactly
    // (the windows inside sit right over the real ones), at 1 it's in place.
    readonly property real cardX: (width - cardWidth) / 2
    readonly property real zoomScale: 1 / Tokens.overviewScale + (1 - 1 / Tokens.overviewScale) * z

    // ── keyboard and dismissal ──────────────────────────────────
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    Timer {
        id: focusFirst
        interval: 1
        onTriggered: {
            strip.jump();
            keys.forceActiveFocus();
            armGrab.restart();
        }
    }
    Timer {
        id: armGrab
        interval: 150
        onTriggered: grab.armed = root.open
    }
    // The surface gets its size after it's shown; keep the current card centered.
    onWidthChanged: strip.jump()
    HyprlandFocusGrab {
        id: grab
        property bool armed: false
        windows: root.barWindow ? [root, root.barWindow] : [root]
        active: root.open && armed
        onCleared: if (root.open) PanelState.closeAll()
    }
    Item {
        id: keys
        focus: true
        Keys.onLeftPressed: root.move(-1)
        Keys.onRightPressed: root.move(1)
        Keys.onTabPressed: root.move(1)
        Keys.onBacktabPressed: root.move(-1)
        Keys.onReturnPressed: root.goTo(root.selected)
        Keys.onEnterPressed: root.goTo(root.selected)
        Keys.onEscapePressed: PanelState.closeAll()
    }

    // ── background ──────────────────────────────────────────────
    // The wallpaper (or the surface color), blurred, laid out on the whole screen so it
    // lines up with the same backdrop the bar draws in its strip. Opaque from the first
    // frame: the windows are in the card, not behind it.
    Item {
        id: backdrop
        x: -root.originX
        width: root.modelData.width
        height: root.modelData.height
        visible: false

        Rectangle {
            anchors.fill: parent
            color: Colors.surface
        }
        Image {
            anchors.fill: parent
            visible: root.wallpaper !== ""
            source: root.wallpaper !== "" ? "file://" + root.wallpaper : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: root.modelData.width
        }
    }
    MultiEffect {
        x: backdrop.x
        width: backdrop.width
        height: backdrop.height
        source: backdrop
        visible: root.started && root.shown
        blurEnabled: true
        blur: 1
        blurMax: Tokens.backdropBlur
        autoPaddingEnabled: false
    }
    // Dims the background as the card settles, so the card stands out.
    Rectangle {
        anchors.fill: parent
        color: Colors.scrim
        opacity: fade.value
        visible: root.shown
    }
    MouseArea {
        anchors.fill: parent
        enabled: root.open
        onClicked: PanelState.closeAll()
        onWheel: event => {
            const d = event.angleDelta.y || -event.angleDelta.x;
            if (Math.abs(d) >= 1)
                root.move(d < 0 ? 1 : -1);
        }
    }

    // ── cards ───────────────────────────────────────────────────
    // Collapses from the full screen into place: scaled about the top-left corner,
    // then moved so the current card's corner goes from the screen's to its own.
    Item {
        id: stage
        anchors.fill: parent
        visible: root.started && root.shown
        transform: [
            Scale {
                xScale: root.zoomScale
                yScale: root.zoomScale
            },
            // The card that grows into the screen keeps its corner at focusX while
            // settled: the centered card, or (going somewhere) the one picked, wherever
            // it is in the strip, so nothing slides as it grows.
            Translate {
                x: root.focusX * root.z - root.focusX * root.zoomScale - root.originX * (1 - root.z)
                y: root.cardTop * root.z - root.cardTop * root.zoomScale
            }
        ]

        Item {
            id: strip
            y: root.cardTop
            x: stripX.value
            height: root.cardHeight

            // Put the current card in the middle without sliding (on open). Sets the
            // value, not the target, so the target keeps following the selection.
            function jump() {
                stripX.value = stripX.target;
                stripX.velocity = 0;
            }

            Spring {
                id: stripX
                spec: Motion.spatialDefault
                target: root.width / 2 - root.cardWidth / 2 - root.selected * root.step
            }

            Repeater {
                id: cards
                // Built only while the overview shows (each window is a live capture).
                model: root.shown ? root.ids : []

                Rectangle {
                    id: card
                    required property int modelData
                    required property int index
                    readonly property bool current: index === root.selected
                    readonly property var windows: Workspaces.windowsOn(modelData)
                    readonly property real factor: root.cardWidth / root.modelData.width

                    // Every window here has its first picture.
                    function ready() {
                        for (let i = 0; i < thumbs.count; i++)
                            if (!thumbs.itemAt(i)?.ready)
                                return false;
                        return true;
                    }

                    x: index * root.step
                    width: root.cardWidth
                    height: root.cardHeight
                    radius: Tokens.radiusXl
                    color: Colors.surfaceContainerLowest
                    clip: true

                    // The wallpaper, as on the screen.
                    Image {
                        anchors.fill: parent
                        visible: root.wallpaper !== ""
                        source: root.wallpaper !== "" ? "file://" + root.wallpaper : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: root.cardWidth
                    }

                    Accessible.role: Accessible.Button
                    Accessible.name: `Workspace ${modelData}, ${windows.length === 1 ? "1 window" : windows.length + " windows"}`

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        // Straight there, growing from where it is.
                        onClicked: root.goTo(card.index)
                    }

                    // Windows where they sit on the screen, scaled down.
                    Repeater {
                        id: thumbs
                        model: card.windows

                        WindowThumb {
                            id: thumb
                            required property var modelData
                            readonly property var ipc: modelData.lastIpcObject
                            toplevel: modelData
                            live: card.current && root.open
                            visible: !!ipc?.at
                            x: ((ipc?.at?.[0] ?? 0) - root.modelData.x) * card.factor
                            y: ((ipc?.at?.[1] ?? 0) - root.modelData.y) * card.factor
                            width: (ipc?.size?.[0] ?? 0) * card.factor
                            height: (ipc?.size?.[1] ?? 0) * card.factor

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const t = thumb.modelData;
                                    PanelState.closeAll();
                                    Workspaces.afterHandoff(() => Workspaces.focusWindow(t));
                                }
                            }
                        }
                    }

                    // The ring around the current workspace.
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.width: Tokens.overviewRing
                        border.color: Colors.primary
                        opacity: ringFade.value * root.z
                        Spring {
                            id: ringFade
                            spec: Motion.effectsDefault
                            target: card.current ? 1 : 0
                        }
                    }
                }
            }
        }

        // Number and window count of the current workspace.
        Column {
            id: labels
            opacity: fade.value
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.cardTop + root.cardHeight + Tokens.space4
            spacing: Tokens.spaceHalf

            readonly property int count: Workspaces.windowCount(root.ids[root.selected] ?? 0)

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                style: "titleMdEmphasized"
                text: root.ids[root.selected] ?? ""
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                style: "bodySm"
                color: Colors.on.surfaceVariant
                text: labels.count === 0 ? "Empty" : labels.count === 1 ? "1 window" : `${labels.count} windows`
            }
        }
    }
}
