pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Named shell actions, shared by keybinds (modules/Commands), IPC and buttons.
// Built actions run their handler; the rest log which milestone builds them.
Singleton {
    id: root

    // name → [description, milestone]   (keybinds: SURFACES.md → Keybinds)
    readonly property var actions: ({
            home: ["Home: an empty workspace", "M7"],
            search: ["Open search", "M4"],
            island: ["Open the Island", "M2"],
            islandSwap: ["Swap the Island's activities", "M2"],
            clipboard: ["Island → Clipboard", "M6"],
            shelf: ["Island → Shelf", "M6"],
            tools: ["Island → Tools", "M6"],
            emoji: ["Island → Tools (emoji)", "M6"],
            coral: ["Coral", "M8"],
            coralApp: ["The Coral app", "M8"],
            controlCenter: ["Control and notification center", "M3"],
            calendar: ["Calendar", "M3"],
            wifiMenu: ["Wi-Fi menu", "M3"],
            bluetoothMenu: ["Bluetooth menu", "M3"],
            audioOutput: ["Audio output menu", "M3"],
            dnd: ["Do not disturb", "M3"],
            nightLight: ["Night light", "M3"],
            micMute: ["Mute microphone", "M3"],
            screenshot: ["Screenshot of a region", "M3"],
            keepAwake: ["Keep awake", "M3"],
            focus: ["Focus session", "M3"],
            overview: ["Workspace overview", "M4"],
            switcher: ["Window switcher", "M4"],
            switcherBack: ["Window switcher, previous", "M4"],
            editMode: ["Edit mode", "M7"],
            settings: ["Settings", "M7"],
            lock: ["Lock", "M5"],
            power: ["Power actions", "M5"],
            focusBar: ["Keyboard focus to the bar", "M1"],
            volumeUp: ["Volume up", "M2"],
            volumeDown: ["Volume down", "M2"],
            volumeMute: ["Mute", "M2"],
            brightnessUp: ["Brightness up", "M2"],
            brightnessDown: ["Brightness down", "M2"]
        })

    // Actions with a global shortcut (bound in hypr/reef.lua).
    readonly property var shortcuts: ["search", "island", "islandSwap", "clipboard", "emoji", "coral", "coralApp", "controlCenter", "overview", "switcher", "switcherBack", "editMode", "lock", "power", "focusBar", "volumeUp", "volumeDown", "volumeMute", "brightnessUp", "brightnessDown"]

    // Surfaces listen to these.
    signal focusBarRequested
    signal islandRequested(string tab)
    signal islandSwapRequested
    signal panelRequested(string name)
    // The Settings app, on a page ("" = where it was).
    signal settingsRequested(string page)
    function openSettings(page) { settingsRequested(page ?? ""); }
    // Alt+Tab: open the switcher, or move its selection (1 forward, -1 back).
    signal switcherRequested(int step)

    readonly property var handlers: ({
            focusBar: () => root.focusBarRequested(),
            home: () => Workspaces.openHome(Hyprland.focusedMonitor?.name ?? ""),
            lock: () => Lock.lock(),
            power: () => root.panelRequested("power"),
            search: () => root.panelRequested("search"),
            overview: () => root.panelRequested("overview"),
            switcher: () => root.switcherRequested(1),
            switcherBack: () => root.switcherRequested(-1),
            island: () => root.islandRequested("now"),
            clipboard: () => root.islandRequested("clipboard"),
            shelf: () => root.islandRequested("shelf"),
            tools: () => root.islandRequested("tools"),
            emoji: () => root.islandRequested("emoji"),
            // Voice when it's set up, else the chat.
            coral: () => CoralVoice.available ? CoralVoice.start() : root.islandRequested("coral"),
            coralApp: () => Coral.openApp(),
            islandSwap: () => root.islandSwapRequested(),
            controlCenter: () => root.panelRequested("controlCenter"),
            editMode: () => root.panelRequested("editMode"),
            settings: () => root.settingsRequested(""),
            calendar: () => root.panelRequested("calendar"),
            wifiMenu: () => root.panelRequested("wifi"),
            bluetoothMenu: () => root.panelRequested("bluetooth"),
            audioOutput: () => root.panelRequested("audio"),
            dnd: () => Notifications.setDnd(!Notifications.dnd),
            nightLight: () => NightLight.toggle(),
            micMute: () => Audio.toggleMicMute(),
            screenshot: () => Screenshot.region(),
            keepAwake: () => KeepAwake.toggle(0),
            focus: () => Focus.active ? Focus.stop() : Focus.start(0),
            volumeUp: () => Audio.setVolume(Audio.volume + 0.05),
            volumeDown: () => Audio.setVolume(Audio.volume - 0.05),
            volumeMute: () => Audio.toggleMute(),
            brightnessUp: () => Brightness.step(0.05),
            brightnessDown: () => Brightness.step(-0.05)
        })

    function run(name) {
        const handler = handlers[name];
        if (handler) {
            handler();
            return;
        }
        const a = actions[name];
        if (!a) {
            console.warn("Reef: unknown action", name);
            return;
        }
        console.info("Reef:", a[0], "isn't built yet (" + a[1] + ")");
    }
}
