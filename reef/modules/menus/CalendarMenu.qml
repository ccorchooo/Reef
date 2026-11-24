import QtQuick
import qs.theme
import qs.services
import qs.components

// Calendar quick menu (screens/QuickMenus): month grid with today on a primary
// cookie shape, a dot under days with events, then the next event.
Column {
    id: root

    width: Tokens.menuCalendarWidth - Tokens.space4 * 2
    spacing: Tokens.space2_5

    property date today: Time.now
    property int year: today.getFullYear()
    property int month: today.getMonth()

    function shift(delta) {
        const d = new Date(year, month + delta, 1);
        year = d.getFullYear();
        month = d.getMonth();
    }

    Keys.onLeftPressed: shift(-1)
    Keys.onRightPressed: shift(1)

    // ── header ──
    Row {
        width: parent.width
        spacing: Tokens.space1

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - prev.width - next.width - parent.spacing * 2
            style: "cardTitle"
            text: Qt.formatDate(new Date(root.year, root.month, 1), "MMMM yyyy")
        }
        CayButton {
            id: prev
            icon: "chevron_left"
            label: "Previous month"
            onClicked: root.shift(-1)
        }
        CayButton {
            id: next
            icon: "chevron_right"
            label: "Next month"
            onClicked: root.shift(1)
        }
    }

    // ── grid ──
    Grid {
        id: grid
        width: parent.width
        columns: 7
        rowSpacing: Tokens.spaceHalf
        readonly property real cell: width / 7
        // Monday first.
        readonly property int offset: (new Date(root.year, root.month, 1).getDay() + 6) % 7
        readonly property int days: new Date(root.year, root.month + 1, 0).getDate()

        Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]
            StyledText {
                required property string modelData
                width: grid.cell
                height: Tokens.calendarWeekdayHeight
                horizontalAlignment: Text.AlignHCenter
                style: "calendarWeekday"
                color: Colors.on.surfaceVariant
                text: modelData
            }
        }

        Repeater {
            model: grid.offset + grid.days

            Item {
                id: day
                required property int index
                readonly property int number: index - grid.offset + 1
                readonly property bool real: number >= 1
                readonly property date date: new Date(root.year, root.month, number)
                readonly property bool isToday: real && root.year === root.today.getFullYear() && root.month === root.today.getMonth() && number === root.today.getDate()
                readonly property bool hasEvents: real && Calendar.eventsOn(date).length > 0

                width: grid.cell
                height: Tokens.calendarDay

                Accessible.role: Accessible.StaticText
                Accessible.name: real ? Qt.formatDate(date, "dddd d MMMM") + (isToday ? ", today" : "") + (hasEvents ? ", has events" : "") : ""

                ShapeItem {
                    anchors.centerIn: parent
                    visible: day.isToday
                    width: Tokens.calendarDay
                    height: Tokens.calendarDay
                    radii: Shapes.sample("cookie9", width, height)
                    color: Colors.primary
                }
                StyledText {
                    anchors.centerIn: parent
                    visible: day.real
                    style: "calendarDay"
                    weight: day.isToday ? 700 : Type.spec("calendarDay").weight
                    color: day.isToday ? Colors.on.primary : Colors.on.surface
                    text: day.number
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Tokens.spaceHalf
                    visible: day.hasEvents && !day.isToday
                    width: Tokens.eventDot
                    height: Tokens.eventDot
                    radius: width / 2
                    color: Colors.tertiaryContainer
                }
            }
        }
    }

    // ── next event ──
    Rectangle {
        width: parent.width
        height: eventRow.implicitHeight + Tokens.space2_5 * 2
        radius: Tokens.radiusLg
        color: Colors.surfaceContainerHigh
        visible: Calendar.next !== null

        Row {
            id: eventRow
            x: Tokens.space3
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Tokens.space3 * 2
            spacing: Tokens.space2_5

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Tokens.eventDot
                height: Tokens.eventBarHeight
                radius: width / 2
                color: Colors.tertiaryContainer
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - Tokens.eventDot - parent.spacing
                StyledText {
                    width: parent.width
                    style: "tileLabel"
                    elide: Text.ElideRight
                    text: Calendar.next?.title ?? ""
                }
                StyledText {
                    width: parent.width
                    style: "bodySm"
                    color: Colors.on.surfaceVariant
                    elide: Text.ElideRight
                    text: Calendar.describe(Calendar.next) + (Calendar.next?.location ? " · " + Calendar.next.location : "")
                }
            }
        }
    }
}
