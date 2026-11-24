# Architecture

This is a proposed implementation plan for Reef on **Quickshell (Qt 6 / QML)** and **Hyprland**. It's a starting point: adjust it as the code teaches you things. Quickshell's APIs change between versions, so check every module name against the docs for the installed version (`qs --version`, quickshell.org/docs) before relying on it.

## Principles

1. **Tokens are the single source of truth.** `design/tokens.json` is converted into QML singletons by `reef/scripts/gen-tokens.py` (run it after every token change). It covers color, type, spacing, radius, size, shadow and motion (springs, stagger, fades). No hex colors, radii, spacing values or durations may appear in component code.
2. **Colors are live.** The wallpaper drives the color scheme, which drives every surface. Changing the wallpaper re-themes Reef without a restart.
3. **Motion is centralized.** Every animation uses the `Motion` singleton (springs and curves from MOTION.md), multiplied by the Animation speed setting. Reduce motion swaps springs for short crossfades in one place.
4. **Shapes are reusable.** The M3E shapes (cookie-4/6/9, clover, sunny, flower, pill, circle) live in one `Shapes` module that can draw any of them and **morph** between them.
5. **Every feature has a setting** and can be enabled per monitor.
6. **Services are separate from UI.** System state lives in singletons under `services/`, and UI modules only bind to them.

## Layout

Built in M0 (✓) and planned:

```
reef/                         # the Quickshell config; symlink to ~/.config/quickshell/reef, run `qs -c reef`
  shell.qml                   ✓ ShellRoot: per-screen Variants, Commands, the dev window (LazyLoader)
  theme/
    Tokens.qml                ✓ GENERATED: spacing, radius, size, type, shadows, reference schemes, motion;
                                spacing/radius/type already include the Scale multipliers (raw* don't)
    ColorRoles.qml            ✓ GENERATED: one color property per role (base type of Colors)
    Colors.qml                ✓ live roles: Colors.primary, Colors.surfaceContainer, … and Colors.on.surface,
                                Colors.on.primary, … (QML reserves on<Name>, so "on-*" roles live under `on`)
    Motion.qml                ✓ spring specs, bezier fallbacks, speed, reduceMotion, shapeMorphs, stagger()
    Shapes.qml                ✓ M3E shapes as polar radius functions + mix() for morphing
    Type.qml                  ✓ FontLoaders (assets/fonts) + every style from tokens; Type.font(name, axes)
  components/
    Spring.qml                ✓ interruptible spring for one number (MOTION.md route 1)
    ColorSpring.qml           ✓ the same for colors (effects springs, no overshoot)
    MotionAnimation.qml       ✓ bezier fallback for Behaviors
    StyledText.qml            ✓ Text in a type style, with animatable wght/ROND/wdth
    Icon.qml                  ✓ Material Symbols Rounded; FILL animates with effects-fast
    ShapeItem.qml             ✓ draws one shape (QtQuick.Shapes, CurveRenderer)
    ShapeMorph.qml            ✓ morphs between shapes; crossfade with Reduce motion / morphs off
    Cay.qml                   ✓ a bar pill: width springs to its content, shadow-float
    CayButton.qml             ✓ round button inside a cay (hover tint, press squash, focus ring, label)
    Logo.qml                  ✓ the Reef mark from assets/logo, colored with a token
    EdgeFillet.qml            ✓ concave corner piece (screen corners, OSD; Tide panels next)
    WavyProgress.qml          ✓ M3E wavy progress with seek
    ShapeImage.qml            ✓ album art clipped to an M3E shape
    MiniWaveform.qml          ✓ five-bar cava waveform
    IconButton.qml  ButtonGroup.qml  Toggle.qml  Tile.qml  Slider.qml  Card.qml  TidePanel.qml
  modules/
    ScreenScope.qml           ✓ one per monitor; surfaces get added here
    Commands.qml              ✓ IpcHandler "reef" (run, dev, scheme, status) + GlobalShortcut "reef:<action>"
    frame/ScreenCorners.qml   ✓ rounded-screen overlay (no input, no reserved space)
    bar/                      ✓ Bar (PanelWindow, input mask = the cays), Dock, Navigator, Spotlight, Status
    island/                   ✓ Island (one morphing body), IslandState (singleton: activities in priority
                                order, swap, simulate), Activity (one activity's data), IslandActivity,
                                IslandPeek, NowTab, IslandTabs, IslandButton
    osd/                      ✓ edge OSD
    toasts/                   ✓ Toast window
    pearl/  controlcenter/  editmode/  search/  workspaces/  switcher/  power/  lock/  greeter/  polkit/
  services/                   # singletons
    Config.qml                ✓ ~/.config/reef/config.json (FileView + JsonAdapter, live reload, write-back)
    Scheme.qml                ✓ runs matugen, caches ~/.cache/reef/scheme.json
    Actions.qml               ✓ named actions shared by keybinds, IPC and buttons (stubs log their milestone)
    Workspaces  Apps  Audio  Network  Battery  Media  Time   ✓ (M1)
    Countdown  Recording  Brightness  Toasts  Visualizer     ✓ (M2)
    Privacy  Stopwatch  KeepAwake  BluetoothNotice           ✓ (M2 activities)
    Notifications  Bluetooth  Clipboard  Shelf  Coral  Wallpaper  Sounds
  dev/                        ✓ DevWindow (M0 inspector) + its small helpers
  settings/                   # Settings app (its own window / entry point)
  assets/fonts → ../../design/fonts (symlink)   assets/logo/ (copied from design/logo)
  scripts/                    ✓ gen-tokens.py, matugen.toml
hypr/
  reef.lua                    ✓ Hyprland snippet (gaps, rounding, start command, binds)
  tokens.lua                  ✓ GENERATED: spacing/radius values for reef.lua
```

