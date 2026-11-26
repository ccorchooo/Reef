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

- Separate pills, called **cays**, sit `space-2` (8px) apart and `space-2` above the bottom edge. Their order is a setting (`bar.cays`; edit mode's Bar card and Settings → Bar & Island, by dragging chips or with the arrow keys): the cays before the gap pack from the start of the bar, the rest from the far end, and a reorder slides into place. By default Dock, Navigator and Spotlight are at the start and Status at the end. Only the cays take clicks; the gaps between them click through. The bar reserves `cay-height` + `space-2`.
  - **Dock**: pinned and running apps, with icons from the user's icon theme (the colored tiles in the mockup stand in for them). A running app has a small dot under its tile; the focused app's tile sits on `secondary-container`. Click launches, focuses, or cycles that app's windows; middle-click opens a new window. Right-click (or the Menu key / Shift+F10 on a focused tile) opens the **app menu**. Until the pins are first edited, Reef pins the first installed terminal, file manager, browser, editor and music app.
  - **App menu** (also from search): an `app-menu-width` `surface-container-high` `radius-xl` card with `shadow-menu`, popping from the tile (above it, or to its right with the bar on the left; at the pointer in search) with `spatial-fast` scale and `effects-fast` fade. The app's icon and name, then Open (New window while it runs), the app's own desktop actions, **Pin to Dock / Unpin from Dock**, **Hide from search** (from search only) and Close window(s). Rows are `app-menu-row` with a hover state layer. Up/Down move, Enter picks, Escape or a click anywhere else closes it, and the keyboard goes back to the tile or the search field. Launching from it closes search; pinning and hiding keep search open.
  - **Navigator**: home (Reef logo), search, workspaces. The home button opens the home screen: the first empty workspace.
  - **Workspaces** (optional, Settings → Bar & Island → "Workspaces in their own cay"): the workspace numerals in their own cay, always shown, with the active one in the sliding `primary` pill; scrolling over it moves between workspaces. The Navigator then stays in its home form, and its grid button opens the overview.
  - **Spotlight**: the "special widget". It shows the first live thing of: **media** (artwork or a note on `tertiary-container`, title, artist, play/pause), a **timer** (remaining, pause/resume), the **stopwatch** (elapsed, pause/resume) and **today's next calendar event** (title and time, or "In 12 min" once it's within `event-soon`). Clicking it opens the Island or the calendar. With none live it shows its **default widget**: the weather (icon, temperature, condition) or system load (CPU, memory), or nothing, folding away. Each source and the default are in Settings → Bar & Island → Spotlight.
  - **Status**: the clock on the left, then a gap (at least `cay-status-split`), then the controls on the right: notifications bell, Wi-Fi (or wired), Bluetooth (with an adapter; it opens the Bluetooth menu; Settings → Bar & Island turns it off), volume, battery (hidden without one). **Clicking anywhere on it opens the control center.** The items aren't buttons: resting the pointer on the clock, network or volume icon for `menu-hover-delay` opens its quick menu (calendar, Wi-Fi, audio output) **inside the cay**, which grows up and out into a `radius-xl` card holding the menu above the row (see Quick menus). Scrolling over it changes the volume. The bell fills when there are notifications and turns to `notifications_off` with Do not disturb. With "Status menus on hover" off (Settings → Bar & Island), clicking an item opens its menu instead.
