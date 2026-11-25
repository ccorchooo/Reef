import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.theme
import qs.services
import qs.components

// The Island's Shelf tab (parts/Island-Shelf). "Shelf" and the count, Clear, then the
// items four to a row: files with a badge (images get the rounded-leaf badge), text as
// a mono snippet. Drag a tile out to drop it into another app; click it to open it (or
// copy text). The last cell is the drop zone; dropping anywhere on the Island works
// (the Island passes drops to Shelf.addDrop and comes here).
Column {
    id: root

    spacing: Tokens.space3_5

    // The Island sets this while something is dragged over it.
    property bool dragOver: false
    readonly property int columns: 4
    readonly property real cell: (width - grid.columnSpacing * (columns - 1)) / columns

    function focusFirst() {
        (tiles.count > 0 ? tiles.itemAt(0) : clear).forceActiveFocus();
    }

    function open(item) {
        if (item.kind === "text")
            Quickshell.execDetached(["wl-copy", "--", item.text]);
        else
            Quickshell.execDetached(["xdg-open", item.path]);
        IslandState.close();
    }

    Item {
        width: parent.width
        height: Tokens.chipHeight

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.space2
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                style: "titleMdEmphasized"
                color: Colors.on.island
                text: "Shelf"
                Accessible.role: Accessible.Heading
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                style: "bodySm"
                color: Colors.on.islandVariant
                text: Shelf.count === 1 ? "1 item" : `${Shelf.count} items`
            }
        }
        IslandTextButton {
            id: clear
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: Shelf.count > 0
            text: "Clear"
            onClicked: Shelf.clear()
        }
    }

    Grid {
        id: grid
        width: parent.width
        columns: root.columns
        columnSpacing: Tokens.space2_5
        rowSpacing: Tokens.space2_5

        Repeater {
            id: tiles
            model: Shelf.items

            Item {
                id: tile
                required property var modelData
                required property int index
                readonly property var item: modelData
                readonly property bool isText: item.kind === "text"

                width: root.cell
                height: Tokens.shelfTileHeight

                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: isText ? "Text: " + item.text : item.name
                Keys.onReturnPressed: root.open(item)
                Keys.onSpacePressed: root.open(item)
                Keys.onDeletePressed: Shelf.remove(index)

                // Drag out to another app: files as URIs, text as text.
                Drag.dragType: Drag.Automatic
                Drag.supportedActions: Qt.CopyAction
                Drag.mimeData: isText ? { "text/plain": item.text } : { "text/uri-list": "file://" + encodeURI(item.path) }
                Drag.active: drag.active
                DragHandler {
                    id: drag
                    target: null
                }
                // The picture the pointer carries: grabbed ahead, while hovered.
                function grab() {
                    tile.grabToImage(r => tile.Drag.imageSource = r.url);
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Tokens.radiusLg
                    color: hover.hovered ? Colors.islandContainerHigh : Colors.islandContainer
                    border.width: tile.activeFocus ? 2 : 0
                    border.color: Colors.islandAccent
                }

                HoverHandler {
                    id: hover
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: if (hovered) tile.grab()
                }
                TapHandler {
                    onTapped: root.open(tile.item)
                }

                // A file: its badge and name.
                Column {
                    visible: !tile.isText
                    anchors.centerIn: parent
                    width: parent.width - Tokens.space2 * 2
                    spacing: Tokens.space2

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Tokens.shelfTileIcon
                        height: Tokens.shelfTileIcon
                        readonly property bool image: tile.item.kind === "image"
                        radius: image ? width / 2 : Tokens.radiusMd
                        bottomLeftRadius: image ? Tokens.radiusSm : Tokens.radiusMd
                        color: image ? Colors.tertiaryContainer : Colors.primaryContainer
                        Icon {
                            anchors.centerIn: parent
                            name: ({ image: "image", folder: "folder" })[tile.item.kind] ?? "description"
                            filled: true
                            size: Tokens.iconLg
                            color: parent.image ? Colors.on.tertiaryContainer : Colors.on.primaryContainer
                        }
                    }
                    StyledText {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        style: "bodySm"
                        color: Colors.on.island
                        elide: Text.ElideMiddle
                        text: tile.item.name
                    }
                }

                // Text: a glyph and the start of it.
                Column {
                    visible: tile.isText
                    x: Tokens.space3
                    y: Tokens.space3
                    width: parent.width - Tokens.space3 * 2
                    height: parent.height - Tokens.space3 * 2
                    spacing: Tokens.cayPaddingTight
                    clip: true
                    Icon {
                        name: "notes"
                        size: Tokens.iconSm
                        color: Colors.on.islandVariant
                    }
                    StyledText {
                        width: parent.width
                        height: parent.height - Tokens.iconSm - parent.spacing
                        style: "monoSm"
                        color: Colors.on.island
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        verticalAlignment: Text.AlignTop
                        elide: Text.ElideRight
                        text: tile.item.text
                    }
                }

                // Remove, on hover.
                IslandButton {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: Tokens.space1
                    width: Tokens.islandButtonSm
                    height: Tokens.islandButtonSm
                    iconSize: Tokens.iconSm
                    icon: "close"
                    filled: false
                    label: "Remove from the Shelf"
                    opacity: hover.hovered || activeFocus ? 1 : 0
                    color: Colors.islandContainerHigh
                    contentColor: Colors.on.islandVariant
                    onClicked: Shelf.remove(tile.index)
                }
            }
        }

        // The drop zone: a dashed outline in the accent.
        Item {
            width: root.cell
            height: Tokens.shelfTileHeight
            Accessible.role: Accessible.StaticText
            Accessible.name: "Drop to add"

            ShapeItem {
                anchors.fill: parent
                radii: Shapes.sample("squircle", width, height)
                color: Qt.alpha(Colors.islandAccent, root.dragOver ? Tokens.dropTargetOpacity * 2 : Tokens.dropTargetOpacity)
            }
            Shape {
                id: outline
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: "transparent"
                    strokeColor: Colors.islandAccent
                    strokeWidth: 2
                    strokeStyle: ShapePath.DashLine
                    dashPattern: [Tokens.space1 / 2, Tokens.space1 / 2]
                    PathPolyline {
                        path: Shapes.points(Shapes.sample("squircle", outline.width - 2, outline.height - 2), outline.width, outline.height)
                    }
                }
            }
            Column {
                anchors.centerIn: parent
                spacing: Tokens.cayPaddingTight
                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "add"
                    size: Tokens.iconLg
                    color: Colors.islandAccent
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    style: "bodySm"
                    color: Colors.islandAccent
                    text: "Drop to add"
                }
            }
        }
    }
}
