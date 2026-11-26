pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.theme
import qs.services

// Which Island is expanded (one at a time, on the monitor it was opened on),
// which tab it shows, and the live activities.
Singleton {
    id: root

    property bool expanded: false
    property string screenName: ""
    property string tab: "now"
    // The Tools tab's tool: calculator | emoji | color | screenshot (kept between opens).
    property string toolsPage: "calculator"

    readonly property var settings: Config.options.island.activities

    // ── activities, in priority order ───────────────────────────
    // Privacy and safety first, then short notices so they're seen, then what you
    // started yourself, then background states.
    readonly property list<Activity> all: [
        Activity {
            key: "recording"
            enabled: root.settings.recording
            live: Recording.active
            width: Tokens.islandActivityRecordingWidth
            leading: "dot"
            text: Recording.text
            textColor: Colors.on.island
            title: "Recording"
            subtitle: Recording.text
            subtitleMono: true
            value: Recording.text
            actions: [{ icon: "stop", label: "Stop recording", tone: "error", run: () => Recording.stop() }]
        },
        Activity {
            key: "screenShare"
            enabled: root.settings.screenShare
            live: Privacy.sharing
            icon: "screen_share"
            text: Privacy.screenApps[0] ?? "Sharing"
            textMono: false
            textColor: Colors.on.island
            title: "Sharing your screen"
            subtitle: Privacy.screenApps.join(", ")
        },
        Activity {
            key: "micCamera"
            enabled: root.settings.micCamera
            live: Privacy.micActive || Privacy.cameraActive
            icon: Privacy.cameraActive ? "videocam" : "mic"
            text: (Privacy.cameraActive ? Privacy.cameraApps : Privacy.micApps)[0] ?? "In use"
            textMono: false
            textColor: Colors.on.island
            title: Privacy.cameraActive && Privacy.micActive ? "Camera and microphone in use"
                : Privacy.cameraActive ? "Camera in use" : "Microphone in use"
            subtitle: [...new Set(Privacy.cameraApps.concat(Privacy.micApps))].join(", ")
        },
        Activity {
            key: "batteryLow"
            enabled: root.settings.battery
            live: Battery.low
            icon: "battery_alert"
            iconColor: Colors.error
            text: Battery.percent
            textColor: Colors.error
            title: Battery.critical ? "Battery critically low" : "Battery low"
            subtitle: Battery.percent + (Battery.powerSaver ? " · Power saver on" : "")
            value: Battery.percent
            actions: Battery.powerSaverAvailable && !Battery.powerSaver
                ? [{ icon: "energy_savings_leaf", label: "Turn on power saver", tone: "accent", run: () => Battery.usePowerSaver() }]
                : []
        },
        Activity {
            key: "charging"
            enabled: root.settings.battery
            notice: true
            live: Battery.chargingNotice
            icon: "bolt"
            text: Battery.percent
            title: "Charging"
            subtitle: Battery.percent
            value: Battery.percent
        },
        Activity {
            key: "bluetooth"
            enabled: root.settings.bluetooth
            notice: true
            live: BluetoothNotice.showing
            icon: BluetoothNotice.icon
            text: BluetoothNotice.hasBattery ? `${Math.round(BluetoothNotice.battery * 100)}%` : "Connected"
            textMono: BluetoothNotice.hasBattery
            textColor: BluetoothNotice.hasBattery ? Colors.islandAccent : Colors.on.island
            title: BluetoothNotice.name
            subtitle: "Connected" + (BluetoothNotice.hasBattery ? ` · ${Math.round(BluetoothNotice.battery * 100)}%` : "")
        },
        Activity {
            key: "event"
            enabled: root.settings.event
            live: Calendar.soon !== null
            icon: "event"
            text: Calendar.soon ? Calendar.startsIn(Calendar.soon) : ""
            textMono: false
            title: Calendar.soon?.title ?? ""
            subtitle: Calendar.soon ? Calendar.startsIn(Calendar.soon) + (Calendar.soon.location ? " · " + Calendar.soon.location : "") : ""
            actions: [{ icon: "calendar_month", label: "Open calendar", tone: "accent", run: () => Actions.run("calendar") }]
        },
        Activity {
            key: "focus"
            enabled: root.settings.focus
            live: Focus.active
            icon: Focus.phase === "focus" ? "self_improvement" : "local_cafe"
            text: Focus.text
            textColor: Focus.paused ? Colors.on.islandVariant : Colors.islandAccent
            title: Focus.phase === "focus" ? "Focus" + (Notifications.dnd ? " · Do not disturb" : "") : "Break"
            subtitle: Focus.text + (Focus.paused ? " · Paused" : "")
            subtitleMono: true
            value: Focus.text
            actions: [
                { icon: Focus.paused ? "play_arrow" : "pause", label: Focus.paused ? "Resume" : "Pause", tone: "accent", run: () => Focus.toggle() },
                { icon: "stop", label: "End session", tone: "neutral", run: () => Focus.stop() }
            ]
        },
        Activity {
            key: "progress"
            enabled: root.settings.progress
            live: Notifications.inProgress.length > 0
            readonly property var n: Notifications.inProgress[0] ?? null
            icon: "downloading"
            text: n ? `${Math.round(Number(n.hints.value))}%` : ""
            title: n ? (n.summary || n.appName) : ""
            subtitle: n ? `${n.appName} · ${Math.round(Number(n.hints.value))}%` : ""
            value: text
        },
        Activity {
            key: "timer"
            enabled: root.settings.timer
            live: Countdown.active
            width: Tokens.islandActivityTimerWidth
            icon: "timer"
            text: Countdown.text
            textColor: Countdown.paused ? Colors.on.islandVariant : Colors.islandAccent
            title: Countdown.label
            subtitle: Countdown.text + (Countdown.paused ? " · Paused" : "")
            subtitleMono: true
            value: Countdown.text
            actions: [
                { icon: Countdown.paused ? "play_arrow" : "pause", label: Countdown.paused ? "Resume timer" : "Pause timer", tone: "accent", run: () => Countdown.toggle() }
            ].concat(Countdown.paused ? [{ icon: "close", label: "Cancel timer", tone: "neutral", run: () => Countdown.cancel() }] : [])
        },
        Activity {
            key: "stopwatch"
            enabled: root.settings.stopwatch
            live: Stopwatch.active
            icon: "timer_play"
            text: Stopwatch.text
            textColor: Stopwatch.running ? Colors.islandAccent : Colors.on.islandVariant
            title: Stopwatch.laps.length > 0 ? `Stopwatch · Lap ${Stopwatch.laps.length + 1}` : "Stopwatch"
            subtitle: Stopwatch.text + (Stopwatch.running ? "" : " · Paused")
            subtitleMono: true
            value: Stopwatch.text
            actions: (Stopwatch.running
                    ? [{ icon: "pause", label: "Pause stopwatch", tone: "accent", run: () => Stopwatch.pause() },
                       { icon: "flag", label: "Lap", tone: "neutral", run: () => Stopwatch.lap() }]
                    : [{ icon: "play_arrow", label: "Resume stopwatch", tone: "accent", run: () => Stopwatch.start() },
                       { icon: "restart_alt", label: "Reset stopwatch", tone: "neutral", run: () => Stopwatch.reset() }])
        },
        Activity {
            key: "media"
            enabled: root.settings.media
            live: Media.playing
            width: Tokens.islandActivityMediaWidth
            leading: "art"
            trailing: "waveform"
            title: Media.title
            subtitle: Media.artist
            actions: [{ icon: Media.playing ? "pause" : "play_arrow", label: Media.playing ? "Pause" : "Play", tone: "accent", run: () => Media.togglePlaying() }]
        },
        Activity {
            key: "keepAwake"
            enabled: root.settings.keepAwake
            live: KeepAwake.active
            icon: "coffee"
            text: KeepAwake.text
            textMono: KeepAwake.until > 0
            title: "Keeping awake"
            subtitle: KeepAwake.until > 0 ? `${KeepAwake.text} left` : "Until you turn it off"
            value: KeepAwake.until > 0 ? KeepAwake.text : ""
            actions: [{ icon: "close", label: "Stop keeping awake", tone: "neutral", run: () => KeepAwake.disable() }]
        }
    ]

    // Dev aid: `qs -p ./reef ipc call island simulate <key>` toggles an activity on
    // with whatever values its service has, to check how it looks.
    property var simulated: ({})
    function simulate(key) {
        const s = Object.assign({}, simulated);
        s[key] = !s[key];
        simulated = s;
    }

    readonly property var liveActivities: all.filter(a => a.enabled && (a.live || !!simulated[a.key]))
    // Keys of the live activities, in priority order.
    readonly property var activities: liveActivities.map(a => a.key)

    function byKey(key) {
        return all.find(a => a.key === key) ?? null;
    }
    function isActivity(key) {
        return all.some(a => a.key === key);
    }

    // ── the Island as the Pearl ─────────────────────────────────
    // Each monitor's Island tells where its body is (screen coordinates), so the Pearl
    // can grow out of it (power actions, lock screen) and fold back into it.
    property var _bodies: ({})
    function registerBody(screen, rect) {
        _bodies[screen] = rect;
    }
    function unregisterBody(screen, rect) {
        if (_bodies[screen] === rect)
            delete _bodies[screen];
    }
    // { x, y, w, h }; the resting Island when there's none on that monitor.
    function bodyRect(screen, screenWidth) {
        const f = _bodies[screen];
        return f ? f() : { x: (screenWidth - Tokens.islandCollapsedWidth) / 2, y: Tokens.space2, w: Tokens.islandCollapsedWidth, h: Tokens.islandCollapsedHeight };
    }
    // The monitor whose Island is out being the Pearl (the power actions): it hides there
    // until the Pearl has folded back into it.
    property string pearlScreen: ""

    // The one the user put on the main Island by swapping; forgotten when it ends.
    property string preferred: ""

    // Shown on the main Island: the preferred one if it's live, else the highest priority.
    readonly property string activity: activities.includes(preferred) ? preferred : (activities[0] ?? "")
    // Shown in the pill below it: the next one in priority order.
    readonly property string secondaryActivity: activities.find(a => a !== activity) ?? ""

    // Put the secondary activity on the main Island.
    function swap() {
        if (secondaryActivity !== "")
            preferred = secondaryActivity;
    }

    readonly property var tabs: [
        { id: "now", icon: "graphic_eq", label: "Now" },
        { id: "shelf", icon: "inventory_2", label: "Shelf" },
        { id: "clipboard", icon: "content_paste", label: "Clipboard" },
        { id: "tools", icon: "widgets", label: "Tools" },
        { id: "coral", icon: "", label: "Coral" }
    ]
    // Tabs that exist so far; the others run their (stub) action.
    readonly property var builtTabs: ["now", "shelf", "clipboard", "tools"]

    // `tab` may also name a tool ("emoji", Super+.): the Tools tab opens on it.
    function open(tab, screen) {
        if (["calculator", "emoji", "color", "screenshot"].includes(tab)) {
            toolsPage = tab;
            tab = "tools";
        }
        if (tab && !builtTabs.includes(tab)) {
            Actions.run(tab);
            return;
        }
        root.tab = tab || "now";
        screenName = screen || Hyprland.focusedMonitor?.name || "";
        expanded = true;
    }

    function close() {
        expanded = false;
    }

    function toggle(screen) {
        if (expanded)
            close();
        else
            open("now", screen);
    }

    Connections {
        target: Actions
        // Super+I toggles; Super+V / Super+. close only when already on that tab.
        function onIslandRequested(tab) {
            const same = tab === "now" || tab === root.tab || (tab === root.toolsPage && root.tab === "tools");
            root.expanded && same ? root.close() : root.open(tab);
        }
        function onIslandSwapRequested() {
            root.swap();
        }
    }

    // A color was picked from the Tools tab: show it there.
    Connections {
        target: ColorPicker
        function onPicked(c) {
            root.open("color");
            Toasts.show({ text: `${ColorPicker.hex(c)} copied`, icon: "colorize" });
        }
    }
}
