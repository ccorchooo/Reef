pragma Singleton
import QtQuick
import Quickshell

// Type styles from tokens.json, scaled by Settings → Scale → Text size.
// Fonts load from assets/fonts (Google Sans Flex, Google Sans Code, Material Symbols Rounded),
// so nothing needs to be installed system-wide.
//
//   StyledText { style: "titleMdEmphasized"; text: "Coral" }
//   font: Type.font("bodyMd")
Singleton {
    id: root

    readonly property string sans: _family(sansLoader, Tokens.fontFamilies.sans)
    readonly property string mono: _family(monoLoader, Tokens.fontFamilies.mono)
    readonly property string icons: _family(iconLoader, "Material Symbols Rounded")

    // Style names, in tokens.json order (for previews).
    readonly property var styles: Object.keys(Tokens.typeStyles)

    function spec(name) {
        const s = Tokens.typeStyles[name];
        if (!s) {
            console.warn("Type: unknown style", name);
            return Tokens.typeStyles.bodyMd;
        }
        return s;
    }

    function family(name) {
        return spec(name).family === "mono" ? mono : sans;
    }

    function size(name) {
        return spec(name).size * Tokens.textScale;
    }

    function lineHeight(name) {
        return spec(name).lineHeight * Tokens.textScale;
    }

    // A font for a style. `axes` adds or overrides variable axes, e.g. { ROND: 100 }.
    function font(name, axes) {
        const s = spec(name);
        return Qt.font({
            family: s.family === "mono" ? mono : sans,
            pixelSize: s.size * Tokens.textScale,
            weight: s.weight,
            letterSpacing: s.letterSpacing * Tokens.textScale,
            variableAxes: Object.assign({ wght: s.weight }, axes ?? {})
        });
    }

    function _family(loader, fallback) {
        return loader.status === FontLoader.Ready ? loader.name : fallback;
    }

    property FontLoader _sans: FontLoader {
        id: sansLoader
        source: Quickshell.shellPath("assets/fonts/GoogleSansFlex-latin-full.woff2")
    }
    property FontLoader _mono: FontLoader {
        id: monoLoader
        source: Quickshell.shellPath("assets/fonts/GoogleSansCode-latin-wght.woff2")
    }
    property FontLoader _icons: FontLoader {
        id: iconLoader
        source: Quickshell.shellPath("assets/fonts/material-symbols-rounded.woff2")
    }
}