## Key technical pieces

| Area | Approach |
| --- | --- |
| Windows | `PanelWindow` (layer-shell) per screen through `Variants`. The bar reserves its height with an exclusive zone. The Island, OSD and toasts use an overlay layer that **doesn't** reserve space. |
| Rounded screen | One overlay `PanelWindow` per screen anchored to all edges, with no input (empty mask), drawing four black concave corner pieces of `radius-xl`. |
| Tide panels | A `PanelWindow` anchored top, bottom and one side, full height, plus `EdgeFillet`s at the top and bottom of the inner edge. Content is a column of `Card`s. Use a focus grab (`HyprlandFocusGrab`) so a click outside closes the panel. |
| Hyprland | `Quickshell.Hyprland` for workspaces, the active window and `GlobalShortcut` keybinds (appid `reef`). Hyprland 0.57 is configured in **Lua**, so the snippet is `hypr/reef.lua`: load it with `dofile(…)`. It sets gaps (`gaps_in` = space-2, `gaps_out` = space-4) and `rounding` = radius-lg from the generated `hypr/tokens.lua`, starts `qs -c reef -n -d`, and binds keys to `hl.dsp.global("reef:<action>")`. |
| Colors | `services/Scheme` runs **matugen 4.x** (`matugen image <path> --prefer saturation --dry-run --json hex -t <type> -c scripts/matugen.toml`, or `matugen color hex <seed>` for a static color). One run returns both dark and light (`colors.<role>.dark.color`). Tinted = `scheme-tonal-spot`, Vivid = `scheme-vibrant`, Neutral = tonal-spot accents with `scheme-neutral` surfaces (two runs). The result is cached in `~/.cache/reef/scheme.json` so the next start is instant. `Colors.qml` falls back to the reference scheme in tokens, keeps the Island roles and scrim fixed, and crossfades every change with `effects-slow`. Writing GTK/Qt/kitty/Hyprland themes through matugen templates comes later. The wallpaper path is `look.wallpaper` in Config; Reef doesn't draw the wallpaper yet. |
| Audio | `Quickshell.Services.Pipewire` |
| Media | `Quickshell.Services.Mpris`. Pull the album art's color for `island-accent`. |
| Notifications | `Quickshell.Services.Notifications`. Reef **is** the notification server. |
| Tray | `Quickshell.Services.SystemTray`, shown inside the Status cay overflow. |
| Battery | `Quickshell.Services.UPower` |
| Network / Bluetooth | Quickshell's networking and Bluetooth modules if your version has them, otherwise `nmcli` and `bluetoothctl` through `Process`. |
| Lock | `WlSessionLock` plus `Quickshell.Services.Pam`. Idle handled with hypridle or Quickshell's idle support. |
| Greeter | greetd plus a Quickshell greeter (`Quickshell.Services.Greetd`), with its own entry point and the same theme. |
| Polkit | Quickshell's polkit agent if available, otherwise a small agent process that the UI talks to. |
| Clipboard | `cliphist` plus `wl-clipboard`. The Clipboard tab lists, searches and pins entries. |
| Shelf | Files and text dropped on the Island (`DropArea`) are kept in `$XDG_RUNTIME_DIR/reef/shelf` and dragged back out as file URIs. |
| Screenshot / recording | `grim` plus `slurp` (or `hyprshot`), and `wf-recorder` / `gpu-screen-recorder`. |
| Audio visualizer | `cava` (raw output) feeding the Pearl and the Island waveform. Its frame rate is capped by the performance setting. |
| Coral | An OpenAI-compatible HTTP client (streaming, configurable base URL, model and key). Optional voice: speech-to-text with whisper.cpp, text-to-speech with piper. Coral's "actions" (for example switching to Neutral) map to Reef IPC commands. |
| Sounds | Short sound files played through `pw-play` / `paplay`. Each category has its own toggle. |
| IPC | `IpcHandler` so scripts and keybinds can call `reef island open clipboard`, `reef power`, `reef panel controlcenter`, and so on. |

