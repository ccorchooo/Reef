import QtQuick
import qs.theme

// An M3 Expressive connected button group (screens/Settings: Colorfulness, Theme).
// Equal widths, space-half apart. The ends are rounded fully on the outside and radius-sm
// inside; the selected one becomes a full primary pill with a check (spatial-fast for the
// shape, effects-default for the color). Left/Right move the selection.
//
//   SegmentedButtons { options: [{ value: "auto", label: "Auto" }, …]; current: …; onSelected: v => … }
Row {
    id: root

    property var options: []                  // [{ value, label }]
    property string current: ""
    property string label: ""                 // for screen readers
    signal selected(string value)

    spacing: Tokens.spaceHalf
    readonly property real cell: (width - spacing * (options.length - 1)) / Math.max(1, options.length)

    Accessible.role: Accessible.Grouping
    Accessible.name: label

    Repeater {
        model: root.options

        Item {
            id: seg
            required property var modelData
            required property int index
            readonly property bool on: modelData.value === root.current
            readonly property bool first: index === 0
            readonly property bool last: index === root.options.length - 1

            width: root.cell
            height: Tokens.settingsSegmentHeight

            activeFocusOnTab: true
            Accessible.role: Accessible.RadioButton
            Accessible.name: modelData.label
            Accessible.checked: on
            Keys.onReturnPressed: root.selected(modelData.value)
            Keys.onSpacePressed: root.selected(modelData.value)
            Keys.onLeftPressed: root.selected(root.options[Math.max(0, index - 1)].value)
            Keys.onRightPressed: root.selected(root.options[Math.min(root.options.length - 1, index + 1)].value)

            readonly property real full: height / 2
            readonly property real inner: segMouse.pressed ? Tokens.radiusXs : Tokens.radiusSm
            Spring { id: rl; spec: Motion.spatialFast; target: seg.on || seg.first ? seg.full : seg.inner }
            Spring { id: rr; spec: Motion.spatialFast; target: seg.on || seg.last ? seg.full : seg.inner }
            ColorSpring { id: fill; target: seg.on ? Colors.primary : Colors.surfaceContainerHighest }

            Rectangle {
                anchors.fill: parent
                color: fill.value
                topLeftRadius: rl.value
                bottomLeftRadius: rl.value
                topRightRadius: rr.value
                bottomRightRadius: rr.value
                border.width: seg.activeFocus ? 2 : 0
                border.color: seg.on ? Colors.on.surface : Colors.primary

                Rectangle {
                    anchors.fill: parent
                    topLeftRadius: parent.topLeftRadius
                    bottomLeftRadius: parent.bottomLeftRadius
                    topRightRadius: parent.topRightRadius
                    bottomRightRadius: parent.bottomRightRadius
                    color: seg.on ? Colors.on.primary : Colors.on.surface
                    opacity: segMouse.pressed ? Tokens.statePressedOpacity : segMouse.containsMouse ? Tokens.stateHoverOpacity : 0
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: Tokens.cayPaddingTight
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: seg.on
                    name: "check"
                    size: Tokens.iconXs
                    color: Colors.on.primary
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    style: seg.on ? "segmentLabelEmphasized" : "segmentLabel"
                    color: seg.on ? Colors.on.primary : Colors.on.surface
                    text: seg.modelData.label
                }
            }

            MouseArea {
                id: segMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selected(seg.modelData.value)
            }
        }
    }
}
