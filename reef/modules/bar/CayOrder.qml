import QtQuick
import qs.theme
import qs.services
import qs.components

// Rearranges the bar's cays (edit mode's Bar card, Settings → Bar & Island): one chip per
// cay plus the gap that splits the start group from the end group, in bar order. Drag a
// chip to a new place (the others make room as it moves), or move the focused one with
// the arrow keys. Saved when let go.
Item {
    id: root

    readonly property real gap: Tokens.cayPaddingTight
    readonly property var order: BarCays.shown
    readonly property real cell: (width - gap * (order.length - 1)) / Math.max(1, order.length)

    property string dragging: ""
    property int dropIndex: -1
    readonly property var preview: {
        const o = order.slice();
        if (dragging === "" || dropIndex < 0)
            return o;
        o.splice(o.indexOf(dragging), 1);
        o.splice(Math.min(dropIndex, o.length), 0, dragging);
        return o;
    }

    implicitHeight: Tokens.chipHeight
    Accessible.role: Accessible.List
    Accessible.name: "Cay order"

    function slotX(id) { return Math.max(0, preview.indexOf(id)) * (cell + gap); }
    function moveBy(id, step) {
        const o = order.slice();
        const i = o.indexOf(id), j = Math.max(0, Math.min(o.length - 1, i + step));
        if (i === j)
            return;
        o.splice(i, 1);
        o.splice(j, 0, id);
        BarCays.setShown(o);
    }

    Repeater {
        model: BarCays.all.concat(["|"])

        Item {
            id: chip
            required property string modelData
            readonly property bool present: root.order.includes(modelData)
            readonly property bool held: chipDrag.active
            readonly property bool isGap: modelData === "|"
            // Where the drag started and its offset (the others reflow under it).
            property real startX: 0
            property real dx: 0

            visible: present
            width: root.cell
            height: Tokens.chipHeight
            z: held ? 1 : 0

            Spring { id: sx; spec: Motion.spatialDefault; target: root.slotX(chip.modelData) }
            x: held ? startX + dx : sx.value

            activeFocusOnTab: present
            Accessible.role: Accessible.ListItem
            Accessible.name: `${BarCays.labels[modelData]}, ${root.order.indexOf(modelData) + 1} of ${root.order.length}`
            Keys.onLeftPressed: root.moveBy(modelData, -1)
            Keys.onRightPressed: root.moveBy(modelData, 1)
            Keys.onUpPressed: root.moveBy(modelData, -1)
            Keys.onDownPressed: root.moveBy(modelData, 1)

            DragHandler {
                id: chipDrag
                target: null
                yAxis.enabled: false
                cursorShape: Qt.ClosedHandCursor
                onActiveTranslationChanged: {
                    if (!active)
                        return;
                    chip.dx = activeTranslation.x;
                    const centre = chip.startX + chip.dx + chip.width / 2;
                    root.dropIndex = Math.max(0, Math.min(root.order.length - 1, Math.floor(centre / (root.cell + root.gap))));
                }
                onActiveChanged: {
                    if (active) {
                        chip.startX = sx.value;
                        chip.dx = 0;
                        root.dragging = chip.modelData;
                        root.dropIndex = root.order.indexOf(chip.modelData);
                    } else {
                        sx.restartFrom(chip.startX + chip.dx);
                        const o = root.preview;
                        root.dragging = "";
                        root.dropIndex = -1;
                        BarCays.setShown(o);
                    }
                }
            }
            HoverHandler {
                cursorShape: Qt.OpenHandCursor
            }

            Rectangle {
                anchors.fill: parent
                radius: chip.isGap ? Tokens.radiusSm : height / 2
                color: chip.isGap ? "transparent" : Colors.surfaceContainerHigh
                border.width: chip.activeFocus || chip.held ? 2 : chip.isGap ? 1 : 0
                border.color: chip.activeFocus || chip.held ? Colors.primary : Colors.outline
            }
            Icon {
                anchors.centerIn: parent
                name: BarCays.icons[chip.modelData]
                size: Tokens.iconSm
                color: chip.isGap ? Colors.on.surfaceVariant : Colors.on.surface
            }
        }
    }
}
