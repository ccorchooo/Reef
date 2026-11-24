# Surfaces

How every part of Reef looks and behaves. Each section links to its mockup in `design/mockups/`. Token names refer to `design/tokens.json`; motion names refer to [MOTION.md](MOTION.md).

## Global rules

- **The screen is rounded.** Every monitor's corners are masked with `radius-xl` (28px), so the desktop reads as one rounded sheet. This is a permanent overlay layer, not part of the wallpaper.
- **Tide panels are part of the screen.** Panels attached to an edge (control/notification center, edit mode) run the **full height** of the screen with **no shadow**. Their outer corners are the screen's own corners. Where their inner edge meets the top and bottom of the screen, they flare out with **concave 28px fillets**, so the desktop beside them looks like a rounded sheet (Caelestia-style).
- **Sections sit on cards, not dividers.** A Tide panel's background is `surface-container-low`. Every section inside it (notifications, quick toggles, sliders, each edit-mode group) sits on its own `surface-container` card with 24px corners and 10px gaps.
- **Tide panels push the bar.** While a Tide panel is open the cays slide aside by the panel's width (with the panel's own `spatial-default` spring) instead of being covered. Settings → Bar & Island → "Panels push the bar".
- **The OSD floats.** The volume and brightness OSD is a free card `space-4` from the right edge with `radius-xl` on every corner and `shadow-menu`, not attached to the edge.
- **No how-to text in menus.** Panels, switchers and dialogs don't explain gestures or shortcuts. Keybinds live in Settings → Keyboard & shortcuts.
- **Everything is a setting**, including per monitor (see [ARCHITECTURE.md](ARCHITECTURE.md#configuration)).

## Bar (four cays)
Mockups: `screens/Home.png`, `screens/Bar.png`, `screens/BarLeft.png`

- Four separate pills, called **cays**, sit `space-2` (8px) apart and `space-2` above the bottom edge. Only the cays take clicks; the gaps between them click through. The bar reserves `cay-height` + `space-2`.
  - **Dock**: pinned and running apps, with icons from the user's icon theme (the colored tiles in the mockup stand in for them). A running app has a small dot under its tile; the focused app's tile sits on `secondary-container`. Click launches, focuses, or cycles that app's windows; middle-click opens a new window. With no pins set, Reef pins the first installed terminal, file manager, browser, editor and music app.
  - **Navigator**: home (Reef logo), search, workspaces.
  - **Spotlight**: the "special widget", which shows the current media or another chosen widget. For media: artwork (or a note on `tertiary-container`), title, artist, and play/pause. It folds away when nothing is playing.
  - **Status**: the clock on the left, then a gap (at least `cay-status-split`), then the controls on the right: notifications bell, Wi-Fi (or wired), volume, battery (hidden without one). **Clicking anywhere on it opens the control center.** The items aren't buttons: resting the pointer on the clock, network or volume icon for `menu-hover-delay` opens its quick menu (calendar, Wi-Fi, audio output) **inside the cay**, which grows up and out into a `radius-xl` card holding the menu above the row (see Quick menus). Scrolling over it changes the volume. The bell fills when there are notifications and turns to `notifications_off` with Do not disturb. With "Status menus on hover" off (Settings → Bar & Island), clicking an item opens its menu instead.
- Each cay is `cay-height` (40px) tall, `radius-full`, on `surface-container`, with `shadow-float`. In Frosted mode it sits on a blurred surface.
- **The Navigator cay re-forms in place** for each mode, using `spatial-default`:
  - **home**: the three icons.
  - **search**: the cay becomes the search field, and the results panel grows upward from it (`screens/Search.png`).
  - **workspaces**: workspace numbers 1–5, with the active one in a `primary` pill that slides between them (`screens/Workspaces.png`). Workspaces with windows use `on-surface` on a subtle `surface-container-high` circle, empty ones `on-surface-variant` with none; workspaces beyond 5 appear while they exist. Scrolling over the Navigator moves between workspaces and switches to this mode. **Holding Super** for `super-hold-delay` shows this mode until Super is let go (only here, not the overview; letting go after a hold doesn't open search).
  - **With the workspace overview open**, this mode shows and drives the overview's selection: the pill follows the overview as it moves, and clicking a numeral or scrolling over the Navigator moves the overview.
  - The **grid button** opens the workspace overview (and closes it again).
  - **power**: Lock, Log out, Sleep, Restart, Power off and Cancel. The Dock and Spotlight cays hide (`screens/PowerActions.png`).
- **Bar on the left**: the cays stack vertically, and the clock stacks as `09` over `41` using narrowed `wdth` numerals.
- Per monitor, the bar can be turned off on any monitor.
- **Keyboard:** Super+B moves keyboard focus into the bar. Tab and Shift+Tab move between controls, Enter or Space activates, and Escape, Super+B or a click elsewhere leaves.

## The Island
Mockups: `parts/Island-Rest.png`, `parts/Island-*.png`, `screens/Working.png`, `screens/Notifications.png`

- **At rest:** a black pill (`island`, 120×32px) at the top center.
- **On the home screen** (no windows open): always visible. Hover expands it into a peek of the current activity.
- **With an app open:** hidden. Pointing at the top center for 150ms drops it in **over** the app with `shadow-island`. It stays while the pointer is anywhere from the top edge down through the Island (including the gap above it and the circle beside it) and leaves `island-hide-delay` after the pointer does. It never reserves space.
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
  - **A second activity** shows as a small black circle (`island-collapsed-height`) `space-2` to the right of the Island, holding just its glyph (icon, dot or artwork). It slides out from behind the Island and follows it through the hover peek. Clicking it (or Super+Shift+I) puts it on the Island: the Island morphs to its width while the contents crossfade. Reef remembers the choice until that activity ends.
  - **Expanded**, the Island has no circle; every live activity other than media sits in **its own pill under the Island**, `space-2` below it and exactly as wide, as rows on `island-container` with their controls.
  - The waveform comes from cava and rests in the mockup's shape when the visualizer is off (Settings → Power & performance).
  - Recording shows any running gpu-screen-recorder, wf-recorder or wl-screenrec (Settings → Bar & Island → Detect screen recording).
  - Timers start from the Tools tab (M6) or `qs -p ./reef ipc call reef timer 5m`. A finished timer shows a toast with **Restart**.
- **Hover peek:** shown only when there's an activity, with its main control (play/pause, pause timer, stop recording). It can be turned off in settings.
- **Opening:** click the Island or press Super+I. Escape, Super+I or a click elsewhere closes it. Tab moves between its controls.
- **Expanded tabs**, chosen from a column of small black circles (`island-tab`) `space-2` to the **left** of the Island, top-aligned, or by scrolling over it. They slide out from behind the Island as it expands, leaving the Island all its room for the tab:
  1. **Now**: media (artwork in an M3E shape, wavy progress bar, controls). The other live activities are in the pill below. The wave travels while playing and flattens when paused. Drag it to seek. The speaker button opens the audio output menu in the control center. With no media, a single "Nothing playing" row.
  2. **Shelf**: drop files, images or text anywhere on the Island to keep them here temporarily, then drag them out to another app.
  3. **Clipboard**: history with search and pinned items. **Super+V** opens the Island straight to this tab.
  4. **Tools**: calculator, emoji picker, color picker, screenshot.
  5. **Coral**: the AI chat.
- **Notifications** appear inside the Island (440 wide) on the focused monitor, with an inline reply field when the app supports it, otherwise its actions. They stay 6 seconds (longer while hovered or while typing a reply; critical ones until dismissed), then go to the control center. Do not disturb holds back everything but critical notifications. Clicking a notification runs its default action. Escape or the close button dismisses it.
- **Notification progress:** a notification that reports progress (hint `value`) becomes an Island activity with its percentage.
- **Upcoming event:** 15 minutes before a calendar event, it becomes an Island activity ("In 4 min").
- **Focus session:** a focus period (25 min) with Do not disturb on, then a toast offers a break (5 min). Both lengths are settings.
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

- With an empty field it lists **every app** (recently opened first, then A–Z) and a bare `/` lists **every command**; the panel scrolls. Typing narrows each section to its best few.
- Opened by **tapping either Super key on its own** (Super pressed and released with no other key), the Navigator's search button, or `qs -p ./reef ipc call panel toggle search`.
- The Navigator cay grows up into it (`search-width`, `radius-xl`, `spatial-default`); the field (`search-field-height`, a `primary`-outlined pill) stays at the bottom, where the cay was. The Dock and Spotlight stay on the bar beside it. It grows to `search-max-height`, then the results scroll.
- Results are grouped as **Apps**, **Settings**, **Files**, and **Coral** ("Ask Coral about …"). Apps match by name, generic name, keywords; recently opened ones rank higher and show "last opened …". Settings act in place until the Settings app exists (a toggle flips, a menu opens in the control center). Files come from `find` in the home folder (hidden folders skipped) after `search-file-delay`; Settings → Search → "Search files" turns it off. Coral says it isn't here yet until M8.
- The selected row uses `secondary-container`. Up/Down (or Tab) move it, Enter opens it, Escape or a click elsewhere closes. Typing `/` switches to commands: every built action (`/dnd`, `/nightLight`, `/controlCenter`, …) plus `/scheme`.
- A light `scrim` (`scrim` at `scrim-light`) dims the desktop behind it.

## Workspaces overview
Mockup: `screens/Workspaces.png`

- Opened with **Super+Tab**, the Navigator's grid button, or `panel toggle overview`.
- Like GNOME's: **the screen collapses into the card.** The overview waits (at most `overview-capture-wait`) until it has the windows' pictures, so its first frame is the screen itself: the card exactly over the screen with the windows live in it right where they are (`ScreencopyView`). Then it shrinks (`spatial-slow`) to the screen at `overview-scale`, a `radius-xl` card with a `primary` ring (`overview-ring`). Nothing is left behind it but the background: the wallpaper (`look.wallpaper`), or `surface` without one, dimmed by the `scrim` as the card settles. The windows are never shown twice. Inside the card the wallpaper repeats (or `surface-container-lowest`). Closing grows the card back to the screen, and the overview is gone the moment it fills it (the spring's overshoot is never drawn).
- Going to a workspace or window waits `focus-handoff-delay` after the overview lets go of the keyboard, so Hyprland's refocus of the old window doesn't undo it. The Alt+Tab switcher does the same.
- The neighboring workspaces peek in at the left and right edges, `space-12` away. The bar stays visible below it, with the Navigator showing the workspaces; the two share one selection, so moving in either moves both.
- Below the card: the workspace number and its window count ("Empty" when it has none). Swipe, scroll, Left/Right or Tab move between workspaces (the card slides with `spatial-default`). Enter or a click on the current card goes there; a click on a neighbour selects it; a click on a window focuses it. Escape, Super+Tab or a click on the background closes.
- Settings → Power & performance → "Live window thumbnails" off shows one still frame per window.

## Window switcher (Alt+Tab)
Mockup: `screens/Switcher.png`

- A `surface-container-low` `radius-xl` card with `shadow-menu` in the center of the focused monitor holds window thumbnails (`switcher-thumb-width` × `switcher-thumb-height`, the window's shape fitted inside), most recently used first, each with its app icon and name. The selected one has a `primary` ring (`overview-ring`). Too many to fit, and the row scrolls to keep the selection in the middle.
- **Alt+Tab** opens it on the previous window; each further Tab moves on (Shift+Tab back), and letting go of Alt switches to the selected window, changing workspace if needed. Enter or a click switches too; Escape or a click elsewhere cancels.

## Control & notification center (Tide panel, right)
Mockup: `screens/ControlCenter.png`

- Full height and 392px wide (`panel-width`), with concave fillets at the top and bottom of its left edge. It slides in from the right with `spatial-default`, pushing the bar aside. Its cards keep the same `space-3` margin on both sides. Escape, the Status cay or a click outside closes it; Tab moves between its controls.
- It has three cards:
  1. **Notifications**: a "N notifications" header with a **Clear all** button. Each notification is an `surface-container-high` item with an app icon, app name, time, title, body, and optional actions. This card grows to fill the free space.
  2. **Quick toggles**: a mixed grid, one M3E button group per row. Wi-Fi and Bluetooth are 2-column tiles with labels. Do not disturb, Night light, Screenshot and Mute mic are 1-column. A third row holds Keep awake and Focus as 2-column tiles. A tile is a **squircle when off** and a **pill on `primary-container` when on**. Pressing a tile widens it by `press-grow` while the rest of its row gives up that width (the Pixel press); on release it springs back and morphs to its new shape. Right-click (or the Menu key) on Wi-Fi or Bluetooth opens its menu, floating inside the panel.
     - **Night light** warms the screen with a Hyprland screen shader written from the temperature setting (no extra programs).
     - **Screenshot** captures a region (slurp + grim), saves it to ~/Pictures/Screenshots and copies it, with a toast.
  3. **Sliders**: volume and brightness (brightness only with a backlight), as thick M3E sliders with a gap before the handle. While the control center or audio menu is open, the OSD stays hidden.

## Quick menus
Mockup: `screens/QuickMenus.png`

- A quick menu has two homes:
  - **In the Status cay** (pointer resting on a Status item, no panel open): the cay grows up and out (`spatial-default`, width and height to fit the menu, corners to `radius-xl`) and the menu fades in above the row. The chosen item slides to the right end of the row alone; the others close up on the left after the clock. The clock (calendar) never moves. Resting on another item switches menus; leaving the cay closes it after `menu-close-delay`, unless a field in it is being typed in (then a click elsewhere or Escape closes it). Items sliding under a still pointer don't switch menus.
  - **Inside the control center**: opened from anywhere else (a tile's menu, the Island's output button, a keybind, IPC), the menu opens the control center if needed and floats in it as a `surface-container-high` `radius-xl` card with `shadow-menu`, over a `scrim` on the panel. Escape or a click on the scrim closes just the menu.
- **Calendar:** a month grid where today is a `primary` cookie shape and days with events get a small dot, followed by the next event. Events come from iCalendar sources (.ics files or https links) in Settings → Calendar.
- **Wi-Fi:** an on/off switch, then a list of networks (the connected one on `primary-container`), then a "Network settings" button.
- **Bluetooth** and **audio output** menus follow the same pattern: a switch (Bluetooth), the devices or outputs with the current one on `primary-container`, and a settings button (Bluetooth scans while open). The audio menu also has the volume slider. A battery menu isn't built yet.

## Notifications, OSD and toasts
Mockup: `screens/Notifications.png`

- New notifications expand the Island with a reply field.
- **The volume and brightness OSD** floats `space-4` from the right edge, vertically centered: a `surface-container` card with `radius-xl` corners and `shadow-menu`. It shows a vertical fill bar (clipped to the track's rounded ends) and an icon only, **with no number**. It slides in from the right on the focused monitor whenever the level changes (from any app or the media keys), stays while hovered, and can be dragged or scrolled.
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
| `Super` (left or right, tapped alone) | Search |
| `Super` (held) | Show the workspaces in the bar |
| `Super + V` | Island → Clipboard |
| `Super + .` | Island → Tools (emoji) |
| `Super + C` | Coral (voice) |
| `Super + N` | Control / notification center |
| `Super + Tab` | Workspace overview |
| `Alt + Tab` (hold Alt) | Window switcher; `Alt + Shift + Tab` steps back |
| `Super + E` | Edit mode |
| `Super + L` | Lock |
| `Ctrl + Alt + Delete` | Power actions |
| `Super + B` | Keyboard focus to the bar (Tab between controls, Escape to leave) |
| `Super + I` | Open or close the Island (Tab between controls, Escape to close) |
| `Super + Shift + I` | Put the activity in the circle beside the Island on the Island |
| Volume and brightness keys | Change the level and show the OSD |