- Each cay is `cay-height` (40px) tall, `radius-full`, on `surface-container`, with `shadow-float`. In Frosted mode it sits on a blurred surface.
- **The Navigator cay re-forms in place** for each mode, using `spatial-default`:
  - **home**: the three icons.
  - **search**: the cay becomes the search field, and the results panel grows upward from it (`screens/Search.png`).
  - **workspaces**: workspace numbers 1–5, with the active one in a `primary` pill that slides between them (`screens/Workspaces.png`). Workspaces with windows use `on-surface` on a subtle `surface-container-high` circle, empty ones `on-surface-variant` with none; workspaces beyond 5 appear while they exist. Scrolling over the Navigator moves between workspaces and switches to this mode. **Holding Super** for `super-hold-delay` shows this mode until Super is let go (only here, not the overview; letting go after a hold doesn't open search).
  - **With the workspace overview open**, this mode shows and drives the overview's selection: the pill follows the overview as it moves, and clicking a numeral or scrolling over the Navigator moves the overview.
  - The **grid button** opens the workspace overview (and closes it again).
  - **power**: Lock, Log out, Sleep, Restart, Power off and Cancel. The Dock and Spotlight cays hide (`screens/PowerActions.png`).
- **Bar on the left** (`screens/BarLeft.png`; per monitor, Settings → Displays or edit mode's "Move bar to left"): the cays stack down the left edge `space-2` from it, with the Status cay at the bottom, and the bar reserves `cay-height` + `space-2` on the left. The Dock's tiles stack (the running dot sits on the edge side), the Navigator's forms stack (power buttons too, with the Power off tooltip to their right), the Spotlight cay is just the artwork over play/pause, and the Status cay is a column: the clock stacked as `09` over `41` in `bar-clock-vertical` with narrowed `wdth` 75 numerals, then network, volume, bell and battery. Search grows the Navigator out to the right (the field ends at the cay's bottom), and a Status quick menu grows the cay up and to the right above its column. Toasts then sit `space-4` above the bottom edge.
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
- The Island's accent (`island-accent`: Done, play, progress) follows the scheme: the dark scheme's `primary` in every theme, since the Island is always black.
- Inside the Island, containers use the island grays `island-container` (#1c1c1e) and `island-container-high` (#2c2c2e). Like `island`, they're fixed in every theme.
- Per monitor, the Island can be turned off on any monitor.

## The Pearl
Mockups: `parts/Pearl-States.png`, `parts/Pearl-Lock.png`, `screens/Lock.png`, `screens/CoralVoice.png`

- The Pearl is the round form of the Island: a soft 9-lobed cookie shape filled with `island` black by default. Settings → Lock screen changes its shape (the clock's shapes), its color (black, or the primary, secondary or tertiary container with its on-color) and its face. The same Pearl (`modules/lock/Pearl.qml`) sits on the lock screen and behind the power actions.
- **States:**
  - **Default (the face):** a digital clock with the date (the date can be turned off), an analog clock whose face is the Pearl (hands, ticks and numbers follow the clock widget's settings), or system stats in mono.
  - **Activity:** with "Show the current activity" on, it shows the Island's main activity instead (paused media too, so it can be resumed), with the time small on top:
    - **Media:** a small player: album art (cookie-12), title, artist, previous / play-pause / next, inside a progress ring in `island-accent` (the color's accent on a tinted Pearl).
    - **Timer:** the readout and its action inside a progress ring in `tertiary-container`.
    - **Anything else:** its icon, readout (or title and subtitle) and first action.
- **Alive:** it hops `pearl-hop` on the minute and when its activity changes (Settings can turn the hop off), stretching as it moves and squashing as it lands (`pearl-squash`), all on `spatial-bouncy`. On the lock screen it swells `pearl-pulse` with each typed character and rocks `pearl-wobble` on a wrong password.
  - **Coral speaking:** layered outline shapes that morph and pulse with the audio.
- The **Island → Pearl** morph uses `spatial-slow` (see MOTION.md).

## Lock screen
Mockup: `screens/Lock.png`

- Shows the wallpaper, with the Pearl in the center (its face, or the Island's main activity; media plays as a small player in the Pearl). No greeting.
- **Bottom-left:** the password field, a black pill where **each typed character appears as the next M3E shape** (circle, cookie-4, clover, sunny, flower…). Next to it is a small cay with Sleep, Power off and Restart.
- **Typing:** each shape pops up from below, spins in from `password-spin` and blooms from a circle into its shape (`spatial-bouncy`); the shapes beside it hop (`password-hop`, less with distance, staggered) on each character typed or erased.
- **Wrong password:** the shapes morph back to circles, shake with `spatial-fast`, and the field tints `error-container`.
- **Bottom-right:** network, battery and keyboard layout.
- Use `WlSessionLock` plus PAM. Fingerprint support is optional.
- **Closing the lid locks** (Settings → Lock screen → Lock when the lid closes). The laptop then sleeps the way logind is set (`HandleLidSwitch=suspend`, the default): Reef holds a logind sleep delay so the suspend waits until the lock covers every monitor, and the delay ends with the shell, so a crash never keeps the laptop awake.

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
- The selected row uses `secondary-container`. Up/Down (or Tab) move it, Enter opens it, Escape or a click elsewhere closes. Right-click an app (or press the Menu key / Shift+F10 on the selected one) for the app menu (see Bar → Dock). Apps hidden from search (the app menu or Settings → Apps) aren't listed. Typing `/` switches to commands: every built action (`/dnd`, `/nightLight`, `/controlCenter`, …) plus `/scheme`.
- A light `scrim` (`scrim` at `scrim-light`) dims the desktop behind it.

## Workspaces overview
Mockup: `screens/Workspaces.png`

- Opened with **Super+Tab**, the Navigator's grid button, or `panel toggle overview`.
- Like GNOME's: **the screen collapses into the card.** The overview waits (at most `overview-capture-wait`) until it has the windows' pictures, so its first frame is the screen itself: the card exactly over the screen with the windows live in it right where they are (`ScreencopyView`). Then it shrinks (`spatial-slow`) to the screen at `overview-scale`, a `radius-xl` card with a `primary` ring (`overview-ring`). Behind it the real screen shows through, blurred by the compositor and dimmed by the `scrim` at `scrim-light` as the card settles. Inside the card the wallpaper repeats (or `surface-container-lowest`). Closing grows the card back to the screen, and the overview is gone the moment it fills it (the spring's overshoot is never drawn).
- Going to a workspace or window waits `focus-handoff-delay` after the overview lets go of the keyboard, so Hyprland's refocus of the old window doesn't undo it. The Alt+Tab switcher does the same.
- The neighboring workspaces peek in at the left and right edges, `space-12` away. The bar stays in front, sharp and usable; its strip gets the same blur and scrim behind its cays, so the whole background reads as one layer with the bar over it.
- Going to a workspace grows its card into the screen from wherever it sits: the strip freezes, so nothing slides (clicking a neighbour goes straight there). The workspace switches under the card as it grows, and the card stays over the screen until Hyprland's workspace slide has ended (its length is read from `hyprctl animations`), so the slide is never seen.
- Below the card: the workspace number and its window count ("Empty" when it has none). Swipe, scroll, Left/Right or Tab move between workspaces (the card slides with `spatial-default`). Enter or a click on a card goes there; a click on a window focuses it. Escape, Super+Tab or a click on the background closes.
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

- Opened with **Ctrl+Alt+Delete**, the power button, or the power button in the header of the control center's Quick toggles card.
- The desktop is blurred by the compositor and covered with the heavy scrim (`scrim-heavy`'s alpha over the scheme's `surface-container`), with the Pearl where the big clock was (its face, or the Island's main activity, e.g. a small media player), the time, and the date and battery level. The Pearl comes out of the Island (which is gone while it's out) and goes back into it; locking from here hands it on to the lock screen.
- The Navigator cay re-forms into the power actions. On hover, **Power off** turns `error-container` and shows a tooltip.

## Home widgets
Mockups: `screens/Home.png`, `screens/BarLeft.png`

- Widgets sit on a bottom-layer surface over the wallpaper (under windows), inside the free desktop (clear of the bar). Each monitor keeps its own layout (`home.layouts.<output>` in Config); a monitor without one shows the default layout from the mockup, starting `widget-inset` from the left and `widget-inset-top` from the top. Settings → Displays → "Home widgets" turns them off per monitor.
- **Clock**: the analog clock, `widget-clock-size`, on `surface-container-high` by default. Settings → Widgets changes its shape (circle, squircle, cookies, sunny, flower, clover, pentagon), numbers (none, 12 3 6 9, all twelve in `clock-numeral`, or the current hour large behind the hands in `clock-backdrop` at `clock-backdrop` opacity: decorative, the clock's accessible name gives the time), face color (surface, primary, secondary or tertiary container, with hands and numerals in its on-color), hour ticks and a second hand.
- **Weather**: a `widget-weather-size` 12-sided cookie on `tertiary-container` with the condition icon, the temperature in `widget-temperature` (ROND 100) and the description. From wttr.in through `curl` every `weather-refresh` while shown; the place is Settings → Bar & Island → "Weather location" (empty: guessed from the IP address), °C or °F.
- **Media**: a `widget-media-width` × `widget-media-height` `radius-2xl` squircle on `primary-container`: the artwork in a 4-leaf clover, title, artist, wavy progress (seekable) and a `radius-play` play/pause button. "Nothing playing" without media.
- **System**: a `radius-xl` card on `surface-container-high` with CPU, memory and GPU temperature in `widget-stat` mono over thin `primary` meters, read every `stats-refresh` while shown (GPU from nvidia-smi or the GPU's hwmon; the row hides without one).
- **Calendar**: the calendar quick menu's month and next event on the same card as System.
- Reef can also draw the wallpaper itself (Settings → Look → "Draw the wallpaper", off by default so another program can): a background-layer surface with `look.wallpaper`, crossfading on change.

## Edit mode (Tide panel, left)
Mockup: `screens/EditMode.png`

- Opened with **Super+E**, Settings → Bar & Island → "Edit home", or `panel toggle editMode`. It shows the home screen: when the monitor's workspace has windows, it goes to the first empty workspace and comes back afterwards (the Navigator's home button does the same). Full height and `edit-panel-width` (320px) wide, with fillets on its right edge; it slides in from the left with `spatial-default` and pushes the bar and the home widgets aside by its width. It holds the keyboard; **Done**, Escape or Super+E leave.
- It has four cards:
  1. A header with "Edit mode" and a **Done** button.
  2. **Home widgets**: thumbnails (`edit-thumb-height`, two columns, Media across both) for Clock, Weather, Media, System and Calendar. Click one (or Enter) to add it near the top-left, or drag it onto the desktop to drop it there.
  3. **Control center**: the quick toggles in their four-column layout as small `edit-tile-height` tiles, on `primary-container` pills when on. Drag one to a new place (the others make room as it moves) or move the focused one with the arrow keys; the control center follows (`controlCenter.tiles`).
  4. **Bar**: "Move bar to left" (or back to the bottom) for this monitor, "Show Spotlight cay", and "Bar on other monitors".
- On the desktop an `edit-scrim` of black dims the wallpaper, and widgets get a dashed `primary` outline `edit-outline-gap` outside their shape, a remove badge on the outline's top-left, and a slight wiggle (`edit-wiggle` degrees over `edit-wiggle-period`; off with Reduce motion or Settings → Bar & Island → "Wiggle while editing"). Drag a widget to move it anywhere inside the free desktop: it follows the pointer, dots show the `home-grid` it snaps to, and a `primary`-tinted outline shows the cell it will land in; let go and it springs there. The Island shows "Editing home · Done" (`island-editing-width` × `island-banner-height`), even over apps.

## Coral (AI assistant)
Mockups: `screens/CoralVoice.png`, `parts/Island-Coral.png`

- **Voice (M8):** Super+C (or the chat's mic and voice buttons, `ipc call coral voice`). The Island leaves the top center as the pill and grows into the Pearl (`pearl-size`, `spatial-bouncy`); the Island hides meanwhile. The Pearl pulses: three `island-accent` outlines (`coral-outline`) grow with the voice's loudness (yours while listening, Coral's while speaking, beat kicks while it writes down or thinks) up to `coral-pulse`, turn and morph between cookie shapes on the beat, and brighten from `coral-outline` opacity to full at the peaks. Coral's mark sits on a dark disc at the center. Below it, on black chips so they read over any wallpaper: "Coral · listening / writing it down / thinking / speaking" in `label-md` caps, the transcript in quotes (`body-lg`, at most `coral-transcript-width`; whisper.cpp writes it down once you stop, so it appears then rather than word by word), and **Type instead** and **Stop** (`error-container`). Listening ends by itself after a pause (Settings → Coral), or with Stop; Escape cancels. The reply is spoken in a voice for the language you used.
- **Wake word (M8):** "Hey Coral" or "Oye Coral" (also "ok", "hola") starts voice mode; anything said after it in the same breath is the request. Off by default (Settings → Coral → Wake word), never while locked or during voice mode. It's checked on this computer (whisper's tiny model, kept loaded) or in the cloud (each short burst of speech goes to the cloud service; Settings says so). Its microphone stream is named "Reef wake word" and is left out of the Island's microphone-in-use activity, which would otherwise never leave the Island.
- **After a reply:** Coral keeps listening a few seconds for a follow-up (Settings → Coral → Keep listening after a reply), then the Pearl folds back into the Island. The Island doesn't open by itself or take the keyboard: the reply waits as Coral's "Replied" activity, and the chat card opens from it, from Type instead, or on its own only when something went wrong. The card shows the reply, action buttons Coral can offer (for example "Switch to Neutral"), and an "Ask a follow-up…" field with mic and send buttons.
- **Chat (built, M8):** the Island's Coral tab (Super+C, search's "Ask Coral…", `ipc call coral ask "…"`). Header: Coral's mark (it hops round on `spatial-bouncy` while Coral thinks or replies), the name in `title-md-emphasized`, the model and where it runs (`local`, or the host) in `mono-sm`, and New conversation and Close. Questions sit right in `island-container-high` bubbles (`coral-bubble-radius`, `coral-bubble-tail` by the edge, at most `coral-bubble-width`); replies on the black in Markdown, at most `coral-reply-width`, with three hopping dots before the first word. Under a reply, the actions Coral offers (the first in `island-accent`); they run only when pressed. The conversation scrolls past `coral-chat-max-height` and follows a streaming reply. The Ask field ("Ask Coral…", then "Ask a follow-up…") ends in a `radius-md` accent send button that becomes Stop while Coral answers. Errors show in `error` with Open Settings.
- **Activity:** while Coral thinks or replies, and when a reply arrives unseen, the Island shows it (Thinking / Replying / Replied; Settings → Bar & Island can turn it off). The peek's action opens the chat.
- **App (M8):** Super+Shift+C, search's "Coral", the open button in the Island's Coral tab, `ipc call coral app`. A normal window like Settings (`coral-app-width` × `coral-app-height`, inside the screen). Sidebar on `surface-container` (`settings-nav-width`): New conversation on `primary-container`, Search conversations (titles and messages), then the conversations under Today / Yesterday / Previous 7 days / Older, the current one on `secondary-container`; double-click (or F2) renames, the bin turns to "Delete for good" for 3 s. The conversation on `surface-container-low`, its column at most `coral-app-column`: a header (the title in `card-title`, the model menu: Default or any chat model the endpoint lists, with where it runs, in `mono-sm`), then the messages: questions on the right in `surface-container-high` bubbles (at most `coral-app-bubble-width`) with their images (`coral-app-thumb` squircles) and file chips above; replies in Markdown, selectable, with what the model thought folded above ("Thought it through"), the actions Coral offers, and Copy / Regenerate / the model under them; questions get Copy and Edit (edit asks again from there). Empty: Coral's mark, "What can I help with?" and four starting points. The composer (`radius-xl` card): attachments (thumbnails or chips, removable), the question (grows to `coral-composer-max`; Enter asks, Shift+Enter a new line), Attach, Speak and Send / Stop. Files can be dropped anywhere on the window. Ctrl+N starts a new conversation, Escape stops a reply. Conversations are shared with the Island's Coral tab and voice mode, and the model names each one after its first reply.
- **Settings → Coral:** where each part runs (Chat, Listening, Speaking: "This computer" or "Cloud", segmented buttons); the cloud (endpoint, API key in a hidden field that's saved privately and never shown back, with Forget the key; or an environment variable; chat, speech-to-text and text-to-speech models and the voice); this computer (local server and model); Offer actions; and voice (on/off, Speak replies, listening language Detect / Español / English, what's missing, Look again). Coral works with any OpenAI-compatible service, local or cloud; with no model set it uses the service's first chat model.

## Settings app
Mockup: `screens/Settings.png`

- A normal window (`settings-width` × `settings-height` times the zoom, kept inside the screen; `hypr/reef.lua` floats and centers it, and Hyprland draws its rounding and border) with a `settings-nav-width` sidebar on `surface-container` listing: Look, Displays, Bar & Island, Apps, Widgets, Sound, Network, Bluetooth, Coral, Keyboard & shortcuts, Power & performance, Accessibility, and About. The sidebar scrolls when it doesn't fit. Changing the zoom while Settings is open resizes the window to match, and two-column choices stack into one below `settings-two-column-min`. The current page is a `secondary-container` pill. Above them, "Search settings" lists the matching settings across pages; picking one opens its page. A close button sits top-right.
- Opened with the `settings` action (`/settings` in search), `qs -p ./reef ipc call reef settings <page>`, and the quick menus' "… settings" buttons (which open the matching page). Inside Settings those menus' buttons open the advanced tools instead (nm-connection-editor, blueman, pavucontrol).
- Pages put their settings on `surface-container-high` `radius-xl` cards under `settings-section` labels; every change is saved to Config at once.
- **Look page:**
  - A wallpaper card with a preview, seed color swatches (the wallpaper's most colorful colors), "Change wallpaper" (a file dialog), and "Use static color" (or "Use wallpaper colors" while a static color is set).
  - **Palette**: `settings-palette-card` option cards: Wallpaper (its seed colors as dots) and each classic palette (its accents on its own surface, in the current mode).
  - Button groups for **Colorfulness** (Mono / Neutral / Tinted / Vivid / Deep; with the Wallpaper palette only), **Theme** (Auto / Light / Dark), and **Transparency** (Solid / Frosted). The selected option is a filled `primary` pill with a check.
  - **Home logo**: Reef / Distro logo / Custom image (`radius-option` cards, the chosen one ringed in `primary`). The choice shows on the Navigator's home button and the lock screen.
  - "Draw the wallpaper".
- **Displays:** per monitor: bar (and its position), Island, home widgets, rounded corners; Night light and its warmth.
- **Bar & Island:** the bar's switches, workspace count and clock format; the Island's peek, hiding over apps, recording detection and drops; each activity; home (Edit home, Reset widgets, wiggle, weather location and unit); notifications, OSD and toasts; clipboard size, file search, focus lengths and calendars.
- **Apps:** **Default apps**: one row per kind (web browser, files, terminal, email, text editor, images, videos, music, PDF) with the current app; a row opens the apps that can handle it as pills, the chosen one on `primary-container`. **Dock**: the pins in order, each with move earlier / later and unpin. **Apps in search**: a filter field, then every app with a pin button and a "Show in search" switch (the first 40 until "Show all").
- **Widgets:** the clock's live preview, then hour ticks, second hand, numbers, face color and shape.
- **Lock screen:** the Pearl's live preview on the wallpaper (show the current activity, date, hop on the minute, Preview lock screen), then its face (clock, analog, system), color (black, primary, secondary, tertiary) and shape; the status and power buttons; locking (when the lid closes, before sleep).
- **Sound, Network, Bluetooth:** the matching quick menu, plus the microphone on Sound.
- **Coral:** endpoint, model, the environment variable holding the API key (the key itself is never stored), voice. Coral arrives in M8.
- **Keyboard & shortcuts:** the layout and the default shortcuts.
- **Power & performance:** the authentication dialog, the low-battery level, blur, shape morphs, the visualizer and its frame rate, live thumbnails.
- **Accessibility:** Reduce motion, animation speed, **Zoom** (75–150%: the whole shell, sizes, spacing, corners and text together), text size, spacing and corner roundness.
- **About:** the Reef lockup, the system, Quickshell and Hyprland versions, and where the settings file lives.

## Keybinds (defaults)

| Keys | Action |
| --- | --- |
| `Super` (left or right, tapped alone) | Search |
| `Super` (held) | Show the workspaces in the bar |
| `Super + V` | Island → Clipboard |
| `Super + .` | Island → Tools (emoji) |
| `Super + C` | Coral (voice; the Island chat until voice is set up) |
| `Super + Shift + C` | The Coral app |
| `Super + N` | Control / notification center |
| `Super + Tab` | Workspace overview |
| `Alt + Tab` (hold Alt) | Window switcher; `Alt + Shift + Tab` steps back |
| `Super + E` | Edit mode (Done, Escape or Super+E again to leave) |
| `Super + L` | Lock |
| `Ctrl + Alt + Delete` | Power actions |
| `Super + B` | Keyboard focus to the bar (Tab between controls, Escape to leave) |
| `Super + I` | Open or close the Island (Tab between controls, Escape to close) |
| `Super + Shift + I` | Put the activity in the circle beside the Island on the Island |
| Volume and brightness keys | Change the level and show the OSD |
