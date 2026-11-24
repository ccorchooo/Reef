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
    readonly property real resultsHeight: Math.min(list.contentHeight, Tokens.searchMaxHeight - Tokens.searchFieldHeight - Tokens.space2 * 3)
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

    Connections {
        target: Search
        function onResultsChanged() {
            root.selected = Math.min(root.selected, Math.max(0, Search.results.length - 1));
        }
    }

    // One list of every result, built lazily (only rows in view exist), with a section
    // header above the first row of each section.
    ListView {
        id: list
        anchors.bottom: field.top
        anchors.bottomMargin: Tokens.space2
        width: parent.width
        height: root.resultsHeight
        visible: root.hasResults
        clip: true
        spacing: Tokens.spaceHalf
        boundsBehavior: Flickable.StopAtBounds
        reuseItems: true
        model: Search.results
        currentIndex: root.selected
        highlightFollowsCurrentItem: false
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

        delegate: Column {
            id: entry
            required property var modelData
            required property int index
            readonly property bool firstOfSection: index === 0 || Search.results[index - 1]?.section !== modelData.section
            width: list.width
            spacing: Tokens.spaceHalf

            StyledText {
                visible: entry.firstOfSection
                style: "searchSection"
                font.capitalization: Font.AllUppercase
                color: Colors.on.surfaceVariant
                leftPadding: Tokens.space3
                topPadding: Tokens.space2
                bottomPadding: Tokens.spaceHalf
                text: entry.modelData.section
                Accessible.role: Accessible.Heading
            }

            SearchRow {
                width: list.width
                result: entry.modelData
                selected: entry.index === root.selected
                onActivated: root.run(entry.index)
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
                list.positionViewAtBeginning();
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
