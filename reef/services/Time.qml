pragma Singleton
import QtQuick
import Quickshell

// Wall clock for the shell. The format is Settings → Bar → Clock format.
Singleton {
    id: root

    readonly property date now: clock.date
    readonly property string time: Qt.formatTime(clock.date, Config.options.bar.clockFormat)
    readonly property string date: Qt.formatDate(clock.date, "dddd d MMMM")

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
