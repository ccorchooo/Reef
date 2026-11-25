import QtQuick
import qs.theme
import qs.components
import qs.modules.menus

// Calendar home widget: the calendar quick menu's month grid and next event on a
// surface-container-high radius-xl card (same card as the system widget).
Rectangle {
    id: root

    readonly property real outlineRadius: radius
    property bool interactive: true

    implicitWidth: Tokens.widgetCalendarWidth
    implicitHeight: month.implicitHeight + Tokens.tilePadding * 2
    radius: Tokens.radiusXl
    color: Colors.surfaceContainerHigh

    Accessible.role: Accessible.Grouping
    Accessible.name: "Calendar"

    CalendarMenu {
        id: month
        x: Tokens.tilePadding
        y: Tokens.tilePadding
        width: root.width - Tokens.tilePadding * 2
        enabled: root.interactive
    }
}
