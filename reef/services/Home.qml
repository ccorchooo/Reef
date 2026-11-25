pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Home widgets (SURFACES.md → Edit mode): which ones sit on each monitor's desktop and
// where. A layout is a list of { id, kind, x, y }, with x and y measured from the
// top-left of the free desktop (the screen minus the bar). Monitors without a saved
// layout show the default one (screens/Home). Edit mode adds, moves and removes widgets,
// and every change is saved to Config at once.
Singleton {
    id: root

    // The kinds, in the order edit mode lists them.
    readonly property var kinds: ["clock", "weather", "media", "system", "calendar"]
    readonly property var labels: ({
            clock: "Clock",
            weather: "Weather",
            media: "Media",
            system: "System",
            calendar: "Calendar"
        })

    // About how big each kind is (to center a dropped widget on the pointer).
    function sizeOf(kind) {
        switch (kind) {
        case "clock": return { width: Tokens.widgetClockSize, height: Tokens.widgetClockSize };
        case "weather": return { width: Tokens.widgetWeatherSize, height: Tokens.widgetWeatherSize };
        case "media": return { width: Tokens.widgetMediaWidth, height: Tokens.widgetMediaHeight };
        case "system": return { width: Tokens.widgetSystemWidth, height: Tokens.widgetSystemWidth * 2 / 3 };
        }
        return { width: Tokens.widgetCalendarWidth, height: Tokens.widgetCalendarWidth };
    }

    function defaultLayout() {
        const col2 = Tokens.widgetInset + Tokens.widgetClockSize + Tokens.space6;
        return [
            { id: "clock", kind: "clock", x: Tokens.widgetInset, y: Tokens.widgetInsetTop + Tokens.space2 },
            { id: "weather", kind: "weather", x: col2, y: Tokens.widgetInsetTop },
            { id: "system", kind: "system", x: col2, y: Tokens.widgetInsetTop + Tokens.widgetWeatherSize + Tokens.space6 },
            { id: "media", kind: "media", x: Tokens.widgetInset, y: Tokens.widgetInsetTop + Tokens.widgetClockSize + Tokens.space12 * 2 + Tokens.space6 }
        ];
    }

    function layout(screen) {
        const saved = Config.widgets(screen);
        return saved ? saved.map(w => Object.assign({}, w)) : defaultLayout();
    }

    function add(screen, kind, x, y) {
        const list = layout(screen);
        let n = 1;
        while (list.some(w => w.id === kind + (n > 1 ? n : "")))
            n++;
        list.push({ id: kind + (n > 1 ? n : ""), kind: kind, x: Math.round(x), y: Math.round(y) });
        Config.setWidgets(screen, list);
    }

    // Adds a widget without a drop point (a click or Enter on its thumbnail): near the
    // top-left, stepping down and right past the widgets already there.
    function place(screen, kind) {
        const n = layout(screen).length;
        add(screen, kind, Tokens.widgetInset + n * Tokens.space6, Tokens.widgetInsetTop + n * Tokens.space6);
    }

    function move(screen, id, x, y) {
        Config.setWidgets(screen, layout(screen).map(w => w.id === id ? Object.assign(w, { x: Math.round(x), y: Math.round(y) }) : w));
    }

    function remove(screen, id) {
        Config.setWidgets(screen, layout(screen).filter(w => w.id !== id));
    }

    function reset(screen) {
        Config.setWidgets(screen, defaultLayout());
    }
}
