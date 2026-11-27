# Reef for fish: the starship prompt and a fastfetch greeting in each new terminal
# window. Installed by `reef install` to ~/.config/fish/conf.d/reef.fish.
# Turn the greeting off with `set -Ux REEF_GREETING 0`.
status is-interactive; or return

set -g fish_greeting
command -q starship; and starship init fish | source

if command -q fastfetch; and not set -q REEF_GREETED; and test "$REEF_GREETING" != 0
    # Once per window: not in shells started from this one, nor in editors' terminals.
    if test "$TERM" = xterm-kitty; or test "$TERM_PROGRAM" = ghostty
        set -gx REEF_GREETED 1
        fastfetch
    end
end
