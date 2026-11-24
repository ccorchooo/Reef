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

        // Toggle the M0 dev window.
        function dev(): void {
            Config.options.debug.devWindow = !Config.options.debug.devWindow;
        }

        // Service state as JSON, for debugging.
        function status(): string {
            return JSON.stringify({
                audio: { ready: Audio.ready, volume: Audio.volume, muted: Audio.muted, sink: Audio.sink?.description ?? null },
                network: { icon: Network.icon, label: Network.label },
                battery: { present: Battery.present, level: Battery.level, icon: Battery.icon },
                media: { active: Media.active, title: Media.title, playing: Media.playing },
                workspaces: { focused: Workspaces.focusedId, all: Workspaces.all.map(w => w.id) },
                dock: Apps.dock.map(i => ({ id: i.id, entry: i.entry?.id ?? null, icon: i.entry?.icon ?? null, running: i.running, focused: i.focused })),
                pinned: Apps.pinnedIds
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
}
