pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The distribution, from /etc/os-release: its name and logo icon (LOGO), for the
// "Distro logo" home logo and Settings → About.
Singleton {
    id: root

    property string name: ""
    property string prettyName: ""
    property string logo: ""                 // an icon name from the icon theme
    readonly property string logoPath: logo !== "" ? Quickshell.iconPath(logo, true) : ""

    FileView {
        path: "/etc/os-release"
        onLoaded: {
            const v = {};
            for (const line of text().split("\n")) {
                const m = /^([A-Z_]+)=(.*)$/.exec(line.trim());
                if (m)
                    v[m[1]] = m[2].replace(/^["']|["']$/g, "");
            }
            root.name = v.NAME ?? "";
            root.prettyName = v.PRETTY_NAME ?? root.name;
            root.logo = v.LOGO ?? "";
        }
    }
}
