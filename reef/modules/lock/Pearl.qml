import QtQuick
import QtQuick.Shapes
import qs.theme
import qs.services
import qs.components
import qs.modules.island

// The Pearl (SURFACES.md → The Pearl; parts/Pearl-States, parts/Pearl-Lock): the round
// form of the Island, on the lock screen and behind the power actions. Its shape, color
// and face come from Settings → Lock screen (lock.pearl).
//
//   Pearl { width: Tokens.pearlLockSize; height: width }
//
// With `activity` on it shows the Island's main activity instead of its face: media is a
// small player (art, title, artist, previous / play / next) inside a progress ring, a timer
// is its readout inside a tertiary ring, anything else its icon, readout, title and first
// action. Paused media still shows, so it can be resumed. The time stays on top.
// With no activity: the face (digital clock and date, an analog clock whose face is the
// Pearl, or system stats in mono).
//
// It's alive: hop() jumps it up and lands with a squash (on the minute and when the
// activity changes, unless lock.pearl.hop is off), wobble() rocks it (wrong password),
// pulse() swells it a little (typing). `travel` is the speed (px/s) of any outside motion,
// so a drop stretches it too. All of it rides spatial-bouncy and stops with Reduce motion.
//
// `resting` turns it into the Island's pill (the lock entry morphs between the two);
// `contentOpacity` fades what's inside. Content is laid out for pearl-lock-size and scales
// with the Pearl.
Item {
    id: root

    readonly property var options: Config.options.lock.pearl
    property bool activity: true
    property bool resting: false
    property real contentOpacity: 1
    property var spec: Motion.spatialSlow
    property real travel: 0

    // ── colors for the chosen tone ──
    readonly property string tone: options.color
    readonly property bool black: tone !== "primary" && tone !== "secondary" && tone !== "tertiary"
    readonly property color fill: tone === "primary" ? Colors.primaryContainer
        : tone === "secondary" ? Colors.secondaryContainer
        : tone === "tertiary" ? Colors.tertiaryContainer : Colors.island
    readonly property color ink: tone === "primary" ? Colors.on.primaryContainer
        : tone === "secondary" ? Colors.on.secondaryContainer
        : tone === "tertiary" ? Colors.on.tertiaryContainer : Colors.on.island
    readonly property color softInk: black ? Colors.on.islandVariant : ink
    readonly property color accent: tone === "primary" ? Colors.primary
        : tone === "secondary" ? Colors.secondary
        : tone === "tertiary" ? Colors.tertiary : Colors.islandAccent
    readonly property color onAccent: tone === "primary" ? Colors.on.primary
        : tone === "secondary" ? Colors.on.secondary
        : tone === "tertiary" ? Colors.on.tertiary : Colors.on.islandAccent

    // ── what it shows ──
    readonly property string key: !activity ? ""
        : IslandState.activity !== "" ? IslandState.activity
        : IslandState.settings.media && Media.active ? "media" : ""
    readonly property var act: key !== "" ? IslandState.byKey(key) : null
    readonly property string mode: key === "media" ? "media" : key === "timer" ? "timer"
        : key !== "" ? "activity" : options.face
    readonly property real ring: mode === "media" ? Media.progress : mode === "timer" ? Countdown.progress : -1

    Accessible.role: Accessible.Grouping
    Accessible.name: act ? "Pearl, " + act.spoken : "Pearl, " + Time.time

    // ── life ──
    function hop() {
        if (options.hop && Performance.idleMotion && visible)
            hopY.kick(-Tokens.pearlHop);
    }
    function wobble() {
        rock.kick(Tokens.pearlWobble);
    }
    function pulse() {
        swell.kick(Tokens.pearlPulse);
    }

    Spring {
        id: hopY
        spec: Motion.spatialBouncy
        target: 0
    }
    Spring {
        id: rock
        spec: Motion.spatialBouncy
        target: 0
    }
    Spring {
        id: swell
        spec: Motion.spatialBouncy
        target: 0
    }
    // Stretched along the motion, squashed as it turns back (volume kept).
    readonly property real stretch: Tokens.pearlSquash
        * Math.tanh((hopY.velocity + travel) / (Math.sqrt(Motion.spatialBouncy.stiffness) * Tokens.pearlHop))

    transform: [
        Translate {
            y: hopY.value
        },
        Scale {
            origin.x: root.width / 2
            origin.y: root.height / 2
            xScale: (1 + swell.value) / (1 + root.stretch)
            yScale: (1 + swell.value) * (1 + root.stretch)
        },
        Rotation {
            origin.x: root.width / 2
            origin.y: root.height / 2
            angle: rock.value
        }
    ]

    onKeyChanged: hop()
    Connections {
        target: Time
        function onTimeChanged() {
            root.hop();
        }
    }

    // ── the Pearl ──
    ShapeMorph {
        anchors.fill: parent
        shape: root.resting ? "pill" : root.options.shape
        spec: root.spec
        color: root.fill
    }

    // Content at pearl-lock-size, scaled to fit.
    Item {
        id: content
        anchors.centerIn: parent
        width: Tokens.pearlLockSize
        height: Tokens.pearlLockSize
        scale: Math.min(root.width, root.height) / Tokens.pearlLockSize
        opacity: root.contentOpacity
        visible: opacity > 0.01

        // Progress ring (media, timer), just outside the shape.
        Shape {
            id: ringShape
            anchors.centerIn: parent
            readonly property real r: Tokens.pearlLockSize / 2 + Tokens.pearlRingGap + Tokens.pearlRingWidth / 2
            width: r * 2 + Tokens.pearlRingWidth
            height: width
            visible: root.ring >= 0
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.alpha(Colors.island, Tokens.pearlRingTrackOpacity)
                strokeWidth: Tokens.pearlRingWidth
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: ringShape.width / 2
                    centerY: ringShape.height / 2
                    radiusX: ringShape.r
                    radiusY: ringShape.r
                    startAngle: 0
                    sweepAngle: 360
                }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: root.mode === "timer" ? Colors.tertiaryContainer : root.accent
                strokeWidth: Tokens.pearlRingWidth
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: ringShape.width / 2
                    centerY: ringShape.height / 2
                    radiusX: ringShape.r
                    radiusY: ringShape.r
                    startAngle: -90
                    sweepAngle: 360 * Math.max(0.001, root.ring)
                }
            }
        }

        // ── face: digital ──
        Column {
            anchors.centerIn: parent
            visible: root.mode === "digital"
            spacing: Tokens.space1

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                style: "pearlClock"
                rond: 100
                text: Time.time
                color: root.ink
                font.features: ({ tnum: 1 })
                Accessible.name: "Time " + Time.time
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.options.date
                style: "pearlDate"
                text: Qt.formatDate(Time.now, "dddd, d MMMM")
                color: root.softInk
            }
        }

        // ── face: analog (the Pearl is its face) ──
        AnalogClock {
            anchors.fill: parent
            visible: root.mode === "analog"
            size: Tokens.pearlLockSize
            shape: root.options.shape
            face: false
            tone: root.black ? "island" : root.tone
            numbers: Config.options.home.clock.numbers
            ticks: Config.options.home.clock.ticks
            seconds: Config.options.home.clock.seconds
        }

        // ── face: system stats ──
        Grid {
            id: stats
            anchors.centerIn: parent
            visible: root.mode === "stats"
            columns: 2
            columnSpacing: Tokens.space3
            rowSpacing: Tokens.space1

            // SystemStats reads only while someone holds it.
            readonly property bool reading: visible
            property bool _held: false
            function _sync() {
                if (reading === _held)
                    return;
                _held = reading;
                reading ? SystemStats.hold() : SystemStats.release();
            }
            onReadingChanged: _sync()
            Component.onCompleted: _sync()
            Component.onDestruction: if (_held) SystemStats.release()

            Repeater {
                model: [
                    { label: "CPU", value: SystemStats.cpuText, shown: true },
                    { label: "RAM", value: SystemStats.memText, shown: true },
                    { label: "GPU", value: SystemStats.gpuText, shown: SystemStats.hasGpu }
                ].filter(r => r.shown).reduce((cells, r) => cells.concat([{ text: r.label, soft: true }, { text: r.value, soft: false }]), [])
                StyledText {
                    required property var modelData
                    style: "monoLg"
                    color: modelData.soft ? root.softInk : root.ink
                    text: modelData.text
                }
            }
        }

        // ── activity ──
        Column {
            anchors.centerIn: parent
            visible: root.mode === "media" || root.mode === "timer" || root.mode === "activity"
            spacing: Tokens.space1

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                style: "pearlDate"
                text: Time.time
                color: root.softInk
                font.features: ({ tnum: 1 })
            }

            // Media: art, title, artist, controls.
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.mode === "media"
                spacing: Tokens.spaceHalf

                ShapeImage {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Tokens.pearlArt
                    height: Tokens.pearlArt
                    shape: "cookie12"
                    // Only while shown, as the Island does: loading art while a lock
                    // surface is being built has crashed Qt's image loader.
                    source: content.visible && root.mode === "media" ? Media.artUrl : ""
                    color: root.black ? Colors.islandContainerHigh : Qt.alpha(root.ink, Tokens.pearlRingTrackOpacity)
                    icon: "music_note"
                    iconSize: Tokens.iconMd
                    iconColor: root.accent
                }
                Item {
                    width: 1
                    height: Tokens.space1
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(implicitWidth, Tokens.pearlTextWidth)
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    style: "islandTitle"
                    color: root.ink
                    text: Media.title
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: text !== ""
                    width: Math.min(implicitWidth, Tokens.pearlTextWidth)
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    style: "bodySm"
                    color: root.softInk
                    text: Media.artist
                }
                Item {
                    width: 1
                    height: Tokens.space1
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Tokens.space1

                    PearlButton {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "skip_previous"
                        label: "Previous track"
                        enabledState: Media.canGoPrevious
                        onClicked: Media.previous()
                    }
                    PearlButton {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Tokens.pearlPlay
                        height: Tokens.pearlPlay
                        accent: true
                        icon: Media.playing ? "pause" : "play_arrow"
                        label: Media.playing ? "Pause" : "Play"
                        onClicked: Media.togglePlaying()
                    }
                    PearlButton {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "skip_next"
                        label: "Next track"
                        enabledState: Media.canGoNext
                        onClicked: Media.next()
                    }
                }
            }

            // Timer and the rest: icon, readout, title, first action.
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.mode === "timer" || root.mode === "activity"
                spacing: Tokens.spaceHalf

                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: !root.act ? "" : root.act.leading === "dot" ? "radio_button_checked" : root.act.icon
                    size: Tokens.iconMd
                    filled: true
                    color: !root.act || !root.black ? root.ink
                        : root.act.leading === "dot" ? root.act.dotColor : root.act.iconColor
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: text !== ""
                    style: "numeralLg"
                    font.features: ({ tnum: 1 })
                    color: root.black && root.act ? root.act.textColor : root.ink
                    text: root.act ? root.act.value : ""
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: text !== ""
                    width: Math.min(implicitWidth, Tokens.pearlTextWidth)
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    style: "islandTitle"
                    color: root.ink
                    text: root.act ? root.act.title : ""
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: text !== "" && !(root.act && root.act.value)
                    width: Math.min(implicitWidth, Tokens.pearlTextWidth)
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    style: "bodySm"
                    color: root.softInk
                    text: root.act ? root.act.subtitle : ""
                }
                Item {
                    width: 1
                    height: Tokens.space1
                    visible: firstAction.visible
                }
                PearlButton {
                    id: firstAction
                    readonly property var a: root.act?.actions?.[0] ?? null
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: !!a
                    accent: !!a && a.tone !== "neutral"
                    icon: a ? a.icon : ""
                    label: a ? a.label : ""
                    onClicked: a.run()
                }
            }
        }
    }

    // A round button in the Pearl's colors: flat ink, or filled with its accent.
    component PearlButton: IslandButton {
        property bool accent: false
        width: Tokens.pearlButton
        height: Tokens.pearlButton
        iconSize: accent ? Tokens.iconMd : Tokens.iconSm
        filled: true
        color: accent ? root.accent : Qt.alpha(root.fill, 0)
        contentColor: accent ? root.onAccent : root.ink
    }
}
