#!/usr/bin/env bash
# Install Reef: the whole desktop (packages, the shell, Hyprland's config, kitty,
# fastfetch, starship, fonts, the session and the login greeter). This runs the `reef`
# command from this checkout; after installing, `reef` is on your PATH.
#
#   ./install.sh                 install everything (asks before each big step)
#   ./install.sh --yes           the same, taking the default answers
#   ./install.sh --dry-run       show what it would do
#   ./install.sh --link          use this checkout live (for working on Reef)
#   ./install.sh --check         what's missing or wrong (reef doctor)
#   ./install.sh --uninstall     remove Reef and put back what it replaced
#   ./install.sh --prefix DIR    packaging: lay Reef out under DIR
#
# `./install.sh --help` (or `reef help`) lists every option.
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ $# -eq 0 ] && set -- install
exec "$here/bin/reef" "$@"
