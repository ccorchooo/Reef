# Reef

**A desktop that moves like it's alive and looks like it was made with care.**

Reef is a full desktop environment built on Quickshell and Hyprland. It takes its motion and shapes from Material 3 Expressive and its restraint from Apple: playfulness goes into **how things move and what shape they take**; **color and density stay calm**. Everything is a setting, so a user can make Reef louder, quieter, or lighter on weak hardware.

This book is the source of truth for anyone (person or agent) building a Reef surface. Tokens live in [`design/tokens.json`](../design/tokens.json). Motion is in [MOTION.md](MOTION.md), surface-by-surface behavior in [SURFACES.md](SURFACES.md), and the implementation plan in [ARCHITECTURE.md](ARCHITECTURE.md).

---

## 1. Vocabulary

Reef's components are named after the sea. Use these names in code, settings and UI copy.

| Name | What it is | Notes |
| --- | --- | --- |
| **Reef** | The desktop environment | Always capitalized, never "ReefDE" in UI. |
| **The Island** | The black pill at the top center | Reef's take on the Dynamic Island: live activities, the Shelf, quick tools, and Coral. |
| **The Pearl** | The round form the Island morphs into | Lock screen centerpiece and Coral's voice mode. Shows the current activity or a default display (clock, weather, performance). |
| **Coral** | The AI assistant | Lives in the Island. Speaks through the Pearl's wave pulse. Endpoint and model are chosen in Settings. |
| **Cays** | The separate pill segments of the bar | *Proposed name* (a cay is a small island on a reef). The bar is four cays: **Dock**, **Navigator** (home, search, workspaces), **Spotlight** (the special widget) and **Status** (clock and tray). |
| **The Shelf** | A tab of the Island | Temporary holding area for dropped files, images and text. |
| **Tide panels** | Panels that hug a screen edge | Control/notification center and edit mode. |

## 2. Principles

1. **Alive.** Something always responds. Hover, press, drag and state changes all get spring motion or a shape morph, never a hard cut (unless Reduce motion is on).
2. **Premium.** Color is used like Apple uses it: one accent does the work, surfaces stay quiet, text is high-contrast, and spacing is generous and consistent. Nothing glows unless it is live.
3. **Sharp.** Hierarchy reads at a glance. Every element sits on the 4px grid, corners are concentric, and type has clear steps. Playful never means sloppy.
4. **Playful in the right places.** Shapes from the M3E library appear where a moment benefits from character: password dots, toggles, the Pearl, home widgets, loading states. Body text, lists and settings stay calm.
5. **Everything is a choice.** Colorfulness, transparency, motion, sounds, which monitors get the bar or the Island, and the logo are all settings. Defaults are opinionated; overrides are first-class.

## 3. Color

### Source
All roles are generated from the wallpaper with Material color utilities (matugen or equivalent) every time the wallpaper changes. The values in `tokens.json` are the **reference scheme** from seed `#e8735a` (coral), used when there is no wallpaper or the user picks **Static**.

### The Colorfulness setting
| Setting | Surfaces | Accents | Feels like |
| --- | --- | --- | --- |
| **Neutral** | Neutral variant (`*-neutral` themes) | Wallpaper accent kept | macOS: quiet gray glass with one color |
| **Tinted** *(default)* | TonalSpot (`dark`, `light` themes) | Wallpaper accent | Reef's signature: warm surfaces that echo the wallpaper |
| **Vivid** | Vibrant or Expressive scheme variant | Stronger, uses tertiary more | Pixel at full volume |

Light/dark: **Auto** (follows sunset/sunrise or a schedule), Light, or Dark.

