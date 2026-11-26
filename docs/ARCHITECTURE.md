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
    EdgeFillet.qml            ✓ concave corner piece (screen corners, Tide panels)
    WavyProgress.qml          ✓ M3E wavy progress with seek
    ShapeImage.qml            ✓ album art clipped to an M3E shape
    MiniWaveform.qml          ✓ five-bar cava waveform
    Card  Tile  ExpressiveSlider  Switch  Chip  ListRow  MenuButton   ✓ (M3)
    ButtonGroup.qml           ✓ M3E button group: shared width, the pressed one widens
    WindowThumb.qml           ✓ a window's live picture (ScreencopyView), rounded, icon fallback
    PasswordField.qml         ✓ (M5) black pill; each character a shape, pop-in, wrong-password shake + tint
    PillButton.qml            ✓ (M5) full-width dialog button (Cancel, Authenticate)
    AnalogClock.qml           ✓ (M5) the power-actions clock (and the clock home widget)
    SwitchRow  SegmentedButtons  SliderRow  TextFieldRow   ✓ (M7) settings rows, shared by edit mode
                                and Settings; SettingsSection (label + card), OptionCard (Home logo)
    HomeLogo.qml              ✓ (M7) Reef mark, distro logo or custom image (Settings → Look)
    IconButton.qml  Toggle.qml  Slider.qml  TidePanel.qml
  modules/
    ScreenScope.qml           ✓ one per monitor; surfaces get added here
    Commands.qml              ✓ IpcHandler "reef" (run, dev, scheme, status) + GlobalShortcut "reef:<action>"
    frame/ScreenCorners.qml   ✓ rounded-screen overlay (no input, no reserved space)
    bar/                      ✓ Bar (PanelWindow, input mask = the cays; places the cays from BarCays.order), Dock,
                                Navigator, Spotlight, Status (grows into a quick menu), StatusItem
                                (M7) WorkspacesCay + WorkspaceNumbers (shared with the Navigator), BarCays
                                (singleton: the saved cay order), CayOrder (drag-to-reorder chips),
                                AppMenu (right-click a Dock tile or a search app: pin, hide, actions)
    island/                   ✓ Island (one morphing body), IslandState (singleton: activities in priority
                                order, swap, simulate), Activity (one activity's data), IslandActivity,
                                IslandPeek, NowTab, IslandTabs (circles), IslandActivities + ActivityRow
                                (the pill under the expanded Island), IslandButton
                                (M6) ShelfTab, ClipboardTab, ToolsTab (calculator, emoji, color, screenshot),
                                IslandTextButton, IslandSearchField
                                (M8) CoralTab (the conversation, actions, Ask field)
    coral/                    ✓ (M8) VoiceWindow (voice mode: the Pearl pulse, transcript, buttons; one per monitor),
                                CoralApp (FloatingWindow: conversations, model menu), CoralMessage, CoralComposer,
                                CoralToolButton
    controlcenter/            ✓ ControlCenter (Tide panel), NotificationCard
    menus/                    ✓ MenuContent (one menu by name) + CalendarMenu, WifiMenu, BluetoothMenu,
                                AudioMenu; hosted by the Status cay and the control center
    PanelState.qml            ✓ which panel/menu is open, on which monitor, and the menu's home
    osd/                      ✓ floating OSD
    toasts/                   ✓ Toast window
    search/                   ✓ SearchView (results + field, inside the Navigator cay), SearchRow
    overview/                 ✓ Overview (workspace cards with live windows, Super+Tab)
    switcher/                 ✓ Switcher (Alt+Tab, most recently used windows)
    lock/                     ✓ (M5) LockScreen (WlSessionLock + preview overlay), LockSurface (one monitor),
                                Pearl (shape, color, face, the Island's main activity; also behind the power actions)
    polkit/                   ✓ (M5) AuthDialog (one per monitor, shown on the one that had focus)
                                Power actions live in the bar: the Navigator's "power" form + Bar's scrim/clock
    home/                     ✓ (M7) Desktop (bottom layer: widgets, edit chrome, drops), HomeWidget (one widget +
                                outline, badge, wiggle, drag), Clock/Weather/Media/System/CalendarWidget,
                                Wallpaper (background layer, optional)
    editmode/                 ✓ (M7) EditMode (left Tide panel: thumbnails, tile layout, bar card)
    controlcenter/QuickTiles  ✓ (M7) the quick toggles' definitions and saved order (control center + edit mode)
    pearl/  greeter/
  services/                   # singletons
    Config.qml                ✓ ~/.config/reef/config.json (FileView + JsonAdapter, live reload, write-back)
    Scheme.qml                ✓ the color scheme (schemegen.js: wallpaper seeds, M3 tones, classic palettes),
                                caches ~/.cache/reef/scheme.json
    DefaultApps.qml           ✓ default apps through xdg-mime; the terminal in ~/.config/xdg-terminals.list
    Actions.qml               ✓ named actions shared by keybinds, IPC and buttons (stubs log their milestone)
    Workspaces  Apps  Audio  Network  Battery  Media  Time   ✓ (M1)
    Countdown  Recording  Brightness  Toasts  Visualizer     ✓ (M2)
    Privacy  Stopwatch  KeepAwake  BluetoothNotice           ✓ (M2 activities)
    Notifications  NightLight  Calendar  Focus  BluetoothState  Screenshot   ✓ (M3)
    Clipboard  Shelf  Calculator  Emoji  ColorPicker   ✓ (M6) cliphist + pins, the Shelf's items,
                                a safe expression parser, assets/emoji.json + recents, grim/slurp pixel pick
    Lock  Session  Keyboard  Polkit   ✓ (M5) lock state + PAM + lid (logind), power actions, keyboard layout, polkit agent
    Home  Weather  SystemStats  OsInfo   ✓ (M7) widget layouts per monitor, wttr.in through curl, /proc +
                                nvidia-smi/hwmon readings (only while a widget holds them), /etc/os-release
    Search                    ✓ (M4) results for search: apps, settings index, `/` commands, files (find)
                                Apps also keeps when each app was last opened (~/.cache/reef/launches.json)
    Coral                     ✓ (M8) OpenAI-compatible streaming chat (curl, server-sent events), actions
    CoralVoice                ✓ (M8) ffmpeg (record + level), whisper-cli, piper, ffmpeg (play + level)
    CoralWake                 ✓ (M8) wake word: ffmpeg ring buffer + level, whisper-server (tiny) or the cloud
    Notifications  Bluetooth  Clipboard  Shelf  Wallpaper  Sounds
  dev/                        ✓ DevWindow (M0 inspector) + its small helpers
  settings/                   ✓ (M7) Settings (FloatingWindow, sidebar + search), SettingsState (singleton: open,
                                page, search index), one *Page.qml per page, loaded by a Loader
  assets/fonts → ../../design/fonts (symlink)   assets/logo/ (copied from design/logo)
  assets/pam.d/reef           ✓ (M5) the lock's PAM service: pam_unix (falls back to /etc/pam.d/login)
  scripts/                    ✓ gen-tokens.py, gen-emoji.py (assets/emoji.json from
                                Unicode's emoji-test.txt; oh-my-zsh ships a copy)
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
| Colors | `services/Scheme` builds the scheme in Reef with `services/schemegen.js` (no external tool; matugen isn't needed). The wallpaper's colors come from Quickshell's `ColorQuantizer` (16 buckets); `seeds()` groups them into 30° hue families and ranks them by coverage and vividness. `generate(seed, tertiarySeed, colorfulness)` applies the M3 tone recipe in CIE LCh (L* = M3 tone), cutting chroma to fit sRGB; the Colorfulness levels are chroma tables (Neutral and Deep use one accent hue; Deep makes every surface black on dark). Classic palettes (`Tokens.palettes`) go through `classic()`, which derives containers and on-colors and enforces 4.5:1 text. The result is cached in `~/.cache/reef/scheme.json` so the next start is instant. `Colors.qml` falls back to the reference scheme in tokens, keeps the Island roles and scrim fixed, and crossfades every change with `effects-slow`. Writing GTK/Qt/kitty/Hyprland themes from the scheme comes later. The wallpaper path is `look.wallpaper` in Config. |
| Audio | `Quickshell.Services.Pipewire` |
| Media | `Quickshell.Services.Mpris`. Pull the album art's color for `island-accent`. |
| Notifications | `Quickshell.Services.Notifications`. Reef **is** the notification server. Only one program can own `org.freedesktop.Notifications`: while another shell (Caelestia) runs, Reef receives none. Test with `dbus-run-session` and an isolated `XDG_CONFIG_HOME`. |
| Tray | `Quickshell.Services.SystemTray`, shown inside the Status cay overflow. |
| Battery | `Quickshell.Services.UPower` |
| Network / Bluetooth | Quickshell's networking and Bluetooth modules if your version has them, otherwise `nmcli` and `bluetoothctl` through `Process`. |
| Lock | `WlSessionLock` plus `Quickshell.Services.Pam`. Idle handled with hypridle or Quickshell's idle support. Lid: `gdbus monitor` on logind (`LidClosed`, `PrepareForSleep`) and a `systemd-inhibit --mode=delay` sleep lock released once the lock is secure; both ship with glib2 and systemd, which Qt and Hyprland already need. |
| Greeter | greetd plus a Quickshell greeter (`Quickshell.Services.Greetd`), with its own entry point and the same theme. |
| Polkit | Quickshell's polkit agent if available, otherwise a small agent process that the UI talks to. |
| Clipboard | `cliphist` plus `wl-clipboard`. The Clipboard tab lists, searches and pins entries. |
| Shelf | Files and text dropped on the Island (`DropArea`) are kept in `$XDG_RUNTIME_DIR/reef/shelf` and dragged back out as file URIs. |
| Screenshot / recording | `grim` plus `slurp` (or `hyprshot`), and `wf-recorder` / `gpu-screen-recorder`. |
| Audio visualizer | `cava` (raw output) feeding the Pearl and the Island waveform. Its frame rate is capped by the performance setting. |
| Coral | An OpenAI-compatible HTTP client (streaming, configurable base URL, model and key). Optional voice: speech-to-text with whisper.cpp, text-to-speech with piper. Coral's "actions" (for example switching to Neutral) map to Reef IPC commands. |
- **Coral (M8).** `services/Coral.qml` posts `/chat/completions` with `stream: true` through `curl -N` (one `Process` per request, so a stopped request's late output is ignored) and reads the server-sent events line by line. Quickshell's `SplitParser` leaves the blank line between events stuck to the next one (`"\ndata: …"`), so lines are split and trimmed again. The key is read from `coral.apiKeyEnv` and given to curl as a header file on fd 3 (`-H @/dev/fd/3`), never as an argument, since any process can read argv. With no model set, the first id from `/models` is used. Actions are written by the model as `[[Label|action:value]]`; Coral keeps only the ones in its `tools` table with valid values, shows them as buttons, and runs them (the same handlers as Reef's IPC and keybinds) only when pressed. IPC: `coral ask|open|app|voice|stop|clear`. Conversations are kept in `~/.local/share/reef/coral/chats.json` (`{ version, chats: [{ id, title, titled, created, updated, model, messages }] }`, written 400 ms after a change through a `FileView` with atomic writes); after the first reply a quiet non-streaming request asks the model for a 2–6 word title. Attachments: `file --mime-type` decides; images are scaled to 1536 px (ffmpeg) into `coral/files/<chat>/` and sent as base64 `image_url` parts (read with `base64 -w0` just before sending, so the JSON stays small), text and code are inlined as fenced blocks (200 KB), PDFs through `pdftotext`. Reasoning models' `delta.reasoning` / `reasoning_content` is kept with the reply. The app's message list is a `ListView` over `Coral.messages.length` whose delegates read `Coral.messages[index]`, so a streaming reply updates bindings instead of rebuilding every message. Local or cloud: chat goes to `coral.local` or `coral.cloud` (Groq by default: `openai/gpt-oss-120b`), per `coral.chat`; `Coral.curl(cloud, endpoint, path, args)` is the one place requests are built (the key file, else `keyEnv`, on fd 3; endpoints pasted whole are trimmed to their base), and voice uses it too. Groq's chat stream also carries a `reasoning` field, which is ignored. When `/models` is used to pick a model, speech, moderation and embedding models are skipped.
- **Coral wake word (M8).** `services/CoralWake.qml`, started by `modules/Commands`. One ffmpeg (`-name 'Reef wake word'`) keeps a ring of 0.5 s raw chunks (`-f segment -segment_wrap 20 -segment_format s16le`, `-c:a pcm_s16le`) in `$XDG_RUNTIME_DIR/reef/wake` and prints the RMS level. A burst (louder than `coral.silenceDb`, ended by `coral.wakeGapMs` of quiet, `wakeMinMs`..`wakeMaxMs` long) is cut from the chunks by modification time (`stat -c %.9Y`; this system's `find` is bfs, which takes no epoch times) into `wake.wav` and written down by `whisper-server` (tiny model, `--prompt 'Hey Coral. Oye Coral.'`, on 127.0.0.1:`coral.wakePort`) or the cloud. Without the prompt tiny hears "Coral" as "Carl"; with it, it sometimes repeats the prompt next to real speech but never invents it from noise. Greetings come out mangled ("Oye Coral" → "Ajay Coral", "Ah, Coral"), so the match is on the name: "Coral" (or what tiny writes for it: corral, carol, carl…) as the first word, or the second after a short word that isn't an article. The request after the phrase is written down again by the main speech-to-text (`CoralVoice.fromClip`), with the phrase stripped. Helpers are started as `setpriv --pdeathsig TERM <program>` (or `exec` into it from `sh`), so the kernel ends them when Quickshell goes, a crash included, and stopping the `Process` stops the program itself; a `sh` wrapper that cleans up after its children leaked them on every reload (Quickshell kills the wrapper outright). A regex kept in a QML `var` property can come back as a new object on each read (lastIndex 0): copy it into a local before looping with `exec`.
- **Loudness from ffmpeg.** `ametadata=mode=print:file=-` buffers when stdout is a pipe: every reading arrives at once when ffmpeg exits. Add `:direct=1`. Speech is told from the room with an adaptive floor (`CoralVoice.isSpeech`): louder than `coral.silenceDb` and `coral.speechMarginDb` above a background level that follows quiet at once and noise slowly (~10 s); a fixed threshold failed on a laptop mic idling at −27 dB. Voice mode pauses playing media while it runs and resumes it after. Once speech has started, softer words count at half the margin (hysteresis), so a quiet syllable doesn't end a sentence. ffmpeg's `pulse` output drops what's still buffered when its input ends (by default up to ~2 s, measured as the last ~0.45 s of a reply going missing), so playback uses `-buffer_duration 150` and `apad=pad_dur=0.5`.
- **Coral voice (M8).** `services/CoralVoice.qml`. Listening: `ffmpeg -f pulse -i default` records 16 kHz mono to `$XDG_RUNTIME_DIR/reef/coral-in.wav` and, through `asplit` + `astats` + `ametadata=print:file=-`, prints the RMS level about 20 times a second (the Pearl's pulse and the end-of-speech detection: `coral.silenceDb`, `coral.silenceMs`). SIGINT lets ffmpeg finish the file. Transcribing (`coral.listen`): in the cloud, `POST /audio/transcriptions` (multipart, `response_format=verbose_json`; Groq's `whisper-large-v3-turbo` answers in about half a second; the language comes back as a name, "Spanish", mapped to a code); locally, `whisper-cli -l auto -oj` (the JSON gives the text and the detected language); its encoder window is sized to the clip (`-ac`, 50 frames a second) since the default 30 s window costs as much for a word as for a paragraph on a CPU, and the temperature fallback is off (`-nf`). Bracketed and parenthesized noise tags (`[BLANK_AUDIO]`, `(indistinct)`) are dropped. Speaking (`coral.speech`): in the cloud, `POST /audio/speech` (`response_format: wav`) when the cloud voice speaks the reply's language (`coral.cloud.speechLanguages`; Groq's Orpheus is English only and needs its terms accepted once in the Groq console), otherwise, or on any cloud error (shown as a toast), `piper -m <voice> -f coral-out.wav` (text on stdin, Markdown stripped); then `ffmpeg -re … -f pulse` plays it while printing the level. Models live in `coral.voiceDir` (default `~/.local/share/reef/voice`): the first `ggml-*.bin`, and one `*.onnx` (+ `.onnx.json`) voice per language prefix. Packages: `whisper-cpp` (extra), `piper-tts` (AUR; its command is `piper-tts`, since `extra/piper` is an unrelated mouse app, and a plain `piper` is used only if it takes `--model`; rendering a sentence takes 3–6 s, mostly Python starting); ffmpeg is already a dependency. On a 2-core i3-1115G4, `ggml-small-q5_1` takes roughly 10 s per encoder pass with language detection adding one; `ggml-base-q5_1` is about 3× faster.
| Sounds | Short sound files played through `pw-play` / `paplay`. Each category has its own toggle. |
| IPC | `IpcHandler` so scripts and keybinds can call `reef island open clipboard`, `reef power`, `reef panel controlcenter`, and so on. |

## Quickshell notes (0.3.2, checked 2026-11-23)

- Every module this plan names is in the installed build, including Bluetooth, Networking and Polkit, plus `IdleMonitor`, `IdleInhibitor`, `BackgroundEffect`, `ColorQuantizer` and `DesktopEntries`. No CLI fallbacks are needed.
- Imports use the config root as the `qs` module: `import qs.theme`, `import qs.services`, `import qs.components`.
- Singletons are created on first use, so a value read at startup may still be a default; bind to it rather than reading once.
- `FileView` creates missing parent directories when it writes. Its `loaded` stays false when a missing file is replaced by `writeAdapter()`, so `Config.loaded` is tracked separately.
- QML treats any name like `onSomething` as a signal handler: never name a property that way (hence `Colors.on.surface`).
- Fonts load straight from the `.woff2` files with `FontLoader`; `font.variableAxes` drives wght, ROND, wdth (Google Sans Flex) and FILL, GRAD, opsz (Material Symbols).
- `Quickshell.Hyprland` fills in after it connects, and `Hyprland.usingLua` turns true then. In Lua mode, dispatches use Lua syntax: `hl.dsp.focus({ workspace = "3" })` (see services/Workspaces).
- `DesktopEntries` loads asynchronously and `byId()` isn't reactive: bindings that call it also read `DesktopEntries.applications.values.length` so they re-run.
- A layer surface gets keyboard focus only with `WlrLayershell.keyboardFocus`; pair Exclusive with `HyprlandFocusGrab` so a click elsewhere releases it, and arm the grab a moment after focusing, or Hyprland clears it at once.
- Debug service state with `qs -p ./reef ipc call reef status`.
- Resizing a layer surface under a resting pointer makes Hyprland send a leave and no enter until the pointer moves, so a surface that grows on hover (the bar, for the Status cay's menus) is created at full height up front with an input mask instead.
- **Performance.** Qt redraws a whole surface on every change and Hyprland then recomposites all of it, so keep surfaces that animate often small: the Island's window is only as wide as its widest form (not the screen). Build heavy content only while it's shown: the overview's window captures exist only while it's open, search computes nothing while closed and lists results in a lazy `ListView`. Avoid rebuilding paths every frame: the wavy progress draws its wave once and slides it inside a clip.
- **Never animate a variable-font axis.** Each new `font.variableAxes` value (FILL, wght, ROND, wdth) makes Qt build a new font instance, which blocks the GUI thread for 100+ ms: the Island ran at ~5 fps while its tab icons filled. `Icon` crossfades an outlined and a filled glyph instead, and the Navigator's active numeral crossfades two weights. Animate opacity between fixed axis values, never the axis itself.
- A child `Process` gets an open stdin pipe. `slurp` reads preset boxes from stdin when it isn't a terminal and never shows its overlay, so run it as `slurp </dev/null`. Send `wl-copy`'s output to `/dev/null`: its background child keeps the pipe open and the `Process` never reports `exited`.
- A `MouseArea` with `hoverEnabled` takes hover from a sibling `HoverHandler` beneath it; to know whether the pointer is anywhere on an item, check both.
- Qt Quick re-sends hover when items move under a still pointer. Where items re-form on hover (the Status row), compare positions in window coordinates and act only on real pointer movement.
- `clip` is rectangular; to clip to a rounded shape, mask a layer with `MultiEffect` (`maskEnabled`, `maskSource`), as the OSD's fill does.
- In Hyprland's Lua mode, `hyprctl dispatch "hl.dsp.cursor.move({x=…,y=…})"` moves the pointer and `hl.dsp.send_shortcut({mods='', key='t'})` types into the focused surface, handy for checking hover and search.
- A Repeater over a JS array hands each delegate a copy of its object, so `indexOf(modelData)` finds nothing; use the delegate's `index`.
- In a `Row`, shorter children sit at the top; cays that share a row with one that grows up (the Navigator into search) anchor to the bottom.
- Quickshell 0.3.2's `Process` has no `exec()`: to restart one, set `running = false` and start again from `exited`.
- Window thumbnails: `ScreencopyView { captureSource: hyprlandToplevel.wayland }`. A HyprlandToplevel's `lastIpcObject` (position `at`, `size`, `class`, `focusHistoryID`) only fills in after `Hyprland.refreshToplevels()`; `Workspaces.refresh()` does it when the overview or switcher opens. Focus a window with `Workspaces.focusWindow()`.
- `Spring.snap()` assigns `target`, which breaks a binding on it; to jump a bound spring, set `value` (and `velocity = 0`) instead.
- Hyprland animates a layer surface as it maps and unmaps (your `layers` animation, often a slide), on top of Reef's own motion. Surfaces with their own open/close motion (overview, switcher) stay mapped and switch to an empty input mask when closed; `hypr/reef.lua` also sets `no_anim` for `reef-*` layers.
- When a surface that held the keyboard closes, Hyprland refocuses the previous window, which can switch back to its workspace. Switch workspaces or windows after `focus-handoff-delay` (`Workspaces.afterHandoff`). Focus a window by address (`hl.dsp.focus({ window = "address:0x…" })`); `Toplevel.activate()` doesn't change workspace.
- Holding Super: `hypr/reef.lua` binds Super's press to the `reef:superHold` global, and a `GlobalShortcut` gets both its press and release (Commands.qml). The tap-for-search bind is a separate release bind on the same key; PanelState skips that search when the release ends a hold.
- The switcher switches when Alt is released, which it sees because it holds the keyboard while open. A release that happens before the surface gets the keyboard (a very quick Alt+Tab tap) isn't seen; Enter or a click then finishes.
- `transient` is a reserved word in QML; don't use it as a property name.
- To add an Island activity: add an `Activity { … }` to `IslandState.all` at its priority, bind `live` to a service, and add a toggle under `island.activities` in Config. The pill, peek, secondary pill and Now row follow.
- QML's JavaScript engine lacks some newer built-ins (`String.prototype.matchAll`, `Object.fromEntries`); use `RegExp.exec` loops and `reduce`.
- Don't start a `Process` from a change handler with a bound `command`: the binding may not have updated yet. Set `command` right before `running = true`.
- The visualizer writes its cava config to `~/.cache/reef/cava.conf` and runs cava only while a waveform is visible and media plays.
- **Lock.** `services/Lock` checks the password with `PamContext` against `assets/pam.d/reef` (`auth required pam_unix.so`: the user's own password through the setuid helper). If that can't start it retries with the system `login` stack. `ipc call lock preview` shows the lock screen in an overlay without locking (Escape closes it); its power buttons do nothing. If Reef dies while locked, Hyprland shows its "lockdead" screen: from a TTY run `hyprctl --instance 0 'keyword misc:allow_session_lock_restore 1'` and start Reef again. Don't drive the lock screen with synthetic keys while testing: `send_shortcut` goes to the focused *window*, not the lock surface.
- **Island tabs (M6).** Clipboard lists `cliphist list` and refreshes on `wl-paste --watch echo`; pins and "first seen" times live in `$XDG_DATA_HOME/reef/clipboard.json` (cliphist has no times, so entries from before Reef ran show none). The Shelf keeps file paths and text in `$XDG_RUNTIME_DIR/reef/shelf.json`; tiles drag out with `Drag.Automatic` (`text/uri-list` or `text/plain`). The color picker reads one pixel with `grim -g "$(slurp -p)" -t ppm - | tail -c 3`, so it needs no extra tool. The calculator never uses `eval`. The Tools tab is `island-tools-width` (420), so the Island morphs width when you switch to it. To check tab layouts without a running shell, load them in a `FloatingWindow` with `QT_QPA_PLATFORM=offscreen` and save `grabToImage` results (layer-shell windows can't load offscreen).
- **Polkit.** Only one authentication agent can register per session. While polkit-gnome or hyprpolkitagent runs, Reef's `PolkitAgent` logs "An authentication agent already exists" and that agent keeps answering; stop it (and drop it from autostart) to get Reef's dialog. Test with `pkexec true`. Settings: `session.polkitAgent`.
- **Blur.** `BackgroundEffect.blurRegion: Region { item: … }` (attached, from `Quickshell.Wayland`; the ext-background-effect protocol) works on Hyprland 0.57: the compositor blurs what's behind that part of the surface. The power actions blur the whole screen; the overview blurs everything behind it, and the bar blurs its own strip to match. Point the region at an empty item to turn it off.
- **Dragging inside a list that reflows** (edit mode's tiles, the cay chips): keep where the drag started and add the drag offset to that, not to the item's current slot, which moves as the others make room.
- **DragHandler zeroes `activeTranslation` before `onActiveChanged(false)` runs.** Keep the last translation yourself (in `onActiveTranslationChanged`) and use it on release, or the drop lands where the drag started (the home widgets did).
- **Zoom.** `scale.zoom` multiplies spacing, corners, type and every pixel size token in `Tokens` (gen-tokens appends `* zoom` to px sizes; ratios and angles stay). Code that uses tokens zooms for free; raw numbers wouldn't. A `FloatingWindow` (Settings) keeps the size Hyprland gave it when it mapped, so changing `implicitWidth` later does nothing: Settings finds its own window in `hyprctl clients -j` (pid + title) and dispatches `hl.dsp.window.resize({ x, y, window = "address:…" })`. Its `minimumSize` must never exceed that size, or Qt draws the content past the window's edge (the old zoom bug).
- **The app menu** lives in the bar's own surface (the Dock and search both live there), like the Status cay's menus: a full-surface `MouseArea` joins the input mask while it's open so any click closes it, and the bar takes the keyboard (Exclusive) until then.
- **Default apps.** `DesktopEntry` has no MIME types, so `DefaultApps` greps `MimeType=` from the desktop files in the usual application folders to find candidates; `xdg-mime query default` / `xdg-mime default` read and set them (xdg-utils, already used for `xdg-open`).
- Testing Config from outside: write `~/.config/reef/config.json` in place. Replacing the file (write a temp file, then rename) drops `FileView`'s watch, and a non-atomic `json.dump` can be read half-written.
- An inline `component` whose root is a `QtObject`, declared in a `PanelWindow`, came up as "is not a type" in Quickshell 0.3.2; use plain objects (Bar.qml spells out one Spring per cay).
- **A Spring only moves when its target changes.** To fade something in again with the same target (a new Settings page), use `restartFrom(0)`; assigning `value` alone leaves it there.
- **New folders need a restart.** Hot reload picks up edits and new files in existing module folders (checked: new bar files loaded live), but a new folder under `reef/` (a new `qs.modules.x`) reports "module is not installed" until Quickshell starts again.
- **Pages loaded by path don't see their folder.** A file a `Loader` loads by `source` (the Settings pages) doesn't resolve types from its own folder by name ("X is not a type"); keep the pieces it shares in `components/` (SettingsSection, OptionCard), which it imports.
- **Checking QML without the live shell.** A throwaway `ShellRoot` file at the config root (so `qs.*` resolves) can `Qt.createComponent()` each file and log `errorString()` (run on the real display with nothing instantiated for layer-shell files, or with `QT_QPA_PLATFORM=offscreen` for the rest), and render Items or a `FloatingWindow`'s first child with `grabToImage`. Isolate it with `dbus-run-session`, no `HYPRLAND_INSTANCE_SIGNATURE`, and scratch `XDG_*` folders.
- **Edit mode (M7).** Widgets live on a bottom-layer `PanelWindow` with `ExclusionMode.Normal` (it fits inside the bar's exclusive zone); its mask is the widgets' bounds, or the whole surface while editing so drops land. A thumbnail drags out of the panel with `Drag.Automatic` and the MIME type `application/x-reef-widget`; a click adds it too. The bar reserves its zone on the left by changing its anchors (top+bottom+left), so each cay has a `vertical` form.
- IPC: `reef run <action>`, `reef settings [page]`, `reef dev`, `reef status`, `reef scheme`, `reef timer <duration>`, `reef toast <text>`, `reef timerCancel`, `island open <tab>`, `island close`, `island toggle`, `island swap`, `island simulate <key>` (shows an activity with its current values, to check how it looks), `stopwatch start|pause|toggle|lap|reset`, `keepAwake on <duration>|off|toggle`, `panel toggle <controlCenter|editMode|search|overview|calendar|wifi|bluetooth|audio>` (menus open inside the control center), `panel close`, `overview select <n>|go <n>` (drive the open overview without input, e.g. to record its motion with `grim` in a loop), `focus start <minutes>|stop|toggle`, `superHold down|up` (what holding Super does), `notifications dnd|clear`, `lock lock|preview`. With more than one Reef running, target one with `qs ipc --pid <pid> call …`.

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
  - **Widgets and tile layout**, as saved by edit mode: `home.layouts`, `controlCenter.tiles`, plus `home.weatherLocation`, `home.temperatureUnit`, `home.wiggle`.
  - **Coral**: `coral.chat`, `coral.listen`, `coral.speech` (each `local` or `cloud`); `coral.local.{endpoint, model}`; `coral.cloud.{endpoint, keyEnv, model, listenModel, speechModel, speechVoice, speechLanguages}`; `coral.actions`, `coral.voice`, `coral.speak`, `coral.listenLanguage` and the listening thresholds. The cloud key is not in config.json: it's saved to `~/.config/reef/keys/cloud` (mode 600; Settings → Coral), or read from the variable named in `coral.cloud.keyEnv`.

## Fonts

- Google Sans Flex (UI) and Google Sans Code (mono) are under the SIL OFL. Material Symbols Rounded is under Apache-2.0.
- Web copies are in `design/fonts/` for the HTML mockups. For the shell, install the TTF/variable fonts system-wide, either from the font projects' GitHub releases or from AUR packages such as `ttf-material-symbols-variable-git`.