## Quickshell notes (0.3.2, checked 2026-11-23)

- Every module this plan names is in the installed build, including Bluetooth, Networking and Polkit, plus `IdleMonitor`, `IdleInhibitor`, `BackgroundEffect`, `ColorQuantizer` and `DesktopEntries`. No CLI fallbacks are needed.
- Imports use the config root as the `qs` module: `import qs.theme`, `import qs.services`, `import qs.components`.
- Singletons are created on first use, so a value read at startup may still be a default; bind to it rather than reading once.
- `FileView` creates missing parent directories when it writes. Its `loaded` stays false when a missing file is replaced by `writeAdapter()`, so `Config.loaded` is tracked separately.
- QML treats any name like `onSomething` as a signal handler: never name a property that way (hence `Colors.on.surface`).
- Fonts load straight from the `.woff2` files with `FontLoader`; `font.variableAxes` drives wght, ROND, wdth (Google Sans Flex) and FILL, GRAD, opsz (Material Symbols).
- matugen refuses to run without a config file that has a `[templates]` table, even with `--dry-run`.
- `Quickshell.Hyprland` fills in after it connects, and `Hyprland.usingLua` turns true then. In Lua mode, dispatches use Lua syntax: `hl.dsp.focus({ workspace = "3" })` (see services/Workspaces).
- `DesktopEntries` loads asynchronously and `byId()` isn't reactive: bindings that call it also read `DesktopEntries.applications.values.length` so they re-run.
- A layer surface gets keyboard focus only with `WlrLayershell.keyboardFocus`; pair Exclusive with `HyprlandFocusGrab` so a click elsewhere releases it, and arm the grab a moment after focusing, or Hyprland clears it at once.
- Debug service state with `qs -p ./reef ipc call reef status`.
- `transient` is a reserved word in QML; don't use it as a property name.
- To add an Island activity: add an `Activity { … }` to `IslandState.all` at its priority, bind `live` to a service, and add a toggle under `island.activities` in Config. The pill, peek, secondary pill and Now row follow.
- QML's JavaScript engine lacks some newer built-ins (`String.prototype.matchAll`); use `RegExp.exec` loops.
- The visualizer writes its cava config to `~/.cache/reef/cava.conf` and runs cava only while a waveform is visible and media plays.
- IPC: `reef run <action>`, `reef dev`, `reef status`, `reef scheme`, `reef timer <duration>`, `reef toast <text>`, `reef timerCancel`, `island open <tab>`, `island close`, `island toggle`, `island swap`, `island simulate <key>` (shows an activity with its current values, to check how it looks), `stopwatch start|pause|toggle|lap|reset`, `keepAwake on <duration>|off|toggle`. With more than one Reef running, target one with `qs ipc --pid <pid> call …`.

## Configuration

- User config lives in `~/.config/reef/config.json`. It's read and written by a `Config` singleton through `FileView` / `JsonAdapter` (or equivalent) and reloaded live.
- Settings groups match the Settings app:
  - **Look**: colorfulness, theme, transparency, seed or static color, home logo.
  - **Scale**: text, spacing and corner multipliers.
  - **Motion**: reduce motion, speed, Island hover reveal.
  - **Per monitor**: bar on/off, Island on/off, bar position.
  - **Performance**: blur, shape morphs, visualizer FPS.
  - **Sound** toggles.
  - **Coral**: endpoint, model, voice, keybind.
  - **Widgets and tile layout**, as saved by edit mode.

## Fonts

- Google Sans Flex (UI) and Google Sans Code (mono) are under the SIL OFL. Material Symbols Rounded is under Apache-2.0.
- Web copies are in `design/fonts/` for the HTML mockups. For the shell, install the TTF/variable fonts system-wide, either from the font projects' GitHub releases or from AUR packages such as `ttf-material-symbols-variable-git`.
