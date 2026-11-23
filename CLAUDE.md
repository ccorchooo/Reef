# CLAUDE.md — working on Reef

Reef is a Quickshell (Qt 6 / QML) desktop shell for Hyprland. The design is finished and lives in this repo. Your job is to build it faithfully.

## Read before coding
1. `README.md` for the vocabulary (Island, Pearl, Coral, cays, Tide panels, Shelf).
2. `docs/DESIGN.md`, `docs/MOTION.md` and `docs/SURFACES.md` for the spec.
3. `docs/ARCHITECTURE.md` for the structure, and `docs/ROADMAP.md` for what to build next.
4. The mockup image for whatever you're building (`design/mockups/screens|parts/*.png`). For exact sizes, colors and spacing, read the matching `design/mockups/html/*.html`.

## Rules
- **No hardcoded design values.** Colors, radii, spacing, sizes and type come from the `theme/` singletons, which are generated from `design/tokens.json` or come from the live color scheme. If a value you need is missing, add it to `tokens.json` and regenerate. Don't inline it.
- **All motion goes through `Motion`.** Use spatial springs for position, size and shape, and effects springs for opacity and color. Every animation must be interruptible and respect Reduce motion and the speed multiplier.
- **Global surface rules** (SURFACES.md): the screen corners are rounded; Tide panels are full height with concave fillets and sit sections on cards, never dividers; edge OSDs use fillets; the Island is pure black and never frosted; menus contain no how-to text.
- **Every feature gets a setting** in `Config`, and per monitor where it makes sense.
- **Keep services and UI apart.** System state lives in `services/` singletons, and UI only binds to them.
- **Check Quickshell APIs against the installed version** (quickshell.org/docs) instead of assuming. If a module is missing, fall back to `Process` with standard CLI tools (see ARCHITECTURE.md).
- **Accessibility:** text contrast at least 4.5:1, every control keyboard-reachable, icon-only buttons labelled.

## Workflow
- Work one roadmap milestone at a time and keep the shell runnable after every change (`qs -p ./reef`, or a symlink to `~/.config/quickshell/reef`).
- When a milestone matches its mockup, tick it in `docs/ROADMAP.md`.
- When the implementation forces a design change, update the relevant doc in `docs/` in the same change so the docs stay true.
- Ask before adding a dependency that isn't listed in ARCHITECTURE.md.
