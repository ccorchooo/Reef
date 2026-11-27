# Reef for bash: the starship prompt and a fastfetch greeting in each new terminal
# window. `reef install` sources this from ~/.bashrc.
# Turn the greeting off with `export REEF_GREETING=0` (before this line in ~/.bashrc).
[[ $- == *i* ]] || return

command -v starship >/dev/null && eval "$(starship init bash)"

if command -v fastfetch >/dev/null && [ -z "$REEF_GREETED" ] && [ "$REEF_GREETING" != 0 ]; then
    if [ "$TERM" = xterm-kitty ] || [ "$TERM_PROGRAM" = ghostty ]; then
        export REEF_GREETED=1
        fastfetch
    fi
fi
