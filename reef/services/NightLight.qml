pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Night light: warms the screen with a Hyprland screen shader (no extra programs).
// The shader is written to ~/.cache/reef/nightlight.frag from the temperature setting
// and applied with `hyprctl eval` (Hyprland 0.57's Lua config).
Singleton {
    id: root

    readonly property bool enabled: Config.options.nightLight.enabled
    readonly property int temperature: Config.options.nightLight.temperature
    readonly property string shaderPath: Config.cacheDir + "/nightlight.frag"

    function toggle() {
        Config.options.nightLight.enabled = !enabled;
    }

    // Approximate white point for a color temperature (Tanner Helland's fit), 0..1.
    function _rgb(kelvin) {
        const t = kelvin / 100;
        const r = t <= 66 ? 255 : 329.698727446 * Math.pow(t - 60, -0.1332047592);
        const g = t <= 66 ? 99.4708025861 * Math.log(t) - 161.1195681661 : 288.1221695283 * Math.pow(t - 60, -0.0755148492);
        const b = t >= 66 ? 255 : t <= 19 ? 0 : 138.5177312231 * Math.log(t - 10) - 305.0447927307;
        const c = v => Math.max(0, Math.min(255, v)) / 255;
        return [c(r), c(g), c(b)];
    }

    readonly property string shader: {
        const [r, g, b] = _rgb(temperature);
        return `#version 300 es
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;
void main() {
    vec4 c = texture(tex, v_texcoord);
    fragColor = vec4(c.rgb * vec3(${r.toFixed(4)}, ${g.toFixed(4)}, ${b.toFixed(4)}), c.a);
}
`;
    }

    function _apply() {
        if (!Config.loaded)
            return;
        if (enabled) {
            file.setText(shader);
            Quickshell.execDetached(["hyprctl", "eval", `hl.config({ decoration = { screen_shader = "${shaderPath}" } })`]);
        } else {
            Quickshell.execDetached(["hyprctl", "eval", `hl.config({ decoration = { screen_shader = "" } })`]);
        }
    }

    onEnabledChanged: _apply()
    onTemperatureChanged: if (enabled) _apply()
    Connections {
        target: Config
        function onLoadedChanged() { root._apply(); }
    }

    FileView {
        id: file
        path: root.shaderPath
        printErrors: false
    }
}
