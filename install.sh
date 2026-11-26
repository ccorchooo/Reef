#!/usr/bin/env bash
# Install Reef (a Quickshell shell for Hyprland).
#
#   ./install.sh               link ~/.config/quickshell/reef to this checkout (edits apply live)
#   ./install.sh --copy        copy it there instead (the checkout can then go)
#   ./install.sh --hypr        also load hypr/reef.lua from your own ~/.config/hypr/hyprland.lua
#   ./install.sh --hypr-config install Reef's whole Hyprland config (hypr/config) as ~/.config/hypr;
#                              an existing config is moved to ~/.config/hypr.bak.<date> first, and a
#                              rerun updates the modules but never your user/ folder
#   ./install.sh --check       only list missing programs
#   ./install.sh --uninstall   remove ~/.config/quickshell/reef (your settings stay in ~/.config/reef)
#   ./install.sh --prefix DIR  system layout under DIR, for packages:
#                                DIR/etc/xdg/quickshell/reef   the shell (`qs -c reef` finds it)
#                                DIR/usr/share/reef/hypr       the Hyprland snippet (+ config/, the whole config)
#                                DIR/usr/share/licenses/reef   the fonts' licenses
#
# Then start it with `qs -c reef` (hypr/reef.lua starts it with Hyprland).
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
target="$config_home/quickshell/reef"
mode=link hypr=0 hypr_config=0 prefix=""

while [ $# -gt 0 ]; do
    case "$1" in
        --copy) mode=copy ;;
        --hypr) hypr=1 ;;
        --hypr-config) hypr_config=1 ;;
        --check) mode=check ;;
        --uninstall) mode=uninstall ;;
        --prefix) mode=prefix; prefix="${2:?--prefix needs a directory}"; shift ;;
        -h|--help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $1 (see --help)" >&2; exit 2 ;;
    esac
    shift
done

# program  what needs it  (required ones first; keep in step with packaging/arch/PKGBUILD)
required=(
    "qs:Quickshell, the shell itself" "hyprctl:Hyprland"
    "wl-copy:copying (wl-clipboard)" "wl-paste:the clipboard (wl-clipboard)" "cliphist:the Clipboard tab"
    "grim:screenshots and the color picker" "slurp:choosing a region"
    "curl:weather, calendars and Coral" "ffmpeg:Coral's voice, attachments"
    "file:Coral attachments" "xdg-open:opening files and links (xdg-utils)" "xdg-mime:default apps (xdg-utils)"
    "gdbus:locking on lid close (glib2)" "systemd-inhibit:locking before sleep (systemd)"
    "setpriv:ending helpers with the shell (util-linux)" "brightnessctl:brightness"
    "bluetoothctl:Bluetooth (bluez-utils)" "pgrep:screen recording detection (procps-ng)"
)
optional=(
    "pw-play:UI sounds (pipewire; paplay also works)" "cava:the audio visualizer"
    "whisper-cli:Coral listening on this computer (whisper.cpp)" "whisper-server:Coral's wake word on this computer"
    "piper-tts:Coral speaking on this computer" "pdftotext:PDF attachments (poppler)"
    "nvidia-smi:GPU temperature on NVIDIA" "gpu-screen-recorder:screen recording"
    "nm-connection-editor:advanced Wi-Fi settings" "blueman-manager:advanced Bluetooth settings"
    "pavucontrol:the volume mixer"
)

check() {
    local missing=0 entry
    for entry in "${required[@]}"; do
        command -v "${entry%%:*}" >/dev/null || { echo "  missing  ${entry%%:*}  (${entry#*:})"; missing=1; }
    done
    for entry in "${optional[@]}"; do
        command -v "${entry%%:*}" >/dev/null || echo "  optional ${entry%%:*}  (${entry#*:})"
    done
    if command -v qs >/dev/null; then
        echo "  found    $(qs --version 2>/dev/null | head -1) (Reef is built against 0.3.2)"
    fi
    return $missing
}

# Copy the shell, with the fonts symlink (assets/fonts → design/fonts) made real.
copy_shell() {
    local dest="$1"
    mkdir -p "$dest"
    cp -rL "$here/reef/." "$dest/"
    find "$dest" \( -name __pycache__ -o -name '*.pyc' -o -name '*.qmlc' -o -name '*.jsc' -o -name .qmlls.ini \) -prune -exec rm -rf {} +
}

case "$mode" in
    check)
        echo "Programs Reef uses:"
        check && echo "All required programs are here." || { echo "Install the missing ones above."; exit 1; }
        exit 0 ;;
    uninstall)
        if [ -L "$target" ] || [ -d "$target" ]; then
            rm -rf "$target"
            echo "Removed $target. Your settings are still in $config_home/reef."
        else
            echo "Reef isn't installed at $target."
        fi
        exit 0 ;;
    prefix)
        copy_shell "$prefix/etc/xdg/quickshell/reef"
        mkdir -p "$prefix/usr/share/reef/hypr" "$prefix/usr/share/licenses/reef"
        cp "$here/hypr/reef.lua" "$here/hypr/tokens.lua" "$prefix/usr/share/reef/hypr/"
        cp -rL "$here/hypr/config" "$prefix/usr/share/reef/hypr/config"
        cp "$here"/design/fonts/LICENSE-*.txt "$prefix/usr/share/licenses/reef/"
        exit 0 ;;
