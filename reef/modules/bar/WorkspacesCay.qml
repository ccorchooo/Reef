import QtQuick
import qs.theme
import qs.services
import qs.components

// The separate Workspaces cay (Settings → Bar & Island → "Workspaces in their own cay"):
// the workspace numerals, always shown, with the active one in the sliding primary pill.
// The Navigator then stays in its home form and its grid button opens the overview,
// whose selection this cay shows. Scrolling over it moves between workspaces.
Cay {
    id: root

    required property string screenName

    leftPadding: Tokens.cayPaddingTight
    rightPadding: Tokens.cayPaddingTight

    Accessible.role: Accessible.ToolBar
    Accessible.name: "Workspaces"

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const d = event.angleDelta.y || -event.angleDelta.x;
            if (Math.abs(d) >= 1)
                numbers.step(d < 0 ? 1 : -1);
        }
    }

    WorkspaceNumbers {
        id: numbers
        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        screenName: root.screenName
        vertical: root.vertical
    }
}
