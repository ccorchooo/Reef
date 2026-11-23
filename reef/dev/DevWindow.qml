import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme
import qs.services
import qs.components

// M0 inspector: live color roles, type ramp, icons, shapes, springs, and the settings
// that drive them. Open with `qs -c reef ipc call reef dev` or debug.devWindow in config.json.
// A developer tool, not a Reef surface: its pixel widths are tool layout. Every color,
// radius, spacing, type style and motion still comes from the theme singletons.
FloatingWindow {
    id: win

    title: "Reef · foundation"
    implicitWidth: 1180
    implicitHeight: 900
    color: Colors.surface

    readonly property var look: Config.options.look
    readonly property var motion: Config.options.motion

    // Closing the window turns the setting off.
    onClosed: Config.options.debug.devWindow = false

    // Dev convenience: the wallpaper Caelestia is currently showing.
    FileView {
        id: caelestiaWall
        path: Quickshell.env("HOME") + "/.local/state/caelestia/wallpaper/path.txt"
        printErrors: false
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: page.implicitHeight + Tokens.space6 * 2
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Column {
            id: page
            x: Tokens.space6
            y: Tokens.space6
            width: flick.width - Tokens.space6 * 2
            spacing: Tokens.space3

            // ── Header ──────────────────────────────────────────────
            Row {
                spacing: Tokens.space4
                ShapeItem {
                    width: Tokens.space8
                    height: Tokens.space8
                    anchors.verticalCenter: parent.verticalCenter
                    radii: Shapes.sample("cookie6", width, height)
                    color: Colors.primary
                }
                Column {
                    StyledText {
                        style: "headlineSm"
                        text: "Reef foundation"
                    }
                    StyledText {
                        style: "bodySm"
                        color: Colors.on.surfaceVariant
                        text: (Colors.fromWallpaper ? "Scheme from " + (win.look.staticColor ? "static color " + win.look.staticColor : "wallpaper") : "Reference scheme (seed " + Tokens.seed + ")") + " · " + Colors.mode + " · " + win.look.colorfulness + (Scheme.busy ? " · generating…" : "") + (Scheme.lastError ? " · matugen: " + Scheme.lastError : "")
                    }
                }
            }

            // ── Look & motion settings ──────────────────────────────
            DevCard {
                width: page.width
                title: "Settings"

                Grid {
                    columns: 2
                    columnSpacing: Tokens.space6
                    rowSpacing: Tokens.space3
                    verticalItemAlignment: Grid.AlignVCenter

                    StyledText { style: "labelLg"; text: "Theme" }
                    Row {
                        spacing: Tokens.space2
                        Repeater {
                            model: ["auto", "light", "dark"]
                            DevButton {
                                required property string modelData
                                text: modelData[0].toUpperCase() + modelData.slice(1)
                                selected: win.look.theme === modelData
                                onClicked: win.look.theme = modelData
                            }
                        }
                    }

                    StyledText { style: "labelLg"; text: "Colorfulness" }
                    Row {
                        spacing: Tokens.space2
                        Repeater {
                            model: ["neutral", "tinted", "vivid"]
                            DevButton {
                                required property string modelData
                                text: modelData[0].toUpperCase() + modelData.slice(1)
                                selected: win.look.colorfulness === modelData
                                onClicked: win.look.colorfulness = modelData
                            }
                        }
                    }

                    StyledText { style: "labelLg"; text: "Scheme source" }
                    Row {
                        spacing: Tokens.space2
                        DevButton {
                            text: "Reference"
                            selected: !win.look.wallpaper && !win.look.staticColor
                            onClicked: { win.look.staticColor = ""; win.look.wallpaper = ""; }
                        }
                        DevButton {
                            text: "Caelestia wallpaper"
                            selected: !!win.look.wallpaper && !win.look.staticColor && win.look.wallpaper === caelestiaWall.text().trim()
                            onClicked: { win.look.staticColor = ""; caelestiaWall.reload(); win.look.wallpaper = caelestiaWall.text().trim(); }
                        }
                    }

                    StyledText { style: "labelLg"; text: "Wallpaper" }
                    DevField {
                        width: 560
                        label: "Wallpaper path"
                        placeholder: "/path/to/image.jpg, Enter to apply"
                        text: win.look.wallpaper
                        onAccepted: value => win.look.wallpaper = value.trim()
                    }

                    StyledText { style: "labelLg"; text: "Static color" }
                    DevField {
                        width: 240
                        label: "Static seed color"
                        placeholder: "#e8735a"
                        text: win.look.staticColor
                        onAccepted: value => win.look.staticColor = value.trim()
                    }

                    StyledText { style: "labelLg"; text: "Reduce motion" }
                    Row {
                        spacing: Tokens.space2
                        DevButton { text: "Off"; selected: !win.motion.reduceMotion; onClicked: win.motion.reduceMotion = false }
                        DevButton { text: "On"; selected: win.motion.reduceMotion; onClicked: win.motion.reduceMotion = true }
                    }

                    StyledText { style: "labelLg"; text: "Animation speed" }
                    Row {
                        spacing: Tokens.space2
                        Repeater {
                            model: [0.25, 0.5, 1, 1.5, 2]
                            DevButton {
                                required property real modelData
                                text: modelData + "×"
                                selected: win.motion.speed === modelData
                                onClicked: win.motion.speed = modelData
                            }
                        }
                    }

                    StyledText { style: "labelLg"; text: "Shape morphs" }
                    Row {
                        spacing: Tokens.space2
                        DevButton { text: "Morph"; selected: Config.options.performance.shapeMorphs; onClicked: Config.options.performance.shapeMorphs = true }
                        DevButton { text: "Crossfade"; selected: !Config.options.performance.shapeMorphs; onClicked: Config.options.performance.shapeMorphs = false }
                    }

                    StyledText { style: "labelLg"; text: "Text size" }
                    Row {
                        spacing: Tokens.space2
                        Repeater {
                            model: [0.9, 1, 1.15]
                            DevButton {
                                required property real modelData
                                text: modelData + "×"
                                selected: Config.options.scale.text === modelData
                                onClicked: Config.options.scale.text = modelData
                            }
                        }
                    }
                }
            }

            // ── Color roles ─────────────────────────────────────────
            DevCard {
                width: page.width
                title: "Color roles"

                Flow {
                    width: parent.width
                    spacing: Tokens.space3
                    Repeater {
                        model: Object.keys(Tokens.referenceSchemes.dark)
                        Column {
                            required property string modelData
                            width: 124
                            spacing: Tokens.space1
                            Rectangle {
                                width: parent.width
                                height: 56
                                radius: Tokens.radiusMd
                                color: Colors.role(parent.modelData)
                                border.width: 1
                                border.color: Colors.outlineVariant
                            }
                            StyledText {
                                width: parent.width
                                style: "labelMd"
                                elide: Text.ElideRight
                                text: parent.modelData
                            }
                            StyledText {
                                style: "monoSm"
                                color: Colors.on.surfaceVariant
                                text: Colors.role(parent.modelData).toString()
                            }
                        }
                    }
                }
            }

            // ── Type ────────────────────────────────────────────────
            DevCard {
                width: page.width
                title: "Type"

                Repeater {
                    model: Type.styles
                    Row {
                        required property string modelData
                        spacing: Tokens.space4
                        StyledText {
                            width: 200
                            anchors.verticalCenter: parent.verticalCenter
                            style: "monoSm"
                            color: Colors.on.surfaceVariant
                            text: parent.modelData + " " + Type.spec(parent.modelData).size + "/" + Type.spec(parent.modelData).lineHeight + " " + Type.spec(parent.modelData).weight
                        }
                        StyledText {
                            style: parent.modelData
                            text: Type.spec(parent.modelData).sample
                        }
                    }
                }

                // Variable axes: ROND and wdth on numerals, wght animated on hover.
                Row {
                    spacing: Tokens.space6
                    StyledText { style: "numeralLg"; rond: 0; text: "24°" }
                    StyledText { style: "numeralLg"; rond: 100; text: "24°" }
                    StyledText { style: "numeralLg"; wdth: 25; text: "09 41" }
                    StyledText {
                        style: "numeralLg"
                        text: "wght"
                        weight: wghtSpring.value
                        Spring { id: wghtSpring; spec: Motion.effectsFast; target: wghtHover.hovered ? 700 : 400 }
                        HoverHandler { id: wghtHover }
                    }
                }
            }

            // ── Icons ───────────────────────────────────────────────
            DevCard {
                width: page.width
                title: "Icons (click to toggle FILL)"

                Row {
                    spacing: Tokens.space4
                    Repeater {
                        model: ["wifi", "bluetooth", "notifications", "dark_mode", "volume_up", "battery_full", "search", "home", "content_paste", "mic"]
                        Rectangle {
                            id: iconTile
                            required property string modelData
                            property bool on: false
                            width: Tokens.cayHeight
                            height: Tokens.cayHeight
                            radius: height / 2
                            color: tileBg.value
                            border.width: activeFocus ? 2 : 0
                            border.color: Colors.primary
                            activeFocusOnTab: true
                            Accessible.role: Accessible.CheckBox
                            Accessible.name: modelData
                            Accessible.checked: on
                            Keys.onSpacePressed: on = !on
                            ColorSpring { id: tileBg; target: iconTile.on ? Colors.primaryContainer : Colors.surfaceContainerHigh }
                            Icon {
                                anchors.centerIn: parent
                                name: iconTile.modelData
                                filled: iconTile.on
                                color: iconTile.on ? Colors.on.primaryContainer : Colors.on.surfaceVariant
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: iconTile.on = !iconTile.on
                            }
                        }
                    }
                }
            }

            // ── Shapes ──────────────────────────────────────────────
            DevCard {
                width: page.width
                title: "Shapes"

                Flow {
                    width: parent.width
                    spacing: Tokens.space4
                    Repeater {
                        model: Shapes.names
                        Column {
                            required property string modelData
                            spacing: Tokens.space1
                            ShapeItem {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: modelData === "pill" || modelData === "squircle" ? 96 : 56
                                height: 56
                                radii: Shapes.sample(modelData, width, height)
                                color: Colors.primaryContainer
                            }
                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                style: "labelMd"
                                text: parent.modelData
                            }
                        }
                    }
                }

                // Morph playground: click shapes quickly to interrupt mid-morph.
                Row {
                    spacing: Tokens.space6

                    Item {
                        width: 400
                        height: 240

                        ShapeMorph {
                            id: morph
                            readonly property bool wide: shape === "pill" || shape === "squircle"
                            anchors.centerIn: parent
                            width: morphW.value
                            height: morphH.value
                            spec: morphSpec.spec
                            shape: "cookie9"
                            color: Colors.primary

                            Spring { id: morphW; spec: morph.spec; target: morph.wide ? 360 : 200 }
                            Spring { id: morphH; spec: morph.spec; target: morph.wide ? 120 : 200 }
                        }
                    }

                    Column {
                        spacing: Tokens.space3
                        anchors.verticalCenter: parent.verticalCenter

                        Flow {
                            width: 640
                            spacing: Tokens.space2
                            Repeater {
                                model: ["circle", "cookie4", "cookie9", "pill", "cookie6", "cookie12", "clover4", "sunny", "flower", "pentagon", "gem", "squircle"]
                                DevButton {
                                    required property string modelData
                                    text: modelData
                                    selected: morph.shape === modelData
                                    onClicked: { cycle.running = false; morph.shape = modelData; }
                                }
                            }
                        }
                        Row {
                            spacing: Tokens.space2
                            DevButton {
                                text: cycle.running ? "Stop cycle" : "Cycle circle → cookie-4 → cookie-9 → pill"
                                selected: cycle.running
                                onClicked: cycle.running = !cycle.running
                            }
                        }
                        Row {
                            id: morphSpec
                            property var spec: Motion.spatialDefault
                            spacing: Tokens.space2
                            Repeater {
                                model: ["spatialFast", "spatialDefault", "spatialSlow"]
                                DevButton {
                                    required property string modelData
                                    text: modelData
                                    selected: morphSpec.spec.name === modelData
                                    onClicked: morphSpec.spec = Motion[modelData]
                                }
                            }
                        }
                    }

                    Timer {
                        id: cycle
                        property int i: 0
                        readonly property var order: ["circle", "cookie4", "cookie9", "pill"]
                        interval: 1200 / Motion.speed
                        repeat: true
                        onTriggered: { i = (i + 1) % order.length; morph.shape = order[i]; }
                    }
                }
            }

            // ── Springs ─────────────────────────────────────────────
            DevCard {
                width: page.width
                title: "Springs (click Move repeatedly to interrupt)"

                DevButton {
                    id: moveBtn
                    property bool moved: false
                    text: "Move"
                    onClicked: moved = !moved
                }

                Repeater {
                    model: ["spatialFast", "spatialDefault", "spatialSlow", "effectsFast", "effectsDefault", "effectsSlow"]
                    Row {
                        id: springRow
                        required property string modelData
                        readonly property var spec: Motion[modelData]
                        spacing: Tokens.space4
                        StyledText {
                            width: 200
                            anchors.verticalCenter: parent.verticalCenter
                            style: "monoSm"
                            color: Colors.on.surfaceVariant
                            text: springRow.modelData + "  k" + springRow.spec.stiffness + " ζ" + springRow.spec.damping
                        }
                        Rectangle {
                            width: page.width - 260
                            height: Tokens.space6
                            radius: height / 2
                            color: Colors.surfaceContainerHighest
                            Rectangle {
                                width: parent.height
                                height: parent.height
                                radius: height / 2
                                color: springRow.spec.effects ? dotColor.value : Colors.primary
                                x: springRow.spec.effects ? (parent.width - width) / 2 : pos.value * (parent.width - width)
                                opacity: springRow.spec.effects ? 0.3 + 0.7 * pos.value : 1
                                Spring { id: pos; spec: springRow.spec; target: moveBtn.moved ? 1 : 0 }
                                ColorSpring { id: dotColor; spec: springRow.spec; target: moveBtn.moved ? Colors.tertiary : Colors.primary }
                            }
                        }
                    }
                }
            }
        }
    }
}