### Rules
- **One accent per view.** `primary` marks the active thing: the selected workspace, an ON toggle, focus. If two things are `primary`, one of them is wrong.
- Containers carry state: `secondary-container` for hover and selection, `primary-container` for the main action in a group.
- `tertiary` is for delight: Coral's wave, timers, the Shelf badge. Never more than one tertiary element on screen at rest.
- **The Island is always black** (`island`) with `on-island` text, in every theme. It should look like there is no screen there. Its live accent is `island-accent`, which media can override with the album art's dominant color.
- Text: `on-surface` for primary, `on-surface-variant` for secondary. Every pair meets 4.5:1 in all four themes (checked: lowest is on-surface-variant on surface-container-high, 5.2:1 in light).
- Transparency is a setting: **Solid** *(default)*, or **Frosted**, which uses Hyprland blur behind cays and Tide panels at about 85% surface opacity. The Island is never frosted.

## 4. Shape

Reef uses shape the way M3 Expressive does: **shape signals state and personality**.

- **Corner scale** comes from `radius-*`. Cays, buttons and ON toggles use `radius-full`, cards use `radius-lg`, and panels and widgets use `radius-xl`.
- **Concentric corners.** An inner element's radius = the outer radius minus the padding between them. Example: a `radius-xl` (28px) widget with `space-3` (12px) padding holds children at 16px (`radius-lg`). This single rule does most of the "Apple elegance" work.
- **Hyprland matches.** Window rounding uses `radius-lg`; `gaps_in` = `space-2`, `gaps_out` = `space-4`, so windows and cays share one rhythm.
- **The screen itself is rounded.** Reef masks the display corners with `radius-xl` (28px), so the desktop reads as one rounded sheet.
- **Tide panels are part of the screen.** The control/notification center and edit mode run the full height of the screen with no shadow. Their outer corners are the screen's own corners, and where their inner edge meets the top and bottom of the screen they flare out with **concave 28px fillets**, so the desktop beside them reads as a rounded sheet. The panel itself is `surface-container-low`, and every section inside it (notifications, quick toggles, sliders, each edit-mode group) sits on its own `surface-container` card (24px corners, 10px gaps), never on dividers.
- **Edge OSDs grab the screen too.** Shorter things attached to an edge (the volume and brightness OSD) meet it with the same concave fillets and use `radius-xl` on their free corners. The OSD shows only the bar and icon, no number.
- **The M3E shape library is used almost everywhere**, with purpose:
  - **Password field:** each typed character appears as the next shape in a fixed sequence (circle, 4-sided cookie, clover, sunny, pentagon, gem…) and pops in with a fast spatial spring. A wrong password morphs them all back to circles and shakes.
  - **Toggles and tiles:** at rest a squircle (`radius-lg`); ON morphs to a pill (`radius-full`) and fills with `primary-container`.
  - **Pressed buttons** squash their corners toward the next smaller radius, then spring back.
  - **Home widgets** choose their container shape from the library: circle for the clock, 12-sided cookie for weather, squircle for media. Edit mode lets users change it.
  - **The Pearl** rests as a soft cookie shape and morphs between shapes with the audio (see Motion).
  - **Loading:** the M3E loading indicator, which morphs through shapes instead of spinning a ring.
- **Not here:** list rows, text fields and notification cards keep plain rounded rectangles, so reading stays calm.

## 5. Type

