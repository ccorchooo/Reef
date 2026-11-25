import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.components

// The Settings app (SURFACES.md → Settings app; screens/Settings). A normal window
// (Hyprland draws its rounding and border) with a sidebar on surface-container: the
// search field, then one row per page, the current one on secondary-container. The page
// sits on surface-container-low with its title in settings-title. Typing in the search
// field lists the matching settings across pages; picking one opens its page.
// The close button, or closing the window, leaves; it remembers the page.
FloatingWindow {
    id: root

    title: "Settings"
    implicitWidth: Tokens.settingsWidth
    implicitHeight: Tokens.settingsHeight
    minimumSize: Qt.size(Tokens.settingsNavWidth + Tokens.settingsWidth / 2, Tokens.settingsHeight / 2)
    color: Colors.surfaceContainerLow

    onClosed: SettingsState.close()

    readonly property var results: {
        const q = SettingsState.query.trim().toLowerCase();
        if (q === "")
            return [];
        return SettingsState.index
            .filter(e => e[1].toLowerCase().includes(q) || e[2].includes(q) || SettingsState.title(e[0]).toLowerCase().includes(q))
            .map(e => ({ page: e[0], label: e[1] }));
    }
    readonly property bool searching: SettingsState.query.trim() !== ""

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: {
            if (root.searching)
                SettingsState.query = "";
            else
                SettingsState.close();
        }

        // ── sidebar ──
        Rectangle {
            id: nav
            width: Tokens.settingsNavWidth
            height: parent.height
            color: Colors.surfaceContainer

            Accessible.role: Accessible.PageTabList
            Accessible.name: "Settings sections"

            Column {
                x: Tokens.space3
                y: Tokens.space4
                width: parent.width - Tokens.space3 * 2
                spacing: Tokens.spaceHalf

                // Search settings
                Rectangle {
                    width: parent.width
                    height: Tokens.settingsNavRow
                    radius: height / 2
                    color: Colors.surfaceContainerLow
                    border.width: search.activeFocus ? 2 : 0
                    border.color: Colors.primary

                    Icon {
                        id: searchIcon
                        x: Tokens.space3_5
                        anchors.verticalCenter: parent.verticalCenter
                        name: "search"
                        size: Tokens.iconSm
                    }
                    TextInput {
                        id: search
                        anchors.left: searchIcon.right
                        anchors.leftMargin: Tokens.space2
                        anchors.right: parent.right
                        anchors.rightMargin: Tokens.space3_5
                        anchors.verticalCenter: parent.verticalCenter
                        clip: true
                        color: Colors.on.surface
                        selectionColor: Colors.primaryContainer
                        selectedTextColor: Colors.on.primaryContainer
                        font: Type.font("segmentLabel")
                        text: SettingsState.query
                        onTextChanged: SettingsState.query = text
                        activeFocusOnTab: true
                        Accessible.role: Accessible.EditableText
                        Accessible.name: "Search settings"
                        Keys.onReturnPressed: if (root.results.length > 0) root.pick(root.results[0].page)

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: search.text === ""
                            style: "segmentLabel"
                            color: Colors.on.surfaceVariant
                            text: "Search settings"
                        }
                    }
                }
                Item {
                    width: 1
                    height: Tokens.space2 - parent.spacing
                }

                Repeater {
                    model: SettingsState.pages

                    Item {
                        id: navRow
                        required property var modelData
                        required property int index
                        readonly property bool current: !root.searching && SettingsState.page === modelData.id
                        readonly property bool matches: !root.searching || root.results.some(r => r.page === modelData.id)

                        width: parent.width
                        height: Tokens.settingsNavRow
                        opacity: matches ? 1 : Tokens.disabledOpacity

                        activeFocusOnTab: true
                        Accessible.role: Accessible.PageTab
                        Accessible.name: modelData.title
                        Accessible.selected: current
                        Keys.onReturnPressed: root.pick(modelData.id)
                        Keys.onSpacePressed: root.pick(modelData.id)
                        Keys.onUpPressed: nextItemInFocusChain(false)?.forceActiveFocus()
                        Keys.onDownPressed: nextItemInFocusChain(true)?.forceActiveFocus()

                        ColorSpring {
                            id: navBg
                            spec: Motion.effectsFast
                            target: navRow.current ? Colors.secondaryContainer : Qt.alpha(Colors.secondaryContainer, 0)
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: navBg.value
                            border.width: navRow.activeFocus ? 2 : 0
                            border.color: Colors.primary

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: Colors.on.surface
                                opacity: navMouse.pressed ? Tokens.statePressedOpacity : navMouse.containsMouse && !navRow.current ? Tokens.stateHoverOpacity : 0
                            }
                        }
                        Row {
                            x: Tokens.space3_5
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Tokens.space3
                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: navRow.modelData.icon
                                filled: navRow.current
                                size: Tokens.iconMd
                                color: navRow.current ? Colors.on.secondaryContainer : Colors.on.surface
                            }
                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                style: navRow.current ? "tileLabel" : "segmentLabel"
                                color: navRow.current ? Colors.on.secondaryContainer : Colors.on.surface
                                text: navRow.modelData.title
                            }
                        }
                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.pick(navRow.modelData.id)
                        }
                    }
                }
            }
        }

        // ── page ──
        Flickable {
            id: flick
            anchors.left: nav.right
            anchors.right: parent.right
            height: parent.height
            contentHeight: page.implicitHeight + Tokens.space6 * 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: page
                x: Tokens.settingsPagePadding
                y: Tokens.space6
                width: flick.width - Tokens.settingsPagePadding * 2
                spacing: Tokens.settingsGap

                StyledText {
                    width: parent.width - Tokens.settingsClose - Tokens.space2
                    style: "settingsTitle"
                    elide: Text.ElideRight
                    text: root.searching ? "Search" : SettingsState.title(SettingsState.page)
                    Accessible.role: Accessible.Heading
                }

                // Search results
                Column {
                    width: parent.width
                    visible: root.searching
                    spacing: Tokens.spaceHalf

                    StyledText {
                        visible: root.results.length === 0
                        style: "bodyMd"
                        color: Colors.on.surfaceVariant
                        text: "No settings match"
                    }
                    Repeater {
                        model: root.searching ? root.results : []
                        ListRow {
                            required property var modelData
                            width: page.width
                            icon: SettingsState.pages.find(p => p.id === modelData.page)?.icon ?? ""
                            title: modelData.label
                            subtitle: SettingsState.title(modelData.page)
                            onClicked: root.pick(modelData.page)
                        }
                    }
                }

                Loader {
                    id: pageLoader
                    width: parent.width
                    visible: !root.searching
                    source: ({
                        look: "LookPage.qml",
                        displays: "DisplaysPage.qml",
                        bar: "BarIslandPage.qml",
                        sound: "SoundPage.qml",
                        network: "NetworkPage.qml",
                        bluetooth: "BluetoothPage.qml",
                        coral: "CoralPage.qml",
                        keyboard: "KeyboardPage.qml",
                        power: "PowerPage.qml",
                        accessibility: "AccessibilityPage.qml",
                        about: "AboutPage.qml"
                    })[SettingsState.page] ?? ""
                    opacity: pageFade.value
                    Spring {
                        id: pageFade
                        spec: Motion.effectsDefault
                        target: 1
                    }
                    onSourceChanged: {
                        pageFade.restartFrom(0);
                        flick.contentY = 0;
                    }
                }
            }
        }

        // Close
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.space3
            width: Tokens.settingsClose
            height: Tokens.settingsClose
            radius: height / 2
            color: Colors.surfaceContainerHigh
            CayButton {
                anchors.fill: parent
                size: Tokens.settingsClose
                icon: "close"
                iconSize: Tokens.iconSm
                label: "Close settings"
                onClicked: SettingsState.close()
            }
        }
    }

    function pick(id) {
        SettingsState.query = "";
        SettingsState.page = id;
    }
}
