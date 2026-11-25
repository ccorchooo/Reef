pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

// Current weather for the weather home widget, from wttr.in (curl, JSON format j1).
// The place is Config home.weatherLocation (a city), or wttr.in's guess from the IP
// address when empty. It refreshes every weather-refresh, and only while a widget shows
// it: widgets call hold() and release().
Singleton {
    id: root

    property int _users: 0
    readonly property bool active: _users > 0
    function hold() { _users++; }
    function release() { _users = Math.max(0, _users - 1); }

    readonly property string location: Config.options.home.weatherLocation
    readonly property bool fahrenheit: Config.options.home.temperatureUnit === "f"

    property bool ready: false
    property string error: ""
    property real tempC: 0
    property real tempF: 0
    property int code: 0
    property string description: ""
    property string place: ""
    property bool night: false

    readonly property string temperature: Math.round(fahrenheit ? tempF : tempC) + "°"
    readonly property string icon: _icon(code, night)

    // WWO condition codes (wttr.in) → Material Symbols.
    function _icon(c, isNight) {
        if (c === 113)
            return isNight ? "clear_night" : "clear_day";
        if (c === 116)
            return isNight ? "partly_cloudy_night" : "partly_cloudy_day";
        if (c === 119 || c === 122)
            return "cloud";
        if ([143, 248, 260].includes(c))
            return "foggy";
        if ([200, 386, 389, 392, 395].includes(c))
            return "thunderstorm";
        if ([179, 182, 185, 227, 230, 281, 284, 311, 314, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377].includes(c))
            return "weather_snowy";
        return "rainy";
    }

    // "06:12 AM" → minutes since midnight
    function _minutes(s) {
        const m = /(\d+):(\d+)\s*(AM|PM)/i.exec(s ?? "");
        if (!m)
            return -1;
        return (Number(m[1]) % 12 + (m[3].toUpperCase() === "PM" ? 12 : 0)) * 60 + Number(m[2]);
    }

    function _parse(text) {
        try {
            const d = JSON.parse(text);
            const c = d.current_condition[0];
            tempC = Number(c.temp_C);
            tempF = Number(c.temp_F);
            code = Number(c.weatherCode);
            description = (c.weatherDesc?.[0]?.value ?? "").trim();
            place = d.nearest_area?.[0]?.areaName?.[0]?.value ?? "";
            const astro = d.weather?.[0]?.astronomy?.[0];
            const now = new Date();
            const mins = now.getHours() * 60 + now.getMinutes();
            const rise = _minutes(astro?.sunrise), set = _minutes(astro?.sunset);
            night = rise >= 0 && set >= 0 ? (mins < rise || mins >= set) : (now.getHours() < 6 || now.getHours() >= 19);
            error = "";
            ready = true;
        } catch (e) {
            error = "Weather unavailable";
        }
    }

    function refresh() {
        if (fetcher.running)
            return;
        fetcher.command = ["curl", "-fsSL", "--max-time", "20", "https://wttr.in/" + encodeURIComponent(location) + "?format=j1"];
        fetcher.running = true;
    }

    onLocationChanged: if (active) refresh()

    Timer {
        running: root.active
        interval: Tokens.weatherRefresh
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: fetcher
        stdout: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root._parse(text)
        }
        onExited: exitCode => {
            if (exitCode !== 0)
                root.error = "Weather unavailable";
        }
    }
}
