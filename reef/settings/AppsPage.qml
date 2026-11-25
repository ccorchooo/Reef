import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.components

// Settings → Apps: default apps (xdg-mime, through DefaultApps), the Dock's pins in order,
// and every installed app with a pin button and a "Show in search" switch.
Column {
    id: root

    spacing: Tokens.settingsGap

    Component.onCompleted: DefaultApps.refresh()

    property string expanded: ""            // the default-app kind whose choices are open
    property string filter: ""
    property bool showAll: false
    readonly property int shortList: 40

    readonly property var allApps: {
        DesktopEntries.applications.values.length;
        const q = filter.trim().toLowerCase();
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay && (q === "" || e.name.toLowerCase().includes(q) || e.id.toLowerCase().includes(q)))
            .sort((a, b) => a.name.localeCompare(b.name));
    }

    component AppIcon: IconImage {
        property var entry: null
        implicitSize: Tokens.appRowIcon
        source: Quickshell.iconPath(entry?.icon ?? "", "application-x-executable")
    }

    // ── default apps ──
    SettingsSection {
        width: parent.width
        title: "Default apps"

        Repeater {
            model: DefaultApps.kinds

            Column {
                id: kindRow
                required property var modelData
                readonly property bool open: root.expanded === modelData.id
                readonly property var chosen: DefaultApps.entryFor(modelData.id)
                width: parent.width
                spacing: Tokens.space2

                // The kind, and the app that opens it now.
                Item {
                    width: parent.width
                    height: Tokens.settingsRowHeight

                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: kindRow.modelData.label + ", " + (kindRow.chosen?.name ?? "not set")
                    Keys.onReturnPressed: root.expanded = kindRow.open ? "" : kindRow.modelData.id
                    Keys.onSpacePressed: root.expanded = kindRow.open ? "" : kindRow.modelData.id

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -Tokens.space2
                        radius: Tokens.radiusLg
                        color: Qt.alpha(Colors.on.surface, kindMouse.containsMouse ? Tokens.stateHoverOpacity : 0)
                        border.width: parent.activeFocus ? 2 : 0
                        border.color: Colors.primary
                    }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Tokens.space3
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: kindRow.modelData.icon
                            size: Tokens.iconMd
                            color: Colors.on.surfaceVariant
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            style: "rowLabel"
                            text: kindRow.modelData.label
                        }
                    }
                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Tokens.space2
                        AppIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: kindRow.chosen !== null
                            entry: kindRow.chosen
                            implicitSize: Tokens.iconLg
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            style: "segmentLabel"
                            color: Colors.on.surfaceVariant
                            text: kindRow.chosen?.name ?? (DefaultApps.loading ? "" : "Not set")
                        }
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: kindRow.open ? "expand_less" : "expand_more"
                            size: Tokens.iconMd
                            color: Colors.on.surfaceVariant
                        }
                    }
                    MouseArea {
                        id: kindMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.expanded = kindRow.open ? "" : kindRow.modelData.id
                    }
                }

                // The apps that can open it.
                Flow {
                    width: parent.width
                    visible: kindRow.open
                    spacing: Tokens.space2

                    StyledText {
                        visible: kindRow.open && DefaultApps.candidates(kindRow.modelData.id).length === 0
                        style: "bodyMd"
                        color: Colors.on.surfaceVariant
                        text: "No installed app opens these"
                    }
                    Repeater {
                        model: kindRow.open ? DefaultApps.candidates(kindRow.modelData.id) : []
                        Item {
                            id: choice
                            required property var modelData
                            readonly property bool selected: DefaultApps.current[kindRow.modelData.id] === modelData.id
                            width: choiceRow.implicitWidth + Tokens.space3 * 2
                            height: Tokens.settingsButtonHeight

                            activeFocusOnTab: true
                            Accessible.role: Accessible.RadioButton
                            Accessible.name: modelData.name
                            Accessible.checked: selected
                            Keys.onReturnPressed: DefaultApps.set(kindRow.modelData.id, modelData.id)
                            Keys.onSpacePressed: DefaultApps.set(kindRow.modelData.id, modelData.id)

                            ColorSpring {
                                id: choiceBg
                                spec: Motion.effectsDefault
                                target: choice.selected ? Colors.primaryContainer : Colors.surfaceContainerHighest
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: choiceBg.value
                                border.width: choice.activeFocus ? 2 : 0
                                border.color: Colors.primary
                            }
                            Row {
                                id: choiceRow
                                anchors.centerIn: parent
                                spacing: Tokens.space2
                                AppIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    entry: choice.modelData
                                    implicitSize: Tokens.iconMd
                                }
                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    style: "segmentLabel"
                                    color: choice.selected ? Colors.on.primaryContainer : Colors.on.surface
                                    text: choice.modelData.name
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: DefaultApps.set(kindRow.modelData.id, choice.modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }

    // ── the Dock ──
    SettingsSection {
        width: parent.width
        title: "Dock"

        StyledText {
            visible: Apps.pinnedIds.length === 0
            style: "bodyMd"
            color: Colors.on.surfaceVariant
            text: "No pinned apps"
        }
        Repeater {
            model: Apps.pinnedIds

            Item {
                id: pinRow
                required property string modelData
                required property int index
                readonly property var entry: DesktopEntries.byId(modelData)
                width: parent.width
                height: Tokens.appRowIcon

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.space3
                    AppIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        entry: pinRow.entry
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        style: "rowLabel"
                        text: pinRow.entry?.name ?? pinRow.modelData
                    }
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.space1
                    CayButton {
                        icon: "arrow_upward"
                        label: "Move " + (pinRow.entry?.name ?? "app") + " earlier"
                        enabled: pinRow.index > 0
                        opacity: enabled ? 1 : Tokens.disabledOpacity
                        onClicked: Apps.movePin(pinRow.modelData, -1)
                    }
                    CayButton {
                        icon: "arrow_downward"
                        label: "Move " + (pinRow.entry?.name ?? "app") + " later"
                        enabled: pinRow.index < Apps.pinnedIds.length - 1
                        opacity: enabled ? 1 : Tokens.disabledOpacity
                        onClicked: Apps.movePin(pinRow.modelData, 1)
                    }
                    CayButton {
                        icon: "keep_off"
                        label: "Unpin " + (pinRow.entry?.name ?? "app")
                        onClicked: Apps.unpin(pinRow.modelData)
                    }
                }
            }
        }
    }

    // ── every app ──
    SettingsSection {
        width: parent.width
        title: "Apps in search"

        // Filter
        Rectangle {
            width: parent.width
            height: Tokens.settingsNavRow
            radius: height / 2
            color: Colors.surfaceContainerHighest
            border.width: filterInput.activeFocus ? 2 : 0
            border.color: Colors.primary

            Icon {
                id: filterIcon
                x: Tokens.space3_5
                anchors.verticalCenter: parent.verticalCenter
                name: "search"
                size: Tokens.iconSm
            }
            TextInput {
                id: filterInput
                anchors.left: filterIcon.right
                anchors.leftMargin: Tokens.space2
                anchors.right: parent.right
                anchors.rightMargin: Tokens.space3_5
                anchors.verticalCenter: parent.verticalCenter
                clip: true
                color: Colors.on.surface
                selectionColor: Colors.primaryContainer
                selectedTextColor: Colors.on.primaryContainer
                font: Type.font("segmentLabel")
                activeFocusOnTab: true
                Accessible.role: Accessible.EditableText
                Accessible.name: "Filter apps"
                onTextChanged: root.filter = text

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: filterInput.text === ""
                    style: "segmentLabel"
                    color: Colors.on.surfaceVariant
                    text: "Filter apps"
                }
            }
        }

        Repeater {
            model: root.showAll || root.filter !== "" ? root.allApps : root.allApps.slice(0, root.shortList)

            Item {
                id: appRow
                required property var modelData
                readonly property bool pinned: Apps.pinnedIds.includes(modelData.id)
                readonly property bool shown: !Config.options.apps.hidden.includes(modelData.id)
                width: parent.width
                height: Math.max(Tokens.appRowIcon, Tokens.switchHeight)

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.space3
                    AppIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        entry: appRow.modelData
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        width: appRow.width - Tokens.appRowIcon - Tokens.cayButton - Tokens.switchWidth - Tokens.space3 * 3
                        style: "rowLabel"
                        elide: Text.ElideRight
                        opacity: appRow.shown ? 1 : Tokens.disabledOpacity
                        text: appRow.modelData.name
                    }
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.space3
                    CayButton {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "keep"
                        selected: appRow.pinned
                        label: (appRow.pinned ? "Unpin " : "Pin ") + appRow.modelData.name + (appRow.pinned ? " from the Dock" : " to the Dock")
                        onClicked: Apps.togglePin(appRow.modelData.id)
                    }
                    Switch {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: appRow.shown
                        label: "Show " + appRow.modelData.name + " in search"
                        onToggled: Apps.setHidden(appRow.modelData.id, appRow.shown)
                    }
                }
            }
        }

        PillButton {
            visible: !root.showAll && root.filter === "" && root.allApps.length > root.shortList
            width: parent.width
            height: Tokens.settingsButtonHeight
            neutralColor: Colors.surfaceContainerHighest
            text: `Show all ${root.allApps.length} apps`
            onClicked: root.showAll = true
        }
    }
}
