# Reef

**A desktop that moves like it's alive and looks like it was made with care.**

Reef is a full desktop environment built with **Quickshell** on **Hyprland**. It takes its motion and shapes from **Material 3 Expressive** and its restraint from **Apple**: the playfulness goes into how things move and what shape they take, while color and density stay calm. Colors come from the wallpaper (like Caelestia), but Reef has its own identity.

![Home](design/mockups/screens/Home.png)

## The pieces

| Name | What it is |
| --- | --- |
| **Reef** | The desktop environment |
| **The Island** | A black pill at the top center for live activities (media, timers, recordings, notifications) with tabs: Now, Shelf, Clipboard, Tools, Coral |
| **The Pearl** | The round form the Island morphs into: the lock screen centerpiece and Coral's voice mode |
| **Coral** | The built-in AI assistant, working with any OpenAI-compatible endpoint, including local models |
| **Cays** | The four separate pills that make up the bar: Dock, Navigator, Spotlight, Status |
| **Tide panels** | Full-height panels attached to a screen edge: the control/notification center and edit mode |
| **The Shelf** | A temporary holding area for files and text, inside the Island |

## Repository map

```
README.md            ← you are here
CLAUDE.md            ← working agreement for Claude Code
docs/
  DESIGN.md          ← brand book: principles, color, shape, type, icons, logo, sound, voice
  MOTION.md          ← M3 Expressive springs, choreography, signature moments, reduce motion
  SURFACES.md        ← every surface's behavior + global rules (rounded screen, Tide panels, …)
  ARCHITECTURE.md    ← proposed Quickshell/Hyprland implementation, services, config
  ROADMAP.md         ← milestones M0–M9
design/
  tokens.json        ← color roles (4 themes), type, spacing, radius, size, shadow
  logo/              ← Reef mark (atoll ring) – color, on-dark, mono SVGs
  fonts/             ← Google Sans Flex, Google Sans Code, Material Symbols Rounded (web, for mockups) + licenses
  mockups/           ← refined mockups: screens/ and parts/ (PNG), html/ (static HTML), README index
mockup/              ← original hand-drawn Excalidraw flow + images
reef/                ← the Quickshell config (shell.qml; greeter.qml is the login greeter)
hypr/                ← Reef's Hyprland snippet (reef.lua: start, Reef's keys), tokens.lua, check-binds.lua
  config/            ← the whole Hyprland config around Reef (installed as ~/.config/hypr)
config/              ← kitty, fastfetch, starship, fish and bash hooks
greeter/  session/   ← greetd + the greeter's Hyprland; the Reef session entry and launcher
bin/reef             ← the CLI: install, update, doctor, uninstall, greeter-sync, …
install.sh           ← runs `bin/reef install`
packaging/arch/      ← PKGBUILD for reef-git
```

## Status

**M0–M4 are done**: tokens, live colors, motion, type, icons, shapes, config, a dev window (`qs -p ./reef ipc call reef dev`), the rounded screen, the four-cay bar, the Island (live activities, peek, Now tab, notifications), the floating OSD, toasts, the control center and quick menus. M4 is done too: search (tap Super), the workspace overview (Super+Tab) and the Alt+Tab switcher. M5 (lock, power actions, polkit), M6 (Island tabs) and M7 (edit mode and home widgets, the bar on the left, the Settings app: `qs -p ./reef ipc call reef settings`) are built and waiting on hands-on checks. M9 is built and waiting on hands-on checks: sounds, Vivid, performance mode, multi-monitor fixes, an accessibility pass and an installer; Frosted comes later. See [docs/ROADMAP.md](docs/ROADMAP.md).

## Install

On Arch (Hyprland 0.57+, Quickshell 0.3.2+):

```bash
git clone https://github.com/ccorchooo/Reef && cd Reef
./install.sh            # asks before each big step; --yes takes the defaults, --dry-run shows the plan
```

That installs **the whole desktop**, not just a link:

- **Packages** through pacman and your AUR helper (paru or yay): Hyprland, Quickshell, portals, PipeWire, NetworkManager, Bluetooth, power profiles, clipboard, screenshots and recording, kitty, fastfetch, starship, fonts and themes.
- **The shell** in `/usr/share/reef` (also read by the greeter and the session), linked from `~/.config/quickshell/reef`, and Reef's fonts for every app.
- **Hyprland's config** as `~/.config/hypr`: Reef's gaps, corners and springs, borders that follow the wallpaper, rules, gestures, and **Caelestia's key layout** (Super+Return terminal, Super+Q close, Super+E files, Super+W browser, Super+C editor, Super+1…0, Super+S/M/D/R special workspaces, Print, Ctrl+Alt+R recording…). No two binds share a key (`reef doctor` checks). Your keyboard layout, monitors and cursor come along; your changes go in `~/.config/hypr/user/` and are never replaced. Coral is **Super+A** and edit mode **Super+Shift+E**.
- **A terminal that belongs:** kitty, see-through and blurred, in Google Sans Code, with its colors (and the 16-color palette) following the wallpaper live; a **starship** prompt in rounded pills like the bar's cays; and a **fastfetch** greeting with the Reef mark.
- **The session:** NetworkManager, Bluetooth, power profiles and PipeWire enabled, the **Reef** session in your login screen, and (if you want it) **Reef's login greeter** on greetd, with your colors and wallpaper. Idle locks, turns the screens off and sleeps (Settings → Power & performance).

Everything replaced is kept beside it as `*.reef-bak.<date>`. Afterwards:

```bash
reef doctor             # what's missing or wrong (programs, config, keybinds, services)
reef update             # pull the latest Reef and refresh it; files you edited are left alone
reef binds              # every keybind
reef uninstall          # remove Reef and put back what it replaced
```

`./install.sh --link` points your config at the checkout so edits apply live (for working on Reef). On Arch, `packaging/arch/PKGBUILD` builds `reef-git`; then run `reef install --no-packages` as yourself.

## Design at a glance

- **Color:** M3 roles generated from the wallpaper. A **Colorfulness** setting offers Mono, Neutral, Tinted (the default), Vivid or Deep (pure black with one accent), and a **Palette** setting swaps the wallpaper for a classic palette (Gruvbox, Catppuccin, Nord, …). Light, Dark or Auto. The Island is always pure black.
- **Shape:** the screen corners are rounded. Corners follow the M3 scale and nest concentrically. M3E shapes appear across the UI: password dots, toggles, widgets, the Pearl.
- **Type:** Google Sans Flex, with variable axes for motion. Google Sans Code for mono text. Material Symbols Rounded for icons.
- **Motion:** M3 Expressive springs, interruptible, with Reduce motion and an animation speed setting.
- **Everything is a setting**, including per monitor.
