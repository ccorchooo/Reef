# Roadmap

Build Reef in thin, working slices. Each milestone should be usable every day before moving on. Check a milestone off only when it matches its mockup and its settings work.

## M0 — Foundation ✅
- [x] Scaffold the Quickshell config (`reef/`) with `shell.qml`, per-screen `Variants`, and hot reload.
- [x] A token generator: `design/tokens.json` → `theme/Tokens.qml`. Add `island-container` (#1c1c1e) and `island-container-high` (#2c2c2e).
- [x] `Colors.qml`: scheme from the wallpaper (generated in Reef, `services/schemegen.js`), falling back to the reference scheme, with a live crossfade.
- [x] `Motion.qml` (springs, reduce motion, speed), `Type.qml`, `Icon.qml`, `Shapes.qml` with a morph demo.
- [x] `Config` singleton reading and writing `~/.config/reef/config.json`.
- [x] A Hyprland snippet with gaps, rounding, keybind stubs and the shell's start command (`hypr/reef.lua`; Hyprland 0.57 is configured in Lua).
- [x] A dev window (`reef/dev/DevWindow.qml`) showing color roles, type, icons, shapes and springs, toggled by `debug.devWindow` or `qs -c reef ipc call reef dev`.

## M1 — Frame & bar ✅
- [x] Rounded-screen corner overlay on every monitor.
- [x] The bar's four cays (Dock, Navigator, Spotlight, Status), live data, and per-monitor on/off.
- [x] Navigator workspaces mode.
- [x] Keyboard access to the bar (Super+B).

## M2 — The Island (core) ✅
- [x] Resting pill. Hover peek on the home screen; hidden and hover-reveal over apps.
- [x] Collapsed live activities: media, timer, recording.
- [x] Now tab with MPRIS controls and wavy progress.
- [x] Floating OSD for volume and brightness, with no number.
- [x] Toasts.
- [x] More live activities: a second activity in a swappable circle beside the Island (and a pill of activities under the expanded Island); screen sharing, microphone/camera in use, low battery, charging, Bluetooth device connected, stopwatch, keep awake.

## M3 — Control & notifications ✅
- [x] Reef as the notification server. Notifications in the Island with inline reply.
- [x] Control center Tide panel: full height, fillets, cards (notifications, quick toggles, sliders).
- [x] Quick menus: calendar, Wi-Fi, Bluetooth, audio output. They open in the Status cay on hover, or float inside the control center.
- [x] Tide panels push the bar aside. Quick toggles press like an M3E button group.
- [x] Island activities that need M3: progress from notifications (downloads, copies, installs), an upcoming calendar event ("Standup in 5 min"), and a focus session that turns on Do not disturb. Keep awake gets a control-center tile.

## M4 — Find & move ✅
- [x] Search launcher growing from the Navigator cay: apps, settings, files, `/` commands, Ask Coral. Opens on a tap of either Super key.
- [x] Workspace overview (Super+Tab): live window thumbnails, neighbours peeking in.
- [x] Alt+Tab window switcher: most recently used first, live thumbnails, release Alt to switch.

## M5 — Session
- [ ] Lock screen: WlSessionLock, PAM, the Pearl, password shapes, wrong-password shake.
- [ ] Power actions (Ctrl+Alt+Delete).
- [ ] Polkit authentication dialog.
- [ ] greetd greeter.

## M6 — Island tabs
- [ ] Shelf (drag in and out).
- [ ] Clipboard (cliphist, search, pin, Super+V).
- [ ] Tools: calculator, emoji picker, color picker, screenshot.

## M7 — Customize
Built and running; not ticked until checked by hand: edit mode (it now goes to an empty workspace, and widgets snap to a visible grid), the left bar, and Settings. Also done here: a Monochrome colorfulness, the Island accent and power scrim following the scheme (with real blur), the overview blurring the bar and hiding Hyprland's slide, and Spotlight sources with a default widget; Bluetooth in the Status cay, reorderable cays, an optional Workspaces cay, a shell-wide zoom, and the home button opening an empty workspace.
- [ ] Edit mode Tide panel and desktop widgets: clock, weather, media, system, calendar.
- [ ] Bar on the left.
- [ ] Settings app: Look, Displays, Bar & Island, Sound, Network, Bluetooth, Coral, Keyboard, Power & performance, Accessibility, About.

## M8 — Coral
- [x] OpenAI-compatible streaming chat in the Island.
- [x] The Coral app: saved conversations, model menu, attachments (images, text, PDFs), edit, regenerate, reasoning.
- [ ] Voice mode: Pearl pulse, transcript, speech-to-text and text-to-speech.
- [x] Actions through Reef IPC.
- [x] Island activity: Coral thinking and replying.

## M9 — Polish
- [ ] Sounds, Frosted mode (blur), the Vivid scheme variant.
- [ ] Performance mode, multi-monitor edge cases, accessibility pass (contrast, keyboard navigation, reduce motion).
- [ ] An installer or package.
