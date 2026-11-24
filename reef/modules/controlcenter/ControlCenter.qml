import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.theme
import qs.services
import qs.components
import qs.modules
import qs.modules.menus

// Control and notification center (SURFACES.md; screens/ControlCenter).
// A Tide panel: full height on the right edge, no shadow, surface-container-low, with
// concave fillets where its inner edge meets the top and bottom of the screen. It slides
// in from its edge with spatial-default. Three cards: notifications (fills the free
// space), quick toggles, sliders. Escape, the Status cay or a click outside closes it.
// Quick menus opened while it's open (a tile's menu, the Island's output button, a
// keybind) float inside it as an elevated card over a scrim; Escape or a click on the
// scrim closes just the menu. The bar moves aside for it (Bar.qml).
PanelWindow {
    id: root

    required property ShellScreen modelData
    // Part of the focus grab, so clicking the (pushed-aside) Status cay toggles the panel.
    property var barWindow: null
    screen: modelData

    anchors {
        top: true
        bottom: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "reef-controlcenter"
    implicitWidth: Tokens.panelWidth + Tokens.radiusXl

    readonly property bool open: PanelState.panel === "controlCenter" && PanelState.screenName === modelData.name
    readonly property string menu: open ? PanelState.menu : ""
    readonly property bool menuOpen: menu !== ""
    // The last menu shown, so it can animate out.
    property string shownMenu: ""
    onMenuChanged: if (menu !== "") shownMenu = menu
    onMenuOpenChanged: {
        if (menuOpen)
            menuFocus.restart();
        else if (open)
            keys.forceActiveFocus();
    }
    Timer {
        id: menuFocus
        interval: 1
        onTriggered: menuCard.nextItemInFocusChain(true)?.forceActiveFocus()
    }

    Spring {
        id: slide
        spec: Motion.spatialDefault
        target: root.open ? 0 : root.width
    }
    visible: open || slide.value < root.width - 0.5

    mask: Region { item: panel }

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
    Item {
        id: keys
        focus: true
        Keys.onTabPressed: keys.nextItemInFocusChain(true)?.forceActiveFocus()
    }
    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: root.menuOpen ? PanelState.closeMenu() : PanelState.closeAll()
    }
    HyprlandFocusGrab {
        id: grab
        property bool armed: false
        windows: root.barWindow ? [root, root.barWindow] : [root]
        active: root.open && armed
        onCleared: if (PanelState.panel === "controlCenter") PanelState.closeAll()
    }

    // Relative times tick while open.
    property real now: Date.now()
    Timer {
        running: root.open
        interval: 30000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = Date.now()
    }

    // ── panel ───────────────────────────────────────────────────
    Item {
        id: panel
        x: slide.value
        width: root.width
        height: root.height

        EdgeFillet {
            anchors.top: parent.top
            anchors.right: body.left
            corner: "topRight"
            color: Colors.surfaceContainerLow
        }
        EdgeFillet {
            anchors.bottom: parent.bottom
            anchors.right: body.left
            corner: "bottomRight"
            color: Colors.surfaceContainerLow
        }

        Rectangle {
            id: body
            anchors.right: parent.right
            width: Tokens.panelWidth
            height: parent.height
            color: Colors.surfaceContainerLow

            Accessible.role: Accessible.Pane
            Accessible.name: "Control center"

            Column {
                id: cards
                anchors.fill: parent
                anchors.topMargin: Tokens.space3
                anchors.bottomMargin: Tokens.space3
                anchors.rightMargin: Tokens.space3
                anchors.leftMargin: Tokens.space3
                spacing: Tokens.space2_5

                // ── notifications (grows to fill) ──
                Card {
                    id: notificationsCard
                    width: parent.width
                    height: parent.height - togglesCard.height - slidersCard.height - parent.spacing * 2
                    title: Notifications.count === 0 ? "Notifications"
                        : Notifications.count === 1 ? "1 notification" : `${Notifications.count} notifications`
                    header: [
                        Chip {
                            visible: Notifications.count > 0
                            text: "Clear all"
                            onClicked: Notifications.clearAll()
                        }
                    ]

                    ListView {
                        id: list
                        width: parent.width
                        height: notificationsCard.height - Tokens.space3_5 * 2 - Tokens.chipHeight - Tokens.space2_5
                        clip: true
                        spacing: Tokens.space2
                        boundsBehavior: Flickable.StopAtBounds
                        model: ScriptModel {
                            values: Notifications.list
                        }
                        delegate: NotificationCard {
                            required property var modelData
                            width: list.width
                            notification: modelData
                            now: root.now
                        }

                        // New cards slide in; removed ones fade.
                        add: Transition {
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Motion.duration(Motion.effectsDefault) }
                        }
                        displaced: Transition {
                            NumberAnimation { property: "y"; duration: Motion.duration(Motion.spatialDefault); easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.curve(Motion.spatialDefault) }
                        }

                        StyledText {
                            anchors.centerIn: parent
                            visible: Notifications.count === 0
                            style: "bodyMd"
                            color: Colors.on.surfaceVariant
                            text: Notifications.dnd ? "Do not disturb is on" : "No notifications"
                        }
                    }
                }

                // ── quick toggles ──
                Card {
                    id: togglesCard
                    width: parent.width
                    title: "Quick toggles"

                    // Four columns, one button group per row; Wi-Fi, Bluetooth, Keep awake
                    // and Focus span two. A pressed tile widens and its row makes room.
                    Column {
                        width: parent.width
                        spacing: Tokens.space2

                        ButtonGroup {
                            width: parent.width

                            Tile {
                                wide: true
                                icon: Network.wired ? "lan" : Network.wifiEnabled ? "wifi" : "wifi_off"
                                label: Network.wired ? "Ethernet" : "Wi-Fi"
                                sublabel: Network.shortLabel
                                checked: Network.wired ? true : Network.wifiEnabled
                                hasMenu: true
                                onToggled: Network.wired ? PanelState.open("wifi") : Network.setWifiEnabled(!Network.wifiEnabled)
                                onMenuRequested: PanelState.open("wifi")
                            }
                            Tile {
                                wide: true
                                icon: "bluetooth"
                                label: "Bluetooth"
                                sublabel: BluetoothState.label
                                checked: BluetoothState.enabled
                                enabledState: BluetoothState.available
                                hasMenu: true
                                onToggled: BluetoothState.toggle()
                                onMenuRequested: PanelState.open("bluetooth")
                            }
                        }
                        ButtonGroup {
                            width: parent.width

                            Tile {
                                icon: "do_not_disturb_on"
                                label: "Do not disturb"
                                checked: Notifications.dnd
                                onToggled: Notifications.setDnd(!Notifications.dnd)
                            }
                            Tile {
                                icon: "nightlight"
                                label: "Night light"
                                checked: NightLight.enabled
                                onToggled: NightLight.toggle()
                            }
                            Tile {
                                icon: "screenshot_region"
                                label: "Screenshot"
                                onToggled: {
                                    PanelState.closeAll();
                                    Screenshot.region();
                                }
                            }
                            Tile {
                                icon: "mic_off"
                                label: "Mute microphone"
                                checked: Audio.micMuted
                                onToggled: Audio.toggleMicMute()
                            }
                        }
                        ButtonGroup {
                            width: parent.width

                            Tile {
                                wide: true
                                icon: "coffee"
                                label: "Keep awake"
                                sublabel: KeepAwake.active ? (KeepAwake.until > 0 ? `${KeepAwake.text} left` : "On") : "Off"
                                checked: KeepAwake.active
                                onToggled: KeepAwake.toggle(0)
                            }
                            Tile {
                                wide: true
                                icon: "self_improvement"
                                label: "Focus"
                                sublabel: Focus.active ? `${Focus.phase === "focus" ? "Focus" : "Break"} · ${Focus.text}` : `${Config.options.focus.focusMinutes} min`
                                checked: Focus.active
                                onToggled: Focus.active ? Focus.stop() : Focus.start(0)
                            }
                        }
                    }
                }

                // ── sliders ──
                Card {
                    id: slidersCard
                    width: parent.width

                    ExpressiveSlider {
                        width: parent.width
                        icon: Audio.icon
                        label: "Volume"
                        value: Audio.muted ? 0 : Audio.volume
                        onMoved: v => Audio.setVolume(v)
                    }
                    ExpressiveSlider {
                        width: parent.width
                        visible: Brightness.available
                        icon: "light_mode"
                        label: "Brightness"
                        value: Brightness.level
                        onMoved: v => Brightness.set(v)
                    }
                }
            }

            // ── floating quick menu ──
            Spring {
                id: menuGrow
                spec: Motion.spatialDefault
                target: root.menuOpen ? 1 : 0
            }
            Spring {
                id: menuFade
                spec: Motion.effectsDefault
                target: root.menuOpen ? 1 : 0
            }

            Rectangle {
                id: scrim
                anchors.fill: parent
                color: Colors.scrim
                opacity: menuFade.value
                visible: opacity > 0.01
                MouseArea {
                    anchors.fill: parent
                    enabled: root.menuOpen
                    onClicked: PanelState.closeMenu()
                    onWheel: event => event.accepted = true
                }
            }

            RectangularShadow {
                anchors.fill: menuCard
                radius: menuCard.radius
                offset.x: Colors.shadowMenu.x
                offset.y: Colors.shadowMenu.y
                blur: Colors.shadowMenu.blur
                color: Colors.shadowMenu.color
                opacity: menuCard.opacity
                scale: menuCard.scale
                visible: menuCard.visible
            }

            Rectangle {
                id: menuCard
                anchors.centerIn: parent
                width: menuContent.width + Tokens.space4 * 2
                height: menuContent.height + Tokens.space4 * 2
                radius: Tokens.radiusXl
                color: Colors.surfaceContainerHigh
                opacity: menuFade.value
                scale: 0.85 + 0.15 * menuGrow.value
                visible: opacity > 0.01
                enabled: root.menuOpen

                Accessible.role: Accessible.Dialog
                Accessible.name: menuContent.title

                MenuContent {
                    id: menuContent
                    x: Tokens.space4
                    y: Tokens.space4
                    menu: root.shownMenu
                    live: root.menuOpen
                }
            }
        }
    }
}
