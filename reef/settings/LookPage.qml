import QtQuick
import QtQuick.Dialogs
import Quickshell
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.components

// Settings → Look (screens/Settings): the wallpaper card (preview, seed colors from the
// wallpaper, Change wallpaper, Use static color), the Palette (the wallpaper's colors or a
// classic palette), Colorfulness (wallpaper palette only), then Theme, Transparency and
// Home logo in two columns (one when the window is narrow, as with a large zoom).
Column {
    id: root

    spacing: Tokens.settingsGap

    readonly property var look: Config.options.look
    readonly property string wallpaper: look.wallpaper

    // Seed candidates: the wallpaper's main colors, one per hue family (Scheme reads them),
    // or the reference seed without a wallpaper.
    readonly property var seeds: Scheme.seeds.length > 0 ? Scheme.seeds : [Tokens.seed]
    readonly property bool fromWallpaper: look.palette === "wallpaper"

    function useSeed(hex) {
        Config.options.look.palette = "wallpaper";
        Config.options.look.staticColor = hex;
    }

    function filePath(url) {
        return decodeURIComponent(url.toString().replace(/^file:\/\//, ""));
    }

    FileDialog {
        id: wallpaperDialog
        title: "Choose a wallpaper"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.bmp)"]
        onAccepted: Config.options.look.wallpaper = root.filePath(selectedFile)
    }
    FileDialog {
        id: logoDialog
        title: "Choose a logo"
        nameFilters: ["Images (*.png *.svg *.jpg *.jpeg *.webp)"]
        onAccepted: {
            Config.options.look.homeLogoPath = root.filePath(selectedFile);
            Config.options.look.homeLogo = "custom";
        }
    }

    // ── wallpaper ──
    Rectangle {
        width: parent.width
        height: wallpaperRow.implicitHeight + Tokens.space4 * 2
        radius: Tokens.radiusXl
        color: Colors.surfaceContainerHigh

        Row {
            id: wallpaperRow
            x: Tokens.space4
            y: Tokens.space4
            width: parent.width - Tokens.space4 * 2
            spacing: Tokens.space5

            ShapeImage {
                anchors.verticalCenter: parent.verticalCenter
                width: Tokens.settingsPreviewWidth
                height: Tokens.settingsPreviewHeight
                shape: "squircle"
                source: root.wallpaper !== "" ? "file://" + root.wallpaper : ""
                color: Colors.surfaceContainerHighest
                icon: "wallpaper"
                iconSize: Tokens.settingsOptionGlyph
                iconColor: Colors.on.surfaceVariant

                // The Island, to scale.
                Rectangle {
                    readonly property real k: parent.width / (Quickshell.screens[0]?.width ?? parent.width)
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Tokens.space2 * k
                    width: Tokens.islandCollapsedWidth * k
                    height: Tokens.islandCollapsedHeight * k
                    radius: height / 2
                    color: Colors.island
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - Tokens.settingsPreviewWidth - parent.spacing
                spacing: Tokens.space3

                StyledText {
                    style: "settingsSection"
                    text: "Wallpaper"
                }

                Row {
                    spacing: Tokens.space2_5
                    Accessible.role: Accessible.Grouping
                    Accessible.name: "Seed color"

                    Repeater {
                        model: root.seeds
                        Item {
                            id: swatch
                            required property string modelData
                            required property int index
                            readonly property bool chosen: root.fromWallpaper && (root.look.staticColor !== "" ? root.look.staticColor.toLowerCase() === modelData.toLowerCase() : index === 0)
                            width: Tokens.settingsSwatch
                            height: Tokens.settingsSwatch

                            activeFocusOnTab: true
                            Accessible.role: Accessible.RadioButton
                            Accessible.name: "Seed color " + modelData
                            Accessible.checked: chosen
                            Keys.onReturnPressed: root.useSeed(modelData)
                            Keys.onSpacePressed: root.useSeed(modelData)

                            // The chosen one: a primary ring outside a gap of the card's color.
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + Tokens.space2_5
                                height: width
                                radius: width / 2
                                color: Colors.primary
                                visible: swatch.chosen || swatch.activeFocus
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + Tokens.cayPaddingTight
                                height: width
                                radius: width / 2
                                color: Colors.surfaceContainerHigh
                                visible: swatch.chosen || swatch.activeFocus
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: swatch.modelData
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.useSeed(swatch.modelData)
                            }
                        }
                    }
                }

                Row {
                    spacing: Tokens.space2
                    PillButton {
                        height: Tokens.settingsButtonHeight
                        accent: true
                        text: "Change wallpaper"
                        onClicked: wallpaperDialog.open()
                    }
                    PillButton {
                        height: Tokens.settingsButtonHeight
                        neutralColor: Colors.surfaceContainerHighest
                        text: root.look.staticColor !== "" || !root.fromWallpaper ? "Use wallpaper colors" : "Use static color"
                        onClicked: {
                            const back = root.look.staticColor !== "" || !root.fromWallpaper;
                            Config.options.look.palette = "wallpaper";
                            Config.options.look.staticColor = back ? "" : root.seeds[0];
                        }
                    }
                }
            }
        }
    }

    // ── palette ──
    Column {
        width: parent.width
        spacing: Tokens.space2

        StyledText {
            style: "settingsSection"
            text: "Palette"
        }
        Flow {
            width: parent.width
            spacing: Tokens.space2
            Accessible.role: Accessible.Grouping
            Accessible.name: "Palette"

            // The wallpaper's colors: its seeds as dots.
            OptionCard {
                width: Tokens.settingsPaletteCard
                text: "Wallpaper"
                selected: root.fromWallpaper
                onClicked: Config.options.look.palette = "wallpaper"
                Row {
                    anchors.centerIn: parent
                    spacing: Tokens.spaceHalf
                    Repeater {
                        model: root.seeds.slice(0, 4)
                        Rectangle {
                            required property string modelData
                            width: Tokens.settingsPaletteDot
                            height: width
                            radius: width / 2
                            color: modelData
                        }
                    }
                }
            }
            Repeater {
                model: Tokens.paletteIds
                OptionCard {
                    id: paletteCard
                    required property string modelData
                    readonly property var colors: Tokens.palettes[modelData][Colors.mode]
                    width: Tokens.settingsPaletteCard
                    text: Tokens.palettes[modelData].name
                    selected: root.look.palette === modelData
                    onClicked: Config.options.look.palette = modelData
                    // The palette's own surface with its accents on it.
                    Rectangle {
                        anchors.centerIn: parent
                        width: dots.implicitWidth + Tokens.space2 * 2
                        height: Tokens.settingsPaletteDot + Tokens.space2 * 2
                        radius: height / 2
                        color: paletteCard.colors.surfaceContainer
                        Row {
                            id: dots
                            anchors.centerIn: parent
                            spacing: Tokens.spaceHalf
                            Repeater {
                                model: [paletteCard.colors.primary, paletteCard.colors.secondary, paletteCard.colors.tertiary, paletteCard.colors.onSurface]
                                Rectangle {
                                    required property string modelData
                                    width: Tokens.settingsPaletteDot
                                    height: width
                                    radius: width / 2
                                    color: modelData
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: Tokens.space2
        visible: root.fromWallpaper

        StyledText {
            style: "settingsSection"
            text: "Colorfulness"
        }
        SegmentedButtons {
            width: parent.width
            label: "Colorfulness"
            options: [{ value: "monochrome", label: "Mono" }, { value: "neutral", label: "Neutral" }, { value: "tinted", label: "Tinted" }, { value: "vivid", label: "Vivid" }, { value: "deep", label: "Deep" }]
            current: root.look.colorfulness
            onSelected: v => Config.options.look.colorfulness = v
        }
    }

    // ── choices ──
    Grid {
        id: choices
        width: parent.width
        columns: width >= Tokens.settingsTwoColumnMin ? 2 : 1
        columnSpacing: Tokens.settingsGap
        rowSpacing: Tokens.settingsGap
        readonly property real cell: columns === 2 ? (width - columnSpacing) / 2 : width

        component Choice: Column {
            property string title
            width: choices.cell
            spacing: Tokens.space2
            StyledText {
                style: "settingsSection"
                text: parent.title
            }
        }

        Choice {
            title: "Theme"
            SegmentedButtons {
                width: parent.width
                label: "Theme"
                options: [{ value: "auto", label: "Auto" }, { value: "light", label: "Light" }, { value: "dark", label: "Dark" }]
                current: root.look.theme
                onSelected: v => Config.options.look.theme = v
            }
        }
        Choice {
            title: "Transparency"
            SegmentedButtons {
                width: parent.width
                label: "Transparency"
                options: [{ value: "solid", label: "Solid" }, { value: "frosted", label: "Frosted" }]
                current: root.look.transparency
                onSelected: v => Config.options.look.transparency = v
            }
        }
        Choice {
            title: "Home logo"
            Row {
                width: parent.width
                spacing: Tokens.space2
                readonly property real cell: (width - spacing * 2) / 3

                OptionCard {
                    width: parent.cell
                    text: "Reef"
                    selected: root.look.homeLogo === "reef"
                    onClicked: Config.options.look.homeLogo = "reef"
                    Logo {
                        anchors.centerIn: parent
                        size: Tokens.settingsOptionGlyph
                        color: Colors.on.surface
                    }
                }
                OptionCard {
                    width: parent.cell
                    text: "Distro logo"
                    icon: OsInfo.logoPath === "" ? "deployed_code" : ""
                    selected: root.look.homeLogo === "distro"
                    onClicked: Config.options.look.homeLogo = "distro"
                    IconImage {
                        anchors.centerIn: parent
                        visible: OsInfo.logoPath !== ""
                        implicitSize: Tokens.settingsOptionGlyph
                        source: OsInfo.logoPath
                    }
                }
                OptionCard {
                    width: parent.cell
                    text: "Custom image"
                    icon: "add_photo_alternate"
                    selected: root.look.homeLogo === "custom"
                    onClicked: logoDialog.open()
                }
            }
        }
    }

    SettingsSection {
        width: parent.width
        SwitchRow {
            width: parent.width
            text: "Draw the wallpaper"
            description: "Turn off when another program draws it."
            checked: root.look.drawWallpaper
            onToggled: Config.options.look.drawWallpaper = !root.look.drawWallpaper
        }
        SwitchRow {
            width: parent.width
            text: "Color Hyprland's borders"
            description: "Window borders and shadows follow these colors. Needs Reef's Hyprland config."
            checked: root.look.themeHyprland
            onToggled: Config.options.look.themeHyprland = !root.look.themeHyprland
        }
    }
}
