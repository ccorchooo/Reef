# Surfaces

How every part of Reef looks and behaves. Each section links to its mockup in `design/mockups/`. Token names refer to `design/tokens.json`; motion names refer to [MOTION.md](MOTION.md).

## Global rules

- **The screen is rounded.** Every monitor's corners are masked with `radius-xl` (28px), so the desktop reads as one rounded sheet. This is a permanent overlay layer, not part of the wallpaper.
- **Tide panels are part of the screen.** Panels attached to an edge (control/notification center, edit mode) run the **full height** of the screen with **no shadow**. Their outer corners are the screen's own corners. Where their inner edge meets the top and bottom of the screen, they flare out with **concave 28px fillets**, so the desktop beside them looks like a rounded sheet (Caelestia-style).
- **Sections sit on cards, not dividers.** A Tide panel's background is `surface-container-low`. Every section inside it (notifications, quick toggles, sliders, each edit-mode group) sits on its own `surface-container` card with 24px corners and 10px gaps.
- **Edge OSDs grab the screen too.** Shorter elements attached to an edge (the volume and brightness OSD) meet it with the same concave fillets and use `radius-xl` on their free corners.
- **No how-to text in menus.** Panels, switchers and dialogs don't explain gestures or shortcuts. Keybinds live in Settings → Keyboard & shortcuts.
- **Everything is a setting**, including per monitor (see [ARCHITECTURE.md](ARCHITECTURE.md#configuration)).

## Bar (four cays)
Mockups: `screens/Home.png`, `screens/Bar.png`, `screens/BarLeft.png`

- Four separate pills, called **cays**, sit `space-2` (8px) apart and `space-2` above the bottom edge. Only the cays take clicks; the gaps between them click through. The bar reserves `cay-height` + `space-2`.
  - **Dock**: pinned and running apps, with icons from the user's icon theme (the colored tiles in the mockup stand in for them). A running app has a small dot under its tile; the focused app's tile sits on `secondary-container`. Click launches, focuses, or cycles that app's windows; middle-click opens a new window. With no pins set, Reef pins the first installed terminal, file manager, browser, editor and music app.
  - **Navigator**: home (Reef logo), search, workspaces.
  - **Spotlight**: the "special widget", which shows the current media or another chosen widget. For media: artwork (or a note on `tertiary-container`), title, artist, and play/pause. It folds away when nothing is playing.
  - **Status**: notifications bell, clock, Wi-Fi (or wired), volume, battery (hidden without one). Clicking it opens the control center; clicking the clock opens the calendar. Scrolling over it changes the volume.
- Each cay is `cay-height` (40px) tall, `radius-full`, on `surface-container`, with `shadow-float`. In Frosted mode it sits on a blurred surface.
- **The Navigator cay re-forms in place** for each mode, using `spatial-default`:
  - **home**: the three icons.
  - **search**: the cay becomes the search field, and the results panel grows upward from it (`screens/Search.png`).
  - **workspaces**: workspace numbers 1–5, with the active one in a `primary` pill that slides between them (`screens/Workspaces.png`). Workspaces with windows use `on-surface`, empty ones `on-surface-variant`; workspaces beyond 5 appear while they exist. Opened from the grid button and closed by it; scrolling over the Navigator moves between workspaces and switches to this mode.
  - **power**: Lock, Log out, Sleep, Restart, Power off and Cancel. The Dock and Spotlight cays hide (`screens/PowerActions.png`).
- **Bar on the left**: the cays stack vertically, and the clock stacks as `09` over `41` using narrowed `wdth` numerals.
- Per monitor, the bar can be turned off on any monitor.
- **Keyboard:** Super+B moves keyboard focus into the bar. Tab and Shift+Tab move between controls, Enter or Space activates, and Escape, Super+B or a click elsewhere leaves.

## The Island
Mockups: `parts/Island-Rest.png`, `parts/Island-*.png`, `screens/Working.png`, `screens/Notifications.png`

- **At rest:** a black pill (`island`, 120×32px) at the top center.
- **On the home screen** (no windows open): always visible. Hover expands it into a peek of the current activity.
- **With an app open:** hidden. Pointing at the top center for 150ms drops it in **over** the app with `shadow-island`. It never reserves space.
- **Collapsed live activities:** a leading glyph and a readout, each with a peek and a row in the Now tab. The Island shows the highest-priority one:
  1. **Recording**: red dot and elapsed time; Stop.
  2. **Screen sharing**: which app is capturing the screen (Pipewire portal streams).
  3. **Microphone / camera in use**: which apps, read from Pipewire links. Listening to the speakers (cava, system-audio recorders) doesn't count.
  4. **Low battery**: at or below the low level (15%), in `error`; offers Power saver when UPower has power profiles.
  5. **Charging**: a 5-second notice when the charger is plugged in, with the level.
  6. **Bluetooth device connected**: a 5-second notice with the device's icon, name and battery.
  7. **Timer**: remaining time; pause, resume, cancel.
  8. **Stopwatch**: elapsed time with tenths; pause, lap, resume, reset. Started from the Tools tab (M6) or `qs -p ./reef ipc call stopwatch start`.
  9. **Media**: artwork plus a mini waveform.
  10. **Keep awake**: blocks idle and screen blanking while on (Wayland idle inhibitor), with the time left; started from the control center (M3) or `ipc call keepAwake on 30m`.
  Each can be turned off in Settings → Bar & Island → Activities.
  - **A second activity** gets its own collapsed pill below the Island, `space-2` under it and as wide as the Island's collapsed form. It slides out from under the Island and stays below the hover peek. Clicking it (or Super+Shift+I) swaps the two: the Island and the pill morph to each other's width while their contents crossfade. Reef remembers the choice until that activity ends. With three activities, the third shows in the Now tab.
  - The waveform comes from cava and rests in the mockup's shape when the visualizer is off (Settings → Power & performance).
  - Recording shows any running gpu-screen-recorder, wf-recorder or wl-screenrec (Settings → Bar & Island → Detect screen recording).
  - Timers start from the Tools tab (M6) or `qs -p ./reef ipc call reef timer 5m`. A finished timer shows a toast with **Restart**.
- **Hover peek:** shown only when there's an activity, with its main control (play/pause, pause timer, stop recording). It can be turned off in settings.
- **Opening:** click the Island or press Super+I. Escape, Super+I or a click elsewhere closes it. Tab moves between its controls.
- **Expanded tabs**, chosen from a row of small icons at the bottom of the Island or by scrolling over it:
  1. **Now**: media (artwork in an M3E shape, wavy progress bar, controls) plus other live activities. The wave travels while playing and flattens when paused. Drag it to seek. The speaker button opens the audio output menu (M3). With nothing going on, a single "Nothing playing" row.
  2. **Shelf**: drop files, images or text anywhere on the Island to keep them here temporarily, then drag them out to another app.
  3. **Clipboard**: history with search and pinned items. **Super+V** opens the Island straight to this tab.
  4. **Tools**: calculator, emoji picker, color picker, screenshot.
  5. **Coral**: the AI chat.
- **Notifications** appear inside the Island, with inline reply and actions, then go to the control center.
- Inside the Island, containers use the island grays `island-container` (#1c1c1e) and `island-container-high` (#2c2c2e). Like `island`, they're fixed in every theme.
- Per monitor, the Island can be turned off on any monitor.

## The Pearl
Mockups: `parts/Pearl-States.png`, `parts/Pearl-Lock.png`, `screens/Lock.png`, `screens/CoralVoice.png`

- The Pearl is the round form of the Island: a soft 9-lobed cookie shape filled with `island` black.
- **States:**
  - **Default:** a clock, or system stats in mono. The user chooses which.
  - **Media:** a progress ring in `island-accent` (or the album art's color).
  - **Timer:** a progress ring in `tertiary-container`.
  - **Coral speaking:** layered outline shapes that morph and pulse with the audio.
- The **Island → Pearl** morph uses `spatial-slow` (see MOTION.md).

## Lock screen
Mockup: `screens/Lock.png`

- Shows the wallpaper, with the Pearl in the center showing the clock and date, a greeting in `display-sm`, and a small media chip.
- **Bottom-left:** the password field, a black pill where **each typed character appears as the next M3E shape** (circle, cookie-4, clover, sunny, flower…). Next to it is a small cay with Sleep, Power off and Restart.
- **Wrong password:** the shapes morph back to circles, shake with `spatial-fast`, and the field tints `error-container`.
- **Bottom-right:** network, battery and keyboard layout.
- Use `WlSessionLock` plus PAM. Fingerprint support is optional.

## Login greeter
Mockup: `screens/Greeter.png`

- The logo lockup (ring plus the "Reef" wordmark) sits top-left, and the clock and date top-right.
- In the center: the user avatar in a cookie shape, the name, and the password field with shapes. Other users and Guest appear as small circles below.
- **Bottom-left:** a session picker. **Bottom-right:** accessibility, keyboard layout, and power buttons.
- Implement with greetd plus a Quickshell greeter.

## Search
Mockup: `screens/Search.png`

- Grows upward from the Navigator cay. The field stays at the bottom, where the cay was.
- Results are grouped as **Apps**, **Settings**, **Files**, and **Coral** ("Ask Coral about …").
- The selected row uses `secondary-container`. Typing `/` switches to commands such as `/power`, `/wallpaper` and `/scheme`.
- A light `scrim` dims the desktop behind it.

## Workspaces overview
Mockup: `screens/Workspaces.png`

- The current workspace zooms into a large `radius-xl` card with a `primary` ring. The neighboring workspaces peek in at the left and right edges.
- Below the card: the workspace number and its window count. Swipe or scroll to move between workspaces.

## Window switcher (Alt+Tab)
Mockup: `screens/Switcher.png`

- A `surface-container-low` card in the center of the screen holds window thumbnails, each with its app icon and title. The selected one has a `primary` ring.

## Control & notification center (Tide panel, right)
Mockup: `screens/ControlCenter.png`

- Full height and 392px wide, with concave fillets at the top and bottom of its left edge.
- It has three cards:
  1. **Notifications**: a "N notifications" header with a **Clear all** button. Each notification is an `surface-container-high` item with an app icon, app name, time, title, body, and optional actions. This card grows to fill the free space.
  2. **Quick toggles**: a mixed grid. Wi-Fi and Bluetooth are 2-column tiles with labels. Do not disturb, Night light, Screenshot and Mute mic are 1-column. A tile is a **squircle when off** and a **pill on `primary-container` when on**.
  3. **Sliders**: volume and brightness, as thick M3E sliders with a gap before the handle.

## Quick menus
Mockup: `screens/QuickMenus.png`

- These menus float above the Status cay as `surface-container` cards with `radius-xl` corners.
- **Calendar:** a month grid where today is a `primary` cookie shape and days with events get a small dot, followed by the next event.
- **Wi-Fi:** an on/off switch, then a list of networks (the connected one on `primary-container`), then a "Network settings" button.
- Bluetooth, audio output and battery menus follow the same pattern but are not mocked up yet.

## Notifications, OSD and toasts
Mockup: `screens/Notifications.png`

- New notifications expand the Island with a reply field.
- **The volume and brightness OSD** attaches to the right edge, vertically centered, with concave fillets. It shows a vertical fill bar and an icon only, **with no number**. It slides in from the edge on the focused monitor whenever the level changes (from any app or the media keys), stays while hovered, and can be dragged or scrolled.
- **Toasts** ("Copied to clipboard · Undo") appear centered above the bar on `inverse-surface`, one at a time, rising from the bar. A toast with an action stays a little longer.

## Authentication dialog (polkit)
Mockup: `screens/AuthDialog.png`

- A centered `radius-xl` card over a `scrim`, with a lock icon in a cookie shape and the title "Authentication required".
- It shows the requesting app and the user chip, then a password field with shapes, a "Details" link, and **Cancel** and **Authenticate** buttons.

## Power actions
Mockup: `screens/PowerActions.png`

- Opened with **Ctrl+Alt+Delete** or the power button.
- A heavy neutral scrim covers the desktop, with a big clock widget, the time, and the date and battery level.
- The Navigator cay re-forms into the power actions. On hover, **Power off** turns `error-container` and shows a tooltip.

## Edit mode (Tide panel, left)
Mockup: `screens/EditMode.png`

- Full height and 320px wide, with fillets on its right edge.
- It has four cards:
  1. A header with "Edit mode" and a **Done** button.
  2. **Home widgets**: draggable thumbnails for Clock, Weather, Media, System and Calendar.
  3. **Control center**: a tile layout you can rearrange.
  4. **Bar**: a "Move bar to left" button, "Show Spotlight cay", and "Bar on other monitors".
- On the desktop, widgets get a dashed `primary` outline, a remove badge, and a slight wiggle (off when Reduce motion is on). The Island shows "Editing home · Done".

## Coral (AI assistant)
Mockups: `screens/CoralVoice.png`, `parts/Island-Coral.png`

- **Voice:** the Island morphs into the Pearl at the top center. The Pearl pulses in layered M3E outlines driven by the audio. Below it: "Coral · listening", a live transcript, and **Type instead** and **Stop** buttons.
- **Chat:** when the spoken reply ends, the Pearl shrinks into a small orb and the Island opens into a chat card. The card shows the reply, action buttons Coral can offer (for example "Switch to Neutral"), and an "Ask a follow-up…" field with mic and send buttons.
- The API endpoint, model and voice are set in Settings → Coral. Coral should work with any OpenAI-compatible endpoint, including local ones.

## Settings app
Mockup: `screens/Settings.png`

- A normal window with a sidebar listing: Look, Displays, Bar & Island, Sound, Network, Bluetooth, Coral, Keyboard & shortcuts, Power & performance, Accessibility, and About.
- **Look page:**
  - A wallpaper card with a preview, seed color swatches, "Change wallpaper", and "Use static color".
  - Button groups for **Colorfulness** (Neutral / Tinted / Vivid), **Theme** (Auto / Light / Dark), and **Transparency** (Solid / Frosted). The selected option is a filled `primary` pill.
  - **Home logo**: Reef / Distro logo / Custom image.

## Keybinds (defaults)

| Keys | Action |
| --- | --- |
| `Super` | Search |
| `Super + V` | Island → Clipboard |
| `Super + .` | Island → Tools (emoji) |
| `Super + C` | Coral (voice) |
| `Super + N` | Control / notification center |
| `Super + Tab` | Workspace overview |
| `Alt + Tab` | Window switcher |
| `Super + E` | Edit mode |
| `Super + L` | Lock |
| `Ctrl + Alt + Delete` | Power actions |
| `Super + B` | Keyboard focus to the bar (Tab between controls, Escape to leave) |
| `Super + I` | Open or close the Island (Tab between controls, Escape to close) |
| `Super + Shift + I` | Swap the Island's activity with the one in the pill below |
| Volume and brightness keys | Change the level and show the edge OSD |
