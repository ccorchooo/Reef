import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
import qs.modules.island

// Entry points for keybinds and scripts; the actions themselves live in services/Actions.
//
//   Hyprland:  hl.bind("SUPER + V", hl.dsp.global("reef:clipboard"))   (see hypr/reef.lua)
//   Shell:     qs -c reef ipc call reef run clipboard
//              qs -c reef ipc call reef dev
Scope {
    id: root

    IpcHandler {
        target: "reef"

        function run(name: string): void {
            Actions.run(name);
        }

        // Open the Settings app, optionally on a page (look, displays, bar, sound, network,
        // bluetooth, coral, keyboard, power, accessibility, about).
        function settings(page: string): void {
            Actions.openSettings(page);
        }

        // Toggle the M0 dev window.
        function dev(): void {
            Config.options.debug.devWindow = !Config.options.debug.devWindow;
        }

        // Service state as JSON, for debugging.
        function status(): string {
            return JSON.stringify({
                audio: { ready: Audio.ready, volume: Audio.volume, muted: Audio.muted, sink: Audio.sink?.description ?? null },
                mic: { source: Audio.source?.description ?? null, id: Audio.source?.id ?? null, ready: Audio.source?.ready ?? false, muted: Audio.micMuted, inputs: Audio.inputs.map(n => n.description) },
                network: { icon: Network.icon, label: Network.label },
                battery: { present: Battery.present, level: Battery.level, icon: Battery.icon },
                media: { active: Media.active, title: Media.title, playing: Media.playing },
                workspaces: { focused: Workspaces.focusedId, all: Workspaces.all.map(w => w.id) },
                dock: Apps.dock.map(i => ({ id: i.id, entry: i.entry?.id ?? null, icon: i.entry?.icon ?? null, running: i.running, focused: i.focused })),
                pinned: Apps.pinnedIds,
                calendar: { sources: Calendar.sources, events: Calendar.events.length, next: Calendar.next?.title ?? null, soon: Calendar.soon?.title ?? null },
                notifications: { count: Notifications.count, dnd: Notifications.dnd, popup: Notifications.popup?.summary ?? null },
                activities: IslandState.activities
            }, null, 1);
        }

        // Start a countdown: "5m", "90s", "1h30m", "4:12".
        function timer(duration: string): string {
            const s = Countdown.parse(duration);
            if (s <= 0)
                return "Couldn't read that duration";
            Countdown.start(s, "Timer");
            return "ok";
        }

        function timerCancel(): void {
            Countdown.cancel();
        }

        function toast(text: string): void {
            Toasts.show({ text: text, icon: "info" });
        }

        // Regenerate the color scheme from the current wallpaper/static color.
        function scheme(): string {
            Scheme.regenerate();
            return Scheme.lastError || "ok";
        }
    }

    IpcHandler {
        target: "island"

        function open(tab: string): void {
            IslandState.open(tab || "now");
        }
        function close(): void {
            IslandState.close();
        }
        function toggle(): void {
            IslandState.toggle();
        }
        // Put the secondary live activity on the main Island.
        function swap(): void {
            IslandState.swap();
        }

        // Dev aid: toggle an activity on to see how it looks (e.g. "charging", "bluetooth").
        function simulate(key: string): string {
            if (!IslandState.isActivity(key))
                return "Activities: " + IslandState.all.map(a => a.key).join(", ");
            IslandState.simulate(key);
            return IslandState.simulated[key] ? "on" : "off";
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void { Lock.lock(); }
        // Show the lock screen without locking (Escape closes it).
        function preview(): void { Lock.showPreview(!Lock.preview); }
    }

    IpcHandler {
        target: "stopwatch"

        function start(): void { Stopwatch.start(); }
        function pause(): void { Stopwatch.pause(); }
        function toggle(): void { Stopwatch.toggle(); }
        function lap(): void { Stopwatch.lap(); }
        function reset(): void { Stopwatch.reset(); }
    }

    IpcHandler {
        target: "keepAwake"

        // "30m", "2h", or "" to stay awake until turned off.
        function on(duration: string): void {
            KeepAwake.enable(Countdown.parse(duration || "0") / 60);
        }
        function off(): void { KeepAwake.disable(); }
        function toggle(): void { KeepAwake.toggle(0); }
    }

    IpcHandler {
        target: "panel"

        // "controlCenter", "search", "calendar", "wifi", "bluetooth", "audio"
        function toggle(name: string): void { PanelState.toggle(name); }
        function close(): void { PanelState.closeAll(); }
    }

    // The workspace overview: `overview go 3` goes to workspace 3 the way Enter on its card
    // does (the overview must be open).
    IpcHandler {
        target: "overview"

        function go(id: int): void { PanelState.overviewGoRequested(id); }
        function select(id: int): void { PanelState.overviewWorkspace = id; }
    }

    IpcHandler {
        target: "focus"

        function start(minutes: string): void { Focus.start(Number(minutes) || 0); }
        function stop(): void { Focus.stop(); }
        function toggle(): void { Focus.toggle(); }
    }

    IpcHandler {
        target: "notifications"

        function dnd(): string {
            Notifications.setDnd(!Notifications.dnd);
            return Notifications.dnd ? "on" : "off";
        }
        function clear(): void { Notifications.clearAll(); }
    }

    Connections {
        target: Focus
        function onPhaseEnded(phase) {
            if (phase === "focus")
                Toasts.show({ text: "Focus session done", icon: "self_improvement", action: "Take a break", onAction: () => Focus.startBreak() });
            else
                Toasts.show({ text: "Break's over", icon: "local_cafe", action: "Focus again", onAction: () => Focus.start(0) });
        }
    }

    // A finished timer says so.
    Connections {
        target: Countdown
        function onFinished() {
            const total = Countdown.total;
            Toasts.show({ text: `${Countdown.label} done`, icon: "timer", action: "Restart", onAction: () => Countdown.start(total, Countdown.label) });
        }
    }

    Variants {
        model: Actions.shortcuts
        GlobalShortcut {
            required property string modelData
            appid: "reef"
            name: modelData
            description: Actions.actions[modelData][0]
            onPressed: Actions.run(modelData)
        }
    }

    // Holding Super (hypr/reef.lua binds Super's press to this): the Navigator shows the
    // workspaces while it's held.
    GlobalShortcut {
        appid: "reef"
        name: "superHold"
        description: "Hold Super to see the workspaces"
        onPressed: PanelState.superDown()
        onReleased: PanelState.superUp()
    }

    IpcHandler {
        target: "superHold"

        function down(): void { PanelState.superDown(); }
        function up(): void { PanelState.superUp(); }
    }
}
