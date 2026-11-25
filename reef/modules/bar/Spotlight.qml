import QtQuick
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.components
import qs.modules

// Spotlight cay (SURFACES.md → Bar): the special widget. It shows the first live thing,
// in this order (each can be turned off in Settings → Bar & Island → Spotlight):
//   media (artwork, title, artist, play/pause) · a timer (remaining, pause/resume) ·
//   the stopwatch (elapsed, pause/resume) · today's next calendar event (title, when).
// With none of them, it shows its default widget: the weather, system load, or nothing
// (then it folds away). Off entirely with Show Spotlight cay.
// On the left (`vertical`) it's just the tile over its button.
Cay {
    id: root

    readonly property var settings: Config.options.bar.spotlight
    readonly property date today: Time.now
    readonly property var event: {
        const e = Calendar.next;
        if (!e || e.allDay)
            return null;
        const s = e.start;
        return s.getFullYear() === today.getFullYear() && s.getMonth() === today.getMonth() && s.getDate() === today.getDate() || s.getTime() <= Date.now() ? e : null;
    }
    readonly property string kind: !Config.options.bar.showSpotlight ? ""
        : settings.media && Media.active ? "media"
        : settings.timers && Countdown.active ? "timer"
        : settings.timers && Stopwatch.active ? "stopwatch"
        : settings.events && event ? "event"
        : settings.fallback === "weather" ? "weather"
        : settings.fallback === "system" ? "system"
        : ""
    readonly property bool shown: kind !== ""

    // The default widgets read their data only while shown.
    property bool _holdsWeather: false
    property bool _holdsStats: false
    function _hold() {
        const w = kind === "weather", s = kind === "system";
        if (w !== _holdsWeather) {
            w ? Weather.hold() : Weather.release();
            _holdsWeather = w;
        }
        if (s !== _holdsStats) {
            s ? SystemStats.hold() : SystemStats.release();
            _holdsStats = s;
        }
    }
    onKindChanged: _hold()
    Component.onCompleted: _hold()
    Component.onDestruction: {
        if (_holdsWeather)
            Weather.release();
        if (_holdsStats)
            SystemStats.release();
    }

    // What the tile, the two lines and the button show for each kind.
    readonly property string icon: ({
            media: "music_note", timer: "timer", stopwatch: "avg_pace", event: "event",
            weather: Weather.ready ? Weather.icon : "cloud", system: "memory"
        })[kind] ?? ""
    readonly property string title: ({
            media: Media.title,
            timer: Countdown.text,
            stopwatch: Stopwatch.text,
            event: event?.title ?? "",
            weather: Weather.ready ? Weather.temperature : "Weather",
            system: `CPU ${SystemStats.cpuText}`
        })[kind] ?? ""
    readonly property string subtitle: ({
            media: Media.artist,
            timer: Countdown.paused ? "Paused" : Countdown.label,
            stopwatch: Stopwatch.running ? "Stopwatch" : "Paused",
            event: event ? (Calendar.startsIn(event) === "Now" || event.start.getTime() - Date.now() <= Tokens.eventSoon ? Calendar.startsIn(event) : Qt.formatTime(event.start, Config.options.bar.clockFormat)) : "",
            weather: Weather.ready ? Weather.description : Weather.error,
            system: `RAM ${SystemStats.memText}`
        })[kind] ?? ""
    readonly property bool hasButton: ["media", "timer", "stopwatch"].includes(kind)
    readonly property bool buttonPlaying: kind === "media" ? Media.playing : kind === "timer" ? !Countdown.paused : Stopwatch.running
    function pressButton() {
        if (kind === "media")
            Media.togglePlaying();
        else if (kind === "timer")
            Countdown.toggle();
        else if (kind === "stopwatch")
            Stopwatch.toggle();
    }
    // A click elsewhere on the cay opens what it's about.
    function open() {
        if (kind === "media" || kind === "timer" || kind === "stopwatch")
            Actions.run("island");
        else if (kind === "event")
            PanelState.toggle("calendar");
    }

    leftPadding: !shown ? 0 : Tokens.cayPaddingTight
    // The play button's hit area is wider than its glyph; keep the glyph cay-padding from the edge.
    rightPadding: !shown ? 0 : vertical ? Tokens.cayPaddingTight
        : hasButton ? Tokens.cayPadding - (Tokens.cayItemSm - Tokens.iconSm) / 2 : Tokens.cayPadding
    contentWidth: shown ? row.implicitWidth : 0
    contentHeight: shown ? row.implicitHeight : 0
    visible: width > 0.5
    opacity: fade.value

    Spring {
        id: fade
        spec: Motion.effectsDefault
        target: root.shown ? 1 : 0
    }

    Accessible.role: Accessible.Button
    Accessible.name: `Spotlight: ${root.title}${root.subtitle ? ", " + root.subtitle : ""}`

    MouseArea {
        anchors.fill: parent
        enabled: root.kind !== "weather" && root.kind !== "system"
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.open()
    }

    Grid {
        id: row
        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        columns: root.vertical ? 1 : 99   // one row, or one column on the left
        spacing: Tokens.space2
        verticalItemAlignment: Grid.AlignVCenter
        horizontalItemAlignment: Grid.AlignHCenter

        ClippingRectangle {
            id: art
            width: Tokens.cayItemSm
            height: Tokens.cayItemSm
            radius: Tokens.radiusArtSm
            color: root.kind === "system" ? Colors.secondaryContainer
                : root.kind === "event" ? Colors.primaryContainer : Colors.tertiaryContainer

            Icon {
                anchors.centerIn: parent
                visible: !(root.kind === "media" && cover.status === Image.Ready)
                name: root.icon
                size: Tokens.iconXs
                filled: true
                color: root.kind === "system" ? Colors.on.secondaryContainer
                    : root.kind === "event" ? Colors.on.primaryContainer : Colors.on.tertiaryContainer
            }

            Image {
                id: cover
                anchors.fill: parent
                source: root.kind === "media" ? Media.artUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: Tokens.cayItemSm * 2
                sourceSize.height: Tokens.cayItemSm * 2
                visible: root.kind === "media" && status === Image.Ready
            }
        }

        Column {
            visible: !root.vertical
            width: Math.min(Tokens.spotlightTextMax, Math.max(titleText.implicitWidth, subtitleText.implicitWidth))

            StyledText {
                id: titleText
                width: parent.width
                style: "barTitle"
                elide: Text.ElideRight
                text: root.title
            }
            StyledText {
                id: subtitleText
                width: parent.width
                visible: text !== ""
                style: "barSubtitle"
                color: Colors.on.surfaceVariant
                elide: Text.ElideRight
                text: root.subtitle
            }
        }

        CayButton {
            visible: root.hasButton
            size: Tokens.cayItemSm
            icon: root.buttonPlaying ? "pause" : "play_arrow"
            iconSize: Tokens.iconSm
            filled: true
            contentColor: Colors.on.surface
            label: root.buttonPlaying ? "Pause" : root.kind === "media" ? "Play" : "Resume"
            onClicked: root.pressButton()
        }
    }
}
