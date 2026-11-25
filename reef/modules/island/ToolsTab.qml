import QtQuick
import qs.theme
import qs.services
import qs.components

// The Island's Tools tab (parts/Island-Tools; the Island is island-tools-width here).
// A switcher on island-container: the chosen tool widens to show its name, the others are
// icons. Calculator, Emoji (Super+.), Color picker, Screenshot.
Column {
    id: root

    spacing: Tokens.space3

    readonly property var tools: [
        { id: "calculator", icon: "calculate", label: "Calculator" },
        { id: "emoji", icon: "mood", label: "Emoji" },
        { id: "color", icon: "colorize", label: "Color picker" },
        { id: "screenshot", icon: "screenshot_region", label: "Screenshot" }
    ]
    readonly property string page: IslandState.toolsPage

    function focusFirst() {
        if (page === "emoji") {
            emojiSearch.clear();
            emojiSearch.forceActiveFocus();
        } else if (page === "calculator") {
            calculator.forceActiveFocus();
        } else {
            switcher.itemAt(tools.findIndex(t => t.id === page))?.forceActiveFocus();
        }
    }
    onPageChanged: if (visible) Qt.callLater(focusFirst)

    // ── switcher ────────────────────────────────────────────────
    Rectangle {
        width: parent.width
        height: Tokens.chipHeight + Tokens.space1 * 2
        radius: height / 2
        color: Colors.islandContainer

        Row {
            id: segments
            x: Tokens.space1
            y: Tokens.space1
            spacing: Tokens.space1
            readonly property real wide: parent.width - Tokens.space1 * 2 - (root.tools.length - 1) * (Tokens.toolSegmentWidth + spacing)

            Repeater {
                id: switcher
                model: root.tools

                Item {
                    id: seg
                    required property var modelData
                    required property int index
                    readonly property bool current: root.page === modelData.id
                    width: w.value
                    height: Tokens.chipHeight

                    activeFocusOnTab: true
                    Accessible.role: Accessible.PageTab
                    Accessible.name: modelData.label
                    Accessible.selected: current
                    Keys.onReturnPressed: IslandState.toolsPage = modelData.id
                    Keys.onSpacePressed: IslandState.toolsPage = modelData.id
                    Keys.onLeftPressed: switcher.itemAt(Math.max(0, index - 1))?.forceActiveFocus()
                    Keys.onRightPressed: switcher.itemAt(Math.min(switcher.count - 1, index + 1))?.forceActiveFocus()

                    Spring {
                        id: w
                        spec: Motion.spatialDefault
                        target: seg.current ? segments.wide : Tokens.toolSegmentWidth
                    }
                    ColorSpring {
                        id: fill
                        spec: Motion.effectsDefault
                        target: seg.current ? Colors.islandAccent : mouse.containsMouse ? Colors.islandContainerHigh : Qt.alpha(Colors.islandContainerHigh, 0)
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: fill.value
                        border.width: seg.activeFocus ? 2 : 0
                        border.color: seg.current ? Colors.on.islandAccent : Colors.islandAccent
                    }
                    Row {
                        anchors.centerIn: parent
                        spacing: Tokens.space1 + Tokens.spaceHalf
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: seg.modelData.icon
                            size: Tokens.iconSm
                            filled: seg.current
                            color: seg.current ? Colors.on.islandAccent : Colors.on.islandVariant
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: seg.current && seg.width > Tokens.toolSegmentWidth * 2
                            opacity: Math.max(0, Math.min(1, (seg.width - Tokens.toolSegmentWidth * 2) / Tokens.toolSegmentWidth))
                            style: "tileLabel"
                            color: Colors.on.islandAccent
                            text: seg.modelData.label
                        }
                    }
                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: IslandState.toolsPage = seg.modelData.id
                    }
                }
            }
        }
    }

    // ── calculator ──────────────────────────────────────────────
    FocusScope {
        id: calculator
        visible: root.page === "calculator"
        width: parent.width
        height: calcColumn.implicitHeight

        // Typing works while the calculator is shown.
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.text === "=")
                Calculator.press("=");
            else if (event.key === Qt.Key_Backspace)
                Calculator.press("⌫");
            else if (event.key === Qt.Key_Delete)
                Calculator.press("C");
            else if (event.text !== "")
                Calculator.type(event.text);
            else
                return;
            event.accepted = true;
        }

        Column {
            id: calcColumn
            width: parent.width
            spacing: Tokens.space3

            // The display; tap it to clear.
            Rectangle {
                width: parent.width
                height: Tokens.calculatorDisplayHeight
                radius: Tokens.radiusLg
                color: Colors.islandContainer
                Accessible.role: Accessible.Button
                Accessible.name: "Result " + Calculator.result + ". Clear"

                Column {
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.space4
                    anchors.verticalCenter: parent.verticalCenter
                    StyledText {
                        anchors.right: parent.right
                        style: "monoMd"
                        color: Colors.on.islandVariant
                        text: (Calculator.previous || Calculator.expression).replace(/([+−×÷^])/g, " $1 ").replace(/^ − /, "−")
                    }
                    StyledText {
                        anchors.right: parent.right
                        style: "calculatorResult"
                        color: Colors.on.island
                        font.features: ({ tnum: 1 })
                        text: Calculator.result
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Calculator.clear();
                        calculator.forceActiveFocus();
                    }
                }
            }

            Grid {
                id: keys
                width: parent.width
                columns: 4
                spacing: Tokens.space2
                readonly property real keyWidth: (width - spacing * 3) / 4

                Repeater {
                    model: ["7", "8", "9", "÷", "4", "5", "6", "×", "1", "2", "3", "−", "0", ".", "=", "+"]

                    IslandTextButton {
                        required property string modelData
                        readonly property bool op: Calculator.operators.includes(modelData)
                        readonly property bool pending: Calculator.pendingOperator === modelData
                        width: keys.keyWidth
                        height: Tokens.calculatorKeyHeight
                        text: modelData
                        label: ({ "÷": "Divide", "×": "Multiply", "−": "Subtract", "+": "Add", "=": "Equals", ".": "Decimal point" })[modelData] ?? modelData
                        textStyle: "calculatorKey"
                        activeFocusOnTab: false
                        // The pending operator stays pressed: accent, corners squashed.
                        radius: pending ? Tokens.radiusIslandIcon : height / 2
                        color: modelData === "=" ? Colors.tertiaryContainer : pending ? Colors.islandAccent : op ? Colors.primaryContainer : Colors.islandContainerHigh
                        contentColor: modelData === "=" ? Colors.on.tertiaryContainer : pending ? Colors.on.islandAccent : op ? Colors.on.primaryContainer : Colors.on.island
                        onClicked: {
                            Calculator.press(modelData);
                            calculator.forceActiveFocus();
                        }
                    }
                }
            }
        }
    }

    // ── emoji ───────────────────────────────────────────────────
    Column {
        visible: root.page === "emoji"
        width: parent.width
        spacing: Tokens.space3

        IslandSearchField {
            id: emojiSearch
            width: parent.width
            placeholder: "Search emoji"
            onTextChanged: {
                Emoji.query = text;
                grid.currentIndex = 0;
            }
            onMoved: by => grid.currentIndex = Math.max(0, Math.min(grid.count - 1, grid.currentIndex + by * grid.columns))
            onAccepted: grid.choose(grid.currentIndex)
            Keys.onLeftPressed: event => event.accepted = false
        }

        GridView {
            id: grid
            readonly property int columns: Math.floor(width / Tokens.emojiCell)
            width: parent.width
            height: Math.min(Math.ceil(count / Math.max(1, columns)) * Tokens.emojiCell, Tokens.islandListMaxHeight)
            cellWidth: width / Math.max(1, columns)
            cellHeight: Tokens.emojiCell
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.page === "emoji" ? Emoji.results : []
            keyNavigationEnabled: true
            activeFocusOnTab: true

            function choose(i) {
                const e = Emoji.results[i];
                if (!e)
                    return;
                Emoji.copy(e.e);
                IslandState.close();
                Toasts.show({ text: `${e.e} copied`, icon: "mood" });
            }
            Keys.onReturnPressed: choose(currentIndex)
            Keys.onSpacePressed: choose(currentIndex)

            StyledText {
                anchors.centerIn: parent
                visible: grid.count === 0
                style: "islandRowLabel"
                color: Colors.on.islandVariant
                text: "No emoji found"
            }

            delegate: Item {
                id: cell
                required property var modelData
                required property int index
                width: grid.cellWidth
                height: grid.cellHeight
                Accessible.role: Accessible.Button
                Accessible.name: modelData.n

                Rectangle {
                    anchors.centerIn: parent
                    width: Tokens.emojiCell
                    height: Tokens.emojiCell
                    radius: Tokens.radiusMd
                    color: cellMouse.containsMouse || cell.index === grid.currentIndex ? Colors.islandContainerHigh : "transparent"
                    border.width: grid.activeFocus && cell.index === grid.currentIndex ? 2 : 0
                    border.color: Colors.islandAccent
                }
                Text {
                    anchors.centerIn: parent
                    text: cell.modelData.e
                    font.pixelSize: Type.size("emoji")
                    renderType: Text.NativeRendering
                }
                MouseArea {
                    id: cellMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: grid.choose(cell.index)
                }
            }
        }
    }

    // ── color picker ────────────────────────────────────────────
    Column {
        visible: root.page === "color"
        width: parent.width
        spacing: Tokens.space3

        Row {
            visible: ColorPicker.hasColor
            width: parent.width
            spacing: Tokens.space4

            ShapeItem {
                width: Tokens.colorSwatch
                height: Tokens.colorSwatch
                radii: Shapes.sample("cookie9", width, height)
                color: ColorPicker.current
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - Tokens.colorSwatch - parent.spacing
                spacing: Tokens.space1

                Repeater {
                    model: ColorPicker.hasColor ? [ColorPicker.hex(ColorPicker.current), ColorPicker.rgb(ColorPicker.current), ColorPicker.hsl(ColorPicker.current)] : []
                    // Click a value to copy it.
                    IslandTextButton {
                        required property string modelData
                        text: modelData
                        label: "Copy " + modelData
                        icon: "content_copy"
                        textStyle: "monoMd"
                        color: Qt.alpha(Colors.islandContainerHigh, 0)
                        contentColor: Colors.on.island
                        padding: Tokens.space2
                        onClicked: ColorPicker.copy(modelData)
                    }
                }
            }
        }

        Row {
            visible: ColorPicker.history.length > 1
            spacing: Tokens.space2
            Repeater {
                model: ColorPicker.history
                Rectangle {
                    required property color modelData
                    width: Tokens.chipHeight
                    height: Tokens.chipHeight
                    radius: width / 2
                    color: modelData
                    border.width: Qt.colorEqual(modelData, ColorPicker.current) ? 2 : 0
                    border.color: Colors.on.island
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: ColorPicker.hex(modelData)
                    Keys.onReturnPressed: ColorPicker.current = modelData
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ColorPicker.current = parent.modelData
                    }
                }
            }
        }

        IslandTextButton {
            width: parent.width
            height: Tokens.dialogButtonHeight
            text: "Pick a color"
            icon: "colorize"
            textStyle: "buttonLabelEmphasized"
            color: Colors.islandAccent
            contentColor: Colors.on.islandAccent
            enabledState: !ColorPicker.busy
            onClicked: {
                IslandState.close();
                ColorPicker.pick();
            }
        }
    }

    // ── screenshot ──────────────────────────────────────────────
    Row {
        visible: root.page === "screenshot"
        width: parent.width
        spacing: Tokens.space2

        Repeater {
            model: [
                { mode: "region", icon: "screenshot_region", label: "Region" },
                { mode: "window", icon: "select_window", label: "Window" },
                { mode: "screen", icon: "fullscreen", label: "Screen" }
            ]
            IslandTextButton {
                required property var modelData
                width: (parent.width - parent.spacing * 2) / 3
                height: Tokens.dialogButtonHeight
                text: modelData.label
                icon: modelData.icon
                textStyle: "buttonLabel"
                enabledState: !Screenshot.busy
                onClicked: {
                    IslandState.close();
                    Screenshot.take(modelData.mode);
                }
            }
        }
    }
}