esac

# Reef's whole Hyprland config. Hyprland reloads as soon as the files change, so the
# running session switches to it at once.
install_hypr_config() {
    local dest="$config_home/hypr" src="$here/hypr/config" stamp
    stamp="$(date +%Y%m%d%H%M%S)"
    if [ -e "$dest" ] && [ ! -f "$dest/reef/lib.lua" ]; then
        mv "$dest" "$dest.bak.$stamp"
        echo "Moved your Hyprland config to $dest.bak.$stamp."
    fi
    mkdir -p "$dest"
    # The modules and the entry file are Reef's; user/ is yours and is never touched.
    rm -rf "$dest/reef"
    cp -rL "$src/reef" "$dest/reef"
    cp "$src/hyprland.lua" "$dest/hyprland.lua"
    # Reef's snippet (start command, Reef's keys, tokens): linked, or copied with --copy.
    rm -rf "$dest/reef-shell"
    if [ "$mode" = copy ]; then
        mkdir -p "$dest/reef-shell"
        cp "$here/hypr/reef.lua" "$here/hypr/tokens.lua" "$dest/reef-shell/"
    else
        ln -s "$here/hypr" "$dest/reef-shell"
    fi
    # First install: carry the running keyboard layout over.
    if [ ! -f "$dest/user/variables.lua" ] && command -v hyprctl >/dev/null && hyprctl version >/dev/null 2>&1; then
        local layout options variant
        layout="$(hyprctl getoption input:kb_layout 2>/dev/null | sed -n 's/^str: //p')"
        variant="$(hyprctl getoption input:kb_variant 2>/dev/null | sed -n 's/^str: //p')"
        options="$(hyprctl getoption input:kb_options 2>/dev/null | sed -n 's/^str: //p')"
        if [ -n "$layout" ] && [ "$layout" != "[[EMPTY]]" ]; then
            mkdir -p "$dest/user"
            {
                echo "-- Your settings (see reef/variables.lua for all of them). The keyboard came"
                echo "-- from the Hyprland config you had when Reef's was installed."
                echo "return {"
                echo "    input = {"
                echo "        layout  = \"$layout\","
                [ -n "$variant" ] && [ "$variant" != "[[EMPTY]]" ] && echo "        variant = \"$variant\","
                [ -n "$options" ] && [ "$options" != "[[EMPTY]]" ] && echo "        options = \"$options\","
                echo "    },"
                echo "}"
            } > "$dest/user/variables.lua"
            echo "Kept your keyboard layout ($layout) in $dest/user/variables.lua."
        fi
    fi
    if command -v Hyprland >/dev/null; then
        if Hyprland --verify-config -c "$dest/hyprland.lua" >/tmp/reef-hypr-verify.$$ 2>&1; then
            echo "Hyprland checked the config: no errors."
        else
            echo "Hyprland found problems in the config:"
            sed -n '/parsing result/,$p' /tmp/reef-hypr-verify.$$ | tail -n +3
        fi
        rm -f /tmp/reef-hypr-verify.$$
    fi
    echo "Installed Reef's Hyprland config in $dest. Your changes go in $dest/user/."
}

echo "Checking programs:"
check || echo "Reef runs without them, but the features listed above won't work."

if [ -e "$target" ] || [ -L "$target" ]; then
    if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$here/reef" ] && [ "$mode" = link ]; then
        echo "$target already links here."
    else
        backup="$target.bak.$(date +%Y%m%d%H%M%S)"
        mv "$target" "$backup"
        echo "Moved the old $target to $backup."
    fi
fi
mkdir -p "$(dirname "$target")"
if [ "$mode" = copy ]; then
    copy_shell "$target"
    echo "Copied Reef to $target."
elif [ ! -L "$target" ]; then
    ln -s "$here/reef" "$target"
    echo "Linked $target → $here/reef."
fi

if [ "$hypr_config" = 1 ]; then
    install_hypr_config
    echo "Run it now with: qs -c reef (Hyprland starts it from now on)"
    exit 0
fi

line="dofile(\"$here/hypr/reef.lua\")"
hyprconf="$config_home/hypr/hyprland.lua"
if [ "$hypr" = 1 ]; then
    if [ ! -f "$hyprconf" ]; then
        echo "No $hyprconf (Reef's snippet needs Hyprland's Lua config, 0.57+). Add this line to it yourself:"
        echo "    $line"
    elif grep -qF "hypr/reef.lua" "$hyprconf"; then
        echo "$hyprconf already loads a reef.lua."
    else
        printf '\n-- Reef (added by install.sh)\n%s\n' "$line" >> "$hyprconf"
        echo "Added Reef to $hyprconf. It starts Reef and binds its keys from the next Hyprland start."
    fi
else
    echo "To start Reef with Hyprland, add this to $hyprconf (or rerun with --hypr):"
    echo "    $line"
fi
echo "Run it now with: qs -c reef"
