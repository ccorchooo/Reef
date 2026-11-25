import QtQuick
import qs.theme

// A labelled setting on a thick slider (Settings: text size, animation speed). Maps the
// slider's 0..1 onto `from`..`to` in steps of `stepSize`, and shows the value at the end.
//
//   SliderRow { text: "Animation speed"; from: 0.5; to: 2; stepSize: 0.25; value: …; format: v => v + "×"; onMoved: v => … }
Column {
    id: root

    property string text: ""
    property string icon: ""
    property real from: 0
    property real to: 1
    property real stepSize: 0.05
    property real value: 0
    property var format: v => String(v)
    signal moved(real value)

    spacing: Tokens.space2

    Item {
        width: parent.width
        height: label.implicitHeight
        StyledText {
            id: label
            style: "rowLabel"
            text: root.text
        }
        StyledText {
            anchors.right: parent.right
            style: "rowLabel"
            color: Colors.on.surfaceVariant
            text: root.format(root.value)
        }
    }

    ExpressiveSlider {
        width: parent.width
        icon: root.icon
        label: root.text
        step: root.stepSize / (root.to - root.from)
        value: (root.value - root.from) / (root.to - root.from)
        onMoved: v => {
            const raw = root.from + Math.max(0, Math.min(1, v)) * (root.to - root.from);
            const snapped = Math.round(raw / root.stepSize) * root.stepSize;
            root.moved(Math.round(snapped * 1000) / 1000);
        }
    }
}
