import QtQuick
import qs.theme
import qs.services
import qs.components
import qs.modules

// The inside of the search panel (screens/Search): grouped results above, the field at
// the bottom where the Navigator cay was. The Navigator cay grows around it.
// Up/Down move the selection, Enter opens it, Escape closes. Results come from Search.
Item {
    id: root

    property int selected: 0

    readonly property bool hasResults: Search.results.length > 0
    readonly property real resultsHeight: Math.min(list.implicitHeight, Tokens.searchMaxHeight - Tokens.searchFieldHeight - Tokens.space2 * 3)
    implicitHeight: (hasResults ? resultsHeight + Tokens.space2 : 0) + Tokens.searchFieldHeight

    // Start a new search: empty field, keyboard in it.
    function open() {
        input.text = "";
        selected = 0;
        input.forceActiveFocus();
    }

    function run(index) {
        const result = Search.results[index];
        if (!result)
            return;
        // Close first: a result may open a panel of its own (a quick menu).
        PanelState.closeAll();
        Search.activate(result);
    }

    function move(by) {
        const n = Search.results.length;
        if (n > 0)
            selected = (selected + by + n) % n;
    }

    // Keep the selected row in view.
    function reveal(row) {
        const y = row.mapToItem(list, 0, 0).y;
        if (y < flick.contentY)
            flick.contentY = y;
        else if (y + row.height > flick.contentY + flick.height)
            flick.contentY = y + row.height - flick.height;
    }

    Connections {
        target: Search
        function onResultsChanged() {
            root.selected = Math.min(root.selected, Math.max(0, Search.results.length - 1));
        }
    }

    Flickable {
        id: flick
        anchors.bottom: field.top
        anchors.bottomMargin: Tokens.space2
        width: parent.width
        height: root.resultsHeight
        visible: root.hasResults
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: list
            width: flick.width
            spacing: Tokens.spaceHalf

            Repeater {
                model: Search.sections

                Column {
                    id: section
                    required property var modelData
                    required property int index
                    // Index of this section's first row among all results.
                    readonly property int offset: Search.sections.slice(0, index).reduce((n, s) => n + s.items.length, 0)
                    width: list.width
                    spacing: Tokens.spaceHalf

                    StyledText {
                        style: "searchSection"
                        font.capitalization: Font.AllUppercase
                        color: Colors.on.surfaceVariant
                        leftPadding: Tokens.space3
                        topPadding: Tokens.space2
                        bottomPadding: Tokens.spaceHalf
                        text: section.modelData.title
                        Accessible.role: Accessible.Heading
                    }

                    Repeater {
                        model: section.modelData.items

                        SearchRow {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property int flatIndex: section.offset + index
                            width: list.width
                            result: modelData
                            selected: flatIndex === root.selected
                            onSelectedChanged: if (selected) root.reveal(row)
                            onActivated: root.run(flatIndex)
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: field
        anchors.bottom: parent.bottom
        width: parent.width
        height: Tokens.searchFieldHeight
        radius: height / 2
        color: Colors.surfaceContainerLowest
        border.width: 2
        border.color: Colors.primary

        Icon {
            id: glass
            anchors.verticalCenter: parent.verticalCenter
            x: Tokens.space4
            name: "search"
            size: Tokens.iconMd
            color: Colors.primary
        }

        TextInput {
            id: input
            anchors.verticalCenter: parent.verticalCenter
            x: glass.x + glass.width + Tokens.space2_5
            width: parent.width - x - Tokens.space4
            font: Type.font("searchField")
            color: Colors.on.surface
            selectionColor: Colors.primaryContainer
            selectedTextColor: Colors.on.primaryContainer
            clip: true
            selectByMouse: true

            Accessible.role: Accessible.EditableText
            Accessible.name: "Search"

            onTextChanged: {
                Search.query = text;
                root.selected = 0;
                flick.contentY = 0;
            }
            Keys.onUpPressed: root.move(-1)
            Keys.onDownPressed: root.move(1)
            Keys.onTabPressed: root.move(1)
            Keys.onBacktabPressed: root.move(-1)
            Keys.onReturnPressed: root.run(root.selected)
            Keys.onEnterPressed: root.run(root.selected)
            Keys.onEscapePressed: PanelState.closeAll()
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            x: input.x
            visible: input.text === ""
            style: "searchField"
            color: Colors.on.surfaceVariant
            text: "Search"
        }
    }
}
