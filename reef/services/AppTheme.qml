pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme
import "schemegen.js" as Gen

// Apps follow Reef's colors (Settings → Look → Apps), like CompositorTheme does for
// Hyprland's borders:
//   kitty  ~/.config/kitty/reef-colors.conf (kitty.conf from config/kitty includes it):
//          the surface, text, selection, cursor and 16 ANSI colors harmonized with the
//          scheme (schemegen.terminal, tokens color.terminal), the accents in 256-color
//          slots 16–18 (primary, secondary, tertiary), a pill container in 19 and the
//          text on primary in 20 (config/starship and config/fastfetch use them),
//          and the background opacity. Running kittys reload it at once (SIGUSR1).
//   GTK    light or dark (gsettings color-scheme, adw-gtk3 when installed) and
//          ~/.config/gtk-{3,4}.0/reef-colors.css with libadwaita's named colors (the
//          installer's gtk.css imports it; apps read it when they start).
// Written once the scheme settles, after the effects-slow crossfade.
Singleton {
    id: root

    readonly property var options: Config.options.appTheme
    readonly property string home: Quickshell.env("HOME")
    readonly property real opacity: options.kittyOpacity >= 0 ? Math.max(0.3, Math.min(1, options.kittyOpacity)) : Tokens.terminal.opacity

    function _hex(c) {
        const s = String(c);
        return "#" + s.replace("#", "").slice(-6);
    }

    function kittyText() {
        const r = {};
        const t = Colors._target;
        for (const k of Object.keys(t))
            r[k] = _hex(t[k]);
        const a = Gen.terminal(r, Colors.dark, Tokens.terminal);
        const ansi = [a.black, a.red, a.green, a.yellow, a.blue, a.magenta, a.cyan, a.white,
            a.brightBlack, a.brightRed, a.brightGreen, a.brightYellow, a.brightBlue, a.brightMagenta, a.brightCyan, a.brightWhite];
        const lines = [
            "# Written by Reef (services/AppTheme) from the current color scheme. Don't edit:",
            "# it's replaced whenever the scheme changes. Settings → Look → Apps turns it off.",
            `background ${r.surface}`,
            `foreground ${r.onSurface}`,
            `background_opacity ${opacity.toFixed(2)}`,
            `cursor ${r.primary}`,
            `cursor_text_color ${r.onPrimary}`,
            `selection_background ${r.primaryContainer}`,
            `selection_foreground ${r.onPrimaryContainer}`,
            `url_color ${a.blue}`,
            `active_border_color ${r.primary}`,
            `inactive_border_color ${r.outlineVariant}`,
            `bell_border_color ${r.error}`,
            `tab_bar_background ${r.surfaceContainerLowest}`,
            `tab_bar_margin_color ${r.surfaceContainerLowest}`,
            `active_tab_background ${r.primary}`,
            `active_tab_foreground ${r.onPrimary}`,
            `inactive_tab_background ${r.surfaceContainer}`,
            `inactive_tab_foreground ${r.onSurfaceVariant}`,
            `mark1_background ${r.primary}`,
            `mark2_background ${r.secondary}`,
            `mark3_background ${r.tertiary}`
        ];
        ansi.forEach((c, i) => lines.push(`color${i} ${c}`));
        // The accents, in 256-color slots 16–18, for prompts and fastfetch
        // (\e[38;5;16m = primary), each readable on the surface.
        // Then a container for pills (19) and the text that goes on primary (20). The accents
        // are checked on the container, the harder of the two backgrounds.
        const accents = [r.primary, r.secondary, r.tertiary].map(c => Gen.ensureContrast(c, r.surfaceContainerHigh, Tokens.terminal.minContrast));
        accents.forEach((c, i) => lines.push(`color${16 + i} ${c}`));
        lines.push(`color19 ${r.surfaceContainerHigh}`);
        lines.push(`color20 ${Gen.ensureContrast(r.onPrimary, accents[0], Tokens.terminal.minContrast)}`);
        return lines.join("\n") + "\n";
    }

    function gtkText() {
        const t = Colors._target, h = k => _hex(t[k]);
        const named = {
            accent_color: h("primary"), accent_bg_color: h("primary"), accent_fg_color: h("onPrimary"),
            destructive_color: h("error"), destructive_bg_color: h("error"), destructive_fg_color: h("onError"),
            window_bg_color: h("surface"), window_fg_color: h("onSurface"),
            view_bg_color: h("surfaceContainerLow"), view_fg_color: h("onSurface"),
            headerbar_bg_color: h("surface"), headerbar_fg_color: h("onSurface"),
            headerbar_backdrop_color: h("surface"),
            sidebar_bg_color: h("surfaceContainer"), sidebar_fg_color: h("onSurface"),
            secondary_sidebar_bg_color: h("surfaceContainerLow"), secondary_sidebar_fg_color: h("onSurface"),
            card_bg_color: h("surfaceContainer"), card_fg_color: h("onSurface"),
            dialog_bg_color: h("surfaceContainerHigh"), dialog_fg_color: h("onSurface"),
            popover_bg_color: h("surfaceContainerHigh"), popover_fg_color: h("onSurface"),
            thumbnail_bg_color: h("surfaceContainerHigh"), thumbnail_fg_color: h("onSurface")
        };
        return "/* Written by Reef (services/AppTheme) from the current color scheme. */\n"
            + Object.keys(named).map(k => `@define-color ${k} ${named[k]};`).join("\n") + "\n";
    }

    function apply() {
        const script = [];
        const args = [];
        if (options.kitty) {
            args.push(kittyText());
            script.push(`d="$HOME/.config/kitty"; mkdir -p "$d" && printf '%s' "$1" > "$d/reef-colors.conf.tmp" && mv "$d/reef-colors.conf.tmp" "$d/reef-colors.conf" && pkill -USR1 -x kitty; true`);
        } else {
            args.push("");
        }
        if (options.gtk) {
            args.push(gtkText(), Colors.dark ? "dark" : "light");
            script.push(`for v in 3.0 4.0; do d="$HOME/.config/gtk-$v"; mkdir -p "$d" && printf '%s' "$2" > "$d/reef-colors.css"; done
command -v gsettings >/dev/null && {
    gsettings set org.gnome.desktop.interface color-scheme "prefer-$3"
    for dir in "$HOME/.local/share/themes" "$HOME/.themes" /usr/share/themes; do
        [ -d "$dir/adw-gtk3" ] || continue
        [ "$3" = dark ] && gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark || gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3
        break
    done
}; true`);
        }
        if (script.length === 0)
            return;
        proc.command = ["sh", "-c", script.join("\n"), "reef-app-theme"].concat(args);
        proc.running = true;
    }

    Connections {
        target: Colors
        function on_TargetChanged() { settle.restart(); }
        function onModeChanged() { settle.restart(); }
    }
    onOpacityChanged: settle.restart()
    Connections {
        target: root.options
        function onKittyChanged() { settle.restart(); }
        function onGtkChanged() { settle.restart(); }
    }
    Timer {
        id: settle
        interval: Motion.duration(Motion.effectsSlow) * 2
        onTriggered: proc.running ? settle.restart() : root.apply()
    }
    Component.onCompleted: settle.restart()

    Process {
        id: proc
    }
}
