pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

// Calendar events from iCalendar (.ics) sources: files or https links (for example a
// calendar's "secret address in iCal format"), listed in Settings → Calendar.
// Handles single and all-day events and common repeats (daily, weekly with days,
// monthly, yearly; INTERVAL, COUNT, UNTIL, EXDATE). Times with a TZID are read as
// local time.
Singleton {
    id: root

    // A plain JS array (the config holds a QML list).
    readonly property var sources: Array.from(Config.options.calendar.sources)
    // [{ title, start: Date, end: Date, allDay, location }], expanded for ±1 year, sorted.
    property var events: []
    property real now: Date.now()

    readonly property var next: events.find(e => e.end.getTime() > now && !e.allDay) ?? events.find(e => e.end.getTime() > now) ?? null
    // Starts within event-soon (15 min) and hasn't started yet, or is happening now.
    readonly property var soon: {
        const e = events.find(e => !e.allDay && e.end.getTime() > now);
        if (!e)
            return null;
        const until = e.start.getTime() - now;
        return until <= Tokens.eventSoon ? e : null;
    }

    function eventsOn(date) {
        const d0 = new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
        const d1 = d0 + 86400000;
        return events.filter(e => e.start.getTime() < d1 && e.end.getTime() > d0);
    }

    function describe(e) {
        if (!e)
            return "";
        const day = Qt.formatDate(e.start, "ddd d");
        return e.allDay ? `${day} · All day` : `${day} · ${Qt.formatTime(e.start, Config.options.bar.clockFormat)}`;
    }

    function startsIn(e) {
        const m = Math.round((e.start.getTime() - now) / 60000);
        return m <= 0 ? "Now" : `In ${m} min`;
    }

    function refresh() {
        if (sources.length === 0) {
            events = [];
            return;
        }
        // Set the command here: a binding could still hold the old sources when the
        // change handler runs.
        fetch.running = false;
        fetch.command = ["sh", "-c", fetch.script, "reef-calendar"].concat(sources);
        fetch.running = true;
    }

    // ── iCalendar parsing ───────────────────────────────────────
    function _parse(text) {
        const lines = text.replace(/\r\n[ \t]/g, "").replace(/\n[ \t]/g, "").split(/\r?\n/);
        const out = [];
        let ev = null;
        for (const line of lines) {
            if (line === "BEGIN:VEVENT") {
                ev = { exdates: [] };
                continue;
            }
            if (line === "END:VEVENT") {
                if (ev?.start)
                    out.push(ev);
                ev = null;
                continue;
            }
            if (!ev)
                continue;
            const colon = line.indexOf(":");
            if (colon < 0)
                continue;
            const head = line.slice(0, colon), value = line.slice(colon + 1);
            const name = head.split(";")[0];
            if (name === "SUMMARY")
                ev.title = _unescape(value);
            else if (name === "LOCATION")
                ev.location = _unescape(value);
            else if (name === "DTSTART") {
                ev.start = _date(value);
                ev.allDay = head.includes("VALUE=DATE") || /^\d{8}$/.test(value);
            } else if (name === "DTEND")
                ev.end = _date(value);
            else if (name === "RRULE")
                ev.rrule = value.split(";").reduce((acc, p) => {   // (no Object.fromEntries in QML)
                    const [k, v] = p.split("=");
                    acc[k] = v;
                    return acc;
                }, {});
            else if (name === "EXDATE")
                ev.exdates = ev.exdates.concat(value.split(",").map(v => _date(v).getTime()));
            else if (name === "STATUS" && value === "CANCELLED")
                ev.cancelled = true;
        }
        return out.filter(e => !e.cancelled);
    }

    function _unescape(s) {
        return s.replace(/\\n/gi, " ").replace(/\\([,;\\])/g, "$1");
    }

    // 20261123, 20261123T180000, 20261123T180000Z
    function _date(v) {
        const m = v.match(/^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z)?)?/);
        if (!m)
            return new Date(NaN);
        const [y, mo, d, h, mi, s] = [m[1], m[2] - 1, m[3], m[4] ?? 0, m[5] ?? 0, m[6] ?? 0].map(Number);
        return m[7] ? new Date(Date.UTC(y, mo, d, h, mi, s)) : new Date(y, mo, d, h, mi, s);
    }

    function _expand(ev, from, to) {
        const dur = (ev.end ?? new Date(ev.start.getTime() + (ev.allDay ? 86400000 : 3600000))).getTime() - ev.start.getTime();
        const make = start => ({ title: ev.title || "Event", location: ev.location ?? "", allDay: ev.allDay, start: start, end: new Date(start.getTime() + dur) });
        if (!ev.rrule)
            return ev.start.getTime() < to && ev.start.getTime() + dur > from ? [make(ev.start)] : [];
        const r = ev.rrule, freq = r.FREQ, interval = Number(r.INTERVAL ?? 1);
        const count = r.COUNT ? Number(r.COUNT) : Infinity;
        const until = r.UNTIL ? _date(r.UNTIL).getTime() : Infinity;
        const days = ["SU", "MO", "TU", "WE", "TH", "FR", "SA"];
        const byday = r.BYDAY ? r.BYDAY.split(",").map(d => days.indexOf(d.slice(-2))) : null;
        const out = [];
        let n = 0;
        const s = ev.start;
        const emit = date => {
            if (n >= count || date.getTime() > until)
                return false;
            n++;
            if (!ev.exdates.includes(date.getTime()) && date.getTime() < to && date.getTime() + dur > from)
                out.push(make(date));
            return true;
        };
        for (let i = 0; i < 2000; i++) {
            let date;
            if (freq === "DAILY")
                date = new Date(s.getFullYear(), s.getMonth(), s.getDate() + i * interval, s.getHours(), s.getMinutes(), s.getSeconds());
            else if (freq === "WEEKLY") {
                const weekStart = new Date(s.getFullYear(), s.getMonth(), s.getDate() - s.getDay() + i * 7 * interval, s.getHours(), s.getMinutes(), s.getSeconds());
                const set = (byday ?? [s.getDay()]).slice().sort((a, b) => a - b);
                let stop = false;
                for (const wd of set) {
                    const d = new Date(weekStart.getFullYear(), weekStart.getMonth(), weekStart.getDate() + wd, s.getHours(), s.getMinutes(), s.getSeconds());
                    if (d < s)
                        continue;
                    if (!emit(d)) {
                        stop = true;
                        break;
                    }
                }
                if (stop || weekStart.getTime() > to)
                    break;
                continue;
            } else if (freq === "MONTHLY")
                date = new Date(s.getFullYear(), s.getMonth() + i * interval, s.getDate(), s.getHours(), s.getMinutes(), s.getSeconds());
            else if (freq === "YEARLY")
                date = new Date(s.getFullYear() + i * interval, s.getMonth(), s.getDate(), s.getHours(), s.getMinutes(), s.getSeconds());
            else
                break;
            if (date.getTime() > to || !emit(date))
                break;
        }
        return out;
    }

    function _build(text) {
        const from = Date.now() - 366 * 86400000, to = Date.now() + 366 * 86400000;
        let all = [];
        for (const ev of _parse(text))
            if (!isNaN(ev.start.getTime()))
                all = all.concat(_expand(ev, from, to));
        events = all.sort((a, b) => a.start - b.start);
    }

    // Each source: https → curl, otherwise read the file. Sources go in argv, not the script.
    Process {
        id: fetch
        readonly property string script: "for s in \"$@\"; do case \"$s\" in http*) curl -fsSL --max-time 20 \"$s\";; *) cat \"$s\";; esac; echo; done"
        stdout: StdioCollector {
            onStreamFinished: root._build(text)
        }
    }

    onSourcesChanged: refresh()
    Component.onCompleted: refresh()

    Timer {
        interval: 15 * 60 * 1000
        running: root.sources.length > 0
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.now = Date.now()
    }
}
