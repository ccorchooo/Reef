import QtQuick
import Quickshell.Widgets
import qs.theme
import qs.services

// The home logo (DESIGN.md §7, Settings → Look → Home logo): the Reef mark colored with a
// token, the distro's logo from the icon theme, or a custom image. Falls back to the
// Reef mark when the distro has no logo or the image is missing.
//
//   HomeLogo { size: Tokens.iconSm; color: Colors.on.primaryContainer }
Item {
    id: root

    property real size: Tokens.iconSm
    property color color: Colors.primary
    readonly property string kind: Config.options.look.homeLogo
    readonly property string imagePath: kind === "distro" ? OsInfo.logoPath
        : kind === "custom" ? Config.options.look.homeLogoPath : ""

    implicitWidth: size
    implicitHeight: size

    Logo {
        anchors.centerIn: parent
        visible: !image.visible
        size: root.size
        color: root.color
    }
    IconImage {
        id: image
        anchors.centerIn: parent
        implicitSize: root.size
        visible: root.imagePath !== "" && status === Image.Ready
        source: root.imagePath === "" ? "" : root.imagePath.startsWith("/") ? "file://" + root.imagePath : root.imagePath
    }
}