- **Google Sans Flex** for everything in the UI. Use its axes, not just weights:
  - `wght` animates on interaction: a pressed label goes from 500 to 700 with a fast effects spring.
  - `ROND` (roundness) at 0 for body text (sharp), raised to about 50–100 on playful surfaces (the Pearl, home widget numerals, Coral's name).
  - `wdth` narrows numerals in tight spots, such as the vertical clock when the bar is on the left.
- **Google Sans Code** (mono) for keybind hints, the calculator, clipboard entries, IPs, performance stats and Coral's code blocks.
- **Emphasized** styles (`*-emphasized`) are for the moment something changes: a confirmation title, the Island's primary line, the selected item.
- **Numerals** styles are for clocks and big readings only; they never hold words.
- Global **Text size** scale in Settings multiplies every style.

## 6. Iconography

- **Material Symbols Rounded**, variable. Defaults: `wght 400`, `GRAD 0`, `opsz` matching the size (20 in cays, 24 in the Island and panels).
- **FILL 0 → 1 means active.** An inactive Wi-Fi icon is outlined; when it's on, it fills, animated over the fast effects spring.
- Icons sit on `on-surface-variant` at rest and `on-surface` or `on-primary-container` when active.
- No other icon sets in shell chrome. App icons come from the user's icon theme.

## 7. Logo

**The Reef mark is an atoll.** A single ring whose outer edge is a 6-lobed M3E cookie shape and whose inner edge (the lagoon) is a perfect circle, with a channel cut through it at the upper right. The soft outside against the precise inside is Reef in one glyph: playful shape, sharp structure. The channel echoes the gaps between the bar's cays.

Files are in [`design/logo/`](../design/logo/):
| File | Use |
| --- | --- |
| `reef-mark-color.svg` | Light backgrounds. Ring `#c9523a` (4.2:1 on the light surface). |
| `reef-mark-on-dark.svg` | Dark backgrounds and the Island. Ring white. |
| `reef-mark-mono.svg` | One ink (black). For print, stencils, and recoloring in code. |

Rules:
- **It's one color.** In the shell, color it with a token rather than the files' fixed colors: `primary` on surfaces, `on-island` inside the Island, `on-primary-container` on the Navigator cay's home button. That way the mark follows the wallpaper.
- **Minimum size 16px.** It was checked at 20px in the Navigator cay.
- **Clear space** around it is at least the channel's width (about a quarter of the mark).
- **The channel stays at the upper right.** Don't rotate, mirror or outline the mark, and don't put anything in the lagoon.
- **Lockup:** the mark plus the "Reef" wordmark in Google Sans Flex 600, with letters 0.9× the mark's height and a gap of half the mark's width between them. Use it on the boot splash and in Settings → About.
- **Motion:** at boot the ring draws itself clockwise from the channel with `spatial-slow`, then its lobes "breathe" once (an M3E shape morph). With Reduce motion on, it simply fades in.

Setting: **Home logo** = Reef mark *(default)* · distro logo (from `/etc/os-release` `LOGO`) · custom image. The choice applies to the Navigator cay, the lock screen and the boot splash.

## 8. Sound

Sounds are **very subtle**, short (under 150 ms) and soft, at low volume, with one master toggle and per-category toggles. Planned sounds: lock and unlock, power menu open, Island expand, a file landing on the Shelf, Coral starting to listen, Coral finishing a reply, notification (only when Do not disturb is off). Never a sound on hover.

## 9. Voice (UI copy)

- Short, plain and friendly. Use sentence case everywhere ("Do not disturb", not "Do Not Disturb").
- Address the user by name only on the lock screen greeting.
- Buttons are verbs: "Power off", "Restart", "Add to Shelf".
- Coral speaks in the first person, briefly, without emoji.
- **No how-to text in menus.** Don't explain gestures or shortcuts inside panels, switchers or dialogs ("release to switch", "drag a widget here"). Keybinds live in Settings → Keyboard & shortcuts.

## 10. Settings that shape the design

| Area | Settings |
| --- | --- |
| Look | Colorfulness (Neutral / Tinted / Vivid), Light/Dark/Auto, Transparency (Solid / Frosted), Static seed color, Home logo |
| Scale | Text size, Spacing, Corner roundness (multipliers on the tokens) |
| Motion | Reduce motion, Animation speed multiplier, Island hover reveal on/off |
| Per monitor | Show bar, show Island, bar position (bottom / left) |
| Performance | Disable blur, disable shape morphs (use crossfades), lower Pearl frame rate, disable the audio visualizer |
| Sound | Master toggle, per-category toggles |
| Coral | API endpoint, model, voice on/off, wake keybind |
