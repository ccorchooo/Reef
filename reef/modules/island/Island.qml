import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.theme
import qs.services
import qs.components

// The Island (SURFACES.md → The Island; MOTION.md → Shape follows content).
//
// One pure-black body that morphs between forms with spatial-default:
//   rest      120×32 pill                    (parts/Island-Rest)
//   timer / media / recording  collapsed live activity, wider pill
//   peek      380×64, radius-xl, on hover    (parts/Island-Rest, screens/Working)
//   expanded  520 wide; its tabs are circles to its left, and the other live
//             activities sit in a pill under it, as wide as it (parts/Island-Now)
//   hidden    up behind the top edge while an app is open; pointing at the top
//             center for island-reveal-delay drops it back in over the app.
// The old content fades out (effects-fast) and the new one fades in after
// content-fade-delay. It never reserves space.
PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "reef-island"

    // Tall enough for the expanded Island plus its shadow; only the body takes input.
    readonly property real shadowRoom: Colors.shadowIsland.blur + Colors.shadowIsland.y * 2
    readonly property real activitiesHeight: activityRows.implicitHeight + Tokens.space3 * 2
    implicitHeight: Tokens.space2 + Math.max(expandedContent.implicitHeight + Tokens.space4 * 2 + Tokens.space2 + activitiesHeight, notificationHeight) + shadowRoom

    mask: Region {
        Region { item: body }
        Region { item: revealStrip }
        Region { item: secondaryCircle }
        Region { item: tabs }
        Region { item: activitiesPill }
    }

    // ── state ───────────────────────────────────────────────────
    readonly property bool expanded: IslandState.expanded && IslandState.screenName === modelData.name
    readonly property bool overApps: Workspaces.windowCount(Workspaces.activeOn(modelData.name)) > 0
    readonly property bool hidesOverApps: overApps && Config.options.motion.islandHoverReveal
    readonly property string activity: IslandState.activity
    readonly property bool hovered: bodyHover.hovered
    property bool revealed: false

    // New notifications show on the focused monitor.
    readonly property var popup: Notifications.popup
    readonly property bool showsPopup: !!popup && (Hyprland.focusedMonitor?.name ?? modelData.name) === modelData.name
    readonly property real notificationHeight: notificationContent.implicitHeight + Tokens.space3_5 * 2

    readonly property string mode: expanded ? "expanded"
        : showsPopup ? "notification"
        : (hovered && activity !== "" && Config.options.island.peek) ? "peek"
        : (hidesOverApps && !revealed && !hovered) ? "hidden"
        : activity !== "" ? activity : "rest"

    // The form the body takes; while hidden it keeps its last visible form.
    property string form: "rest"
    onModeChanged: {
        if (mode !== "hidden")
            form = mode;
        if (Motion.reduceMotion) {
            shownForm = form;
        } else {
            shownForm = "";
            fadeIn.restart();
        }
    }
    property string shownForm: form

    Timer {
        id: fadeIn
        interval: Motion.contentFadeDelay
        onTriggered: root.shownForm = root.form
    }

    readonly property real formWidth: form === "notification" ? Tokens.islandNotificationWidth
        : form === "peek" ? Tokens.islandPeekWidth
        : form === "expanded" ? Tokens.islandExpandedWidth
        : activityWidth(form)
    readonly property real formHeight: form === "peek" ? Tokens.islandPeekHeight
        : form === "expanded" ? expandedContent.implicitHeight + Tokens.space4 * 2
        : form === "notification" ? notificationHeight
        : Tokens.islandCollapsedHeight
    readonly property real formRadius: (form === "peek" || form === "expanded" || form === "notification") ? Tokens.radiusXl : formHeight / 2

    // ── reveal over apps ────────────────────────────────────────
    Timer {
        id: revealTimer
        interval: Tokens.islandRevealDelay
        onTriggered: root.revealed = true
    }
    Timer {
        id: hideTimer
        interval: Tokens.islandHideDelay
        onTriggered: if (!stripHover.hovered && !bodyHover.hovered && !secondaryHover.hovered && !root.expanded) root.revealed = false
    }
    onHoveredChanged: if (!hovered) hideTimer.restart()
    onHidesOverAppsChanged: if (!hidesOverApps) revealed = false

    Item {
        id: revealStrip
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        width: Tokens.islandPeekWidth
        height: root.hidesOverApps && root.mode === "hidden" ? Tokens.islandRevealStrip : 0
        HoverHandler {
            id: stripHover
            onHoveredChanged: {
                if (hovered)
                    revealTimer.restart();
                else {
                    revealTimer.stop();
                    hideTimer.restart();
                }
            }
        }
    }

    // ── body ────────────────────────────────────────────────────
    Spring { id: wSpring; spec: Motion.spatialDefault; target: root.formWidth }
    Spring { id: hSpring; spec: Motion.spatialDefault; target: root.formHeight }
    Spring { id: rSpring; spec: Motion.spatialDefault; target: root.formRadius }
    Spring {
        id: ySpring
        spec: Motion.spatialDefault
        target: root.mode === "hidden" ? -(root.formHeight + root.shadowRoom) : Tokens.space2
    }
    Spring {
        id: shadowOpacity
        spec: Motion.effectsDefault
        target: root.overApps || ["peek", "expanded", "notification"].includes(root.form) ? 1 : 0
    }

    // ── secondary activity ──────────────────────────────────────
    // With two live activities, the second shows as a small black circle beside the
    // Island holding just its glyph. It slides out from behind the Island and follows it
    // through the peek; clicking it (or Super+Shift+I) puts it on the Island. Expanded,
    // every other activity moves into the pill under the Island instead.
    readonly property string secondary: IslandState.secondaryActivity
    readonly property bool secondaryShown: secondary !== "" && !expanded && mode !== "notification"
        && (mode === "peek" || IslandState.isActivity(mode))

    // Collapsed width of an activity (the resting pill for anything else).
    function activityWidth(key) {
        return IslandState.byKey(key)?.width ?? Tokens.islandCollapsedWidth;
    }

    property string shownSecondary: secondary
    onSecondaryChanged: {
        if (Motion.reduceMotion) {
            shownSecondary = secondary;
        } else {
            shownSecondary = "";
            secondaryFade.restart();
        }
    }
    Timer {
        id: secondaryFade
        interval: Motion.contentFadeDelay
        onTriggered: root.shownSecondary = root.secondary
    }

    Spring {
        id: secondaryOut
        spec: Motion.spatialDefault
        target: root.secondaryShown ? Tokens.space2 + Tokens.islandCollapsedHeight : 0
    }
    Spring {
        id: secondaryOpacity
        spec: Motion.effectsDefault
        target: root.secondaryShown ? 1 : 0
    }

    RectangularShadow {
        anchors.fill: secondaryCircle
        radius: secondaryCircle.radius
        offset.x: Colors.shadowIsland.x
        offset.y: Colors.shadowIsland.y
        blur: Colors.shadowIsland.blur
        color: Colors.shadowIsland.color
        opacity: shadowOpacity.value * secondaryOpacity.value
        visible: secondaryCircle.visible && opacity > 0.01
    }

    Rectangle {
        id: secondaryCircle
        // Tucked behind the Island's right end, then out beside it.
        x: body.x + body.width - width + secondaryOut.value
        y: body.y + (Math.min(body.height, Tokens.islandPeekHeight) - height) / 2
        width: Tokens.islandCollapsedHeight
        height: width
        radius: width / 2
        color: Colors.island
        clip: true
        opacity: secondaryOpacity.value
        visible: opacity > 0.01

        Accessible.role: Accessible.Button
        Accessible.name: (IslandState.byKey(root.secondary)?.spoken ?? "") + ". Put on the Island"

        IslandActivity {
            anchors.fill: parent
            compact: true
            activity: IslandState.byKey(root.shownSecondary || root.secondary)
            opacity: secondaryContent.value
            visible: opacity > 0.01 && root.secondary !== ""
            Spring {
                id: secondaryContent
                spec: Motion.effectsFast
                target: root.shownSecondary !== "" ? 1 : 0
            }
        }

        // Hover state layer
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Colors.on.island
            opacity: secondaryState.value
            Spring {
                id: secondaryState
                spec: Motion.effectsFast
                target: secondaryTap.pressed ? Tokens.statePressedOpacity : secondaryHover.hovered ? Tokens.stateHoverOpacity : 0
            }
        }

        HoverHandler {
            id: secondaryHover
            cursorShape: Qt.PointingHandCursor
            onHoveredChanged: if (!hovered) hideTimer.restart()
        }
        TapHandler {
            id: secondaryTap
            onTapped: IslandState.swap()
        }
    }

    // ── expanded: tabs and the activities pill ──────────────────
    Spring {
        id: besideOut
        spec: Motion.spatialDefault
        target: root.expanded ? 1 : 0
    }
    Spring {
        id: besideOpacity
        spec: Motion.effectsDefault
        target: root.expanded ? 1 : 0
    }

    // Tabs: circles to the left of the Island, sliding out from behind it.
    IslandTabs {
        id: tabs
        x: body.x - Tokens.space2 - width + (1 - besideOut.value) * (Tokens.space2 + width)
        y: body.y
        opacity: besideOpacity.value
        visible: opacity > 0.01
        enabled: root.expanded
        shadowOpacity: shadowOpacity.value
    }

    // The other live activities, in a pill under the Island as wide as it.
    readonly property bool activitiesShown: expanded && activityRows.count > 0
    Spring {
        id: activitiesOpacity
        spec: Motion.effectsDefault
        target: root.activitiesShown ? 1 : 0
    }
    Spring {
        id: activitiesH
        spec: Motion.spatialDefault
        target: root.activitiesShown ? root.activitiesHeight : 0
    }

    RectangularShadow {
        anchors.fill: activitiesPill
        radius: activitiesPill.radius
        offset.x: Colors.shadowIsland.x
        offset.y: Colors.shadowIsland.y
        blur: Colors.shadowIsland.blur
        color: Colors.shadowIsland.color
        opacity: shadowOpacity.value * activitiesOpacity.value
        visible: activitiesPill.visible && opacity > 0.01
    }

    Rectangle {
        id: activitiesPill
        anchors.horizontalCenter: parent.horizontalCenter
        y: body.y + body.height + Tokens.space2 * besideOut.value
        width: body.width
        height: activitiesH.value
        radius: Math.min(Tokens.radiusXl, height / 2)
        color: Colors.island
        clip: true
        opacity: activitiesOpacity.value
        visible: opacity > 0.01
        enabled: root.activitiesShown

        Accessible.role: Accessible.Grouping
        Accessible.name: "Live activities"

        IslandActivities {
            id: activityRows
            x: Tokens.space3
            y: Tokens.space3
            width: Tokens.islandExpandedWidth - Tokens.space3 * 2
        }
    }

    RectangularShadow {
        anchors.fill: body
        radius: body.radius
        offset.x: Colors.shadowIsland.x
        offset.y: Colors.shadowIsland.y
        blur: Colors.shadowIsland.blur
        color: Colors.shadowIsland.color
        opacity: shadowOpacity.value
        visible: opacity > 0.01 && body.y > -body.height
    }

    Rectangle {
        id: body
        anchors.horizontalCenter: parent.horizontalCenter
        y: ySpring.value
        width: wSpring.value
        height: hSpring.value
        radius: Math.min(rSpring.value, height / 2)
        color: Colors.island
        clip: true

        Accessible.role: Accessible.Grouping
        Accessible.name: "The Island"

        HoverHandler {
            id: bodyHover
        }

        TapHandler {
            enabled: !root.expanded && root.form !== "notification"
            onTapped: IslandState.open("now", root.modelData.name)
        }

        // A notification stays while the pointer is on it or a reply is being typed.
        Binding {
            when: root.form === "notification"
            target: root
            property: "_holdPopup"
            value: bodyHover.hovered || notificationContent.replying
        }

        // Scroll over the Island to move between tabs.
        WheelHandler {
            enabled: root.expanded
            onWheel: event => {
                const tabs = IslandState.builtTabs;
                const i = tabs.indexOf(IslandState.tab) + (event.angleDelta.y < 0 ? 1 : -1);
                if (i >= 0 && i < tabs.length)
                    IslandState.tab = tabs[i];
            }
        }

        // Collapsed activities share one item; its kind follows the form.
        IslandActivity {
            id: activityContent
            width: root.formWidth
            height: Tokens.islandCollapsedHeight
            anchors.centerIn: parent
            activity: IslandState.byKey(IslandState.isActivity(root.form) ? root.form : root.activity)
            opacity: activityOpacity.value
            visible: opacity > 0.01
            Spring {
                id: activityOpacity
                spec: Motion.effectsFast
                target: IslandState.isActivity(root.shownForm) ? 1 : 0
            }
        }

        IslandPeek {
            width: Tokens.islandPeekWidth
            height: Tokens.islandPeekHeight
            anchors.centerIn: parent
            activity: IslandState.byKey(root.activity)
            opacity: peekOpacity.value
            visible: opacity > 0.01
            enabled: root.shownForm === "peek"
            Spring {
                id: peekOpacity
                spec: Motion.effectsFast
                target: root.shownForm === "peek" ? 1 : 0
            }
        }

        IslandNotification {
            id: notificationContent
            x: Tokens.space4
            y: Tokens.space3_5
            width: Tokens.islandNotificationWidth - Tokens.space4 - Tokens.space3_5
            notification: root.popup
            opacity: notificationOpacity.value
            visible: opacity > 0.01
            enabled: root.shownForm === "notification"
            onWantsKeyboard: root.typing = true
            Spring {
                id: notificationOpacity
                spec: Motion.effectsFast
                target: root.shownForm === "notification" ? 1 : 0
            }
        }

        Column {
            id: expandedContent
            x: Tokens.space4
            y: Tokens.space4
            width: Tokens.islandExpandedWidth - Tokens.space4 * 2
            spacing: Tokens.space3_5
            opacity: expandedOpacity.value
            visible: opacity > 0.01
            enabled: root.expanded

            Spring {
                id: expandedOpacity
                spec: Motion.effectsFast
                target: root.shownForm === "expanded" ? 1 : 0
            }

            NowTab {
                width: parent.width
                visible: IslandState.tab === "now"
            }
        }
    }

    // Keep awake: inhibit idle while this surface is mapped.
    IdleInhibitor {
        window: root
        enabled: KeepAwake.active
    }

    // ── keyboard while expanded ─────────────────────────────────
    // Tab between controls, Escape or a click elsewhere closes.
    // Typing a reply to a notification also takes the keyboard.
    property bool typing: false
    property bool _holdPopup: false
    on_HoldPopupChanged: Notifications.holdPopup(_holdPopup)
    onPopupChanged: typing = false
    readonly property bool wantsKeys: expanded || (typing && mode === "notification")

    WlrLayershell.keyboardFocus: wantsKeys ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onWantsKeysChanged: {
        if (wantsKeys) {
            if (expanded)
                focusFirst.restart();
            else
                armGrab.restart();
        } else {
            grab.armed = false;
        }
    }

    Timer {
        id: focusFirst
        interval: 1
        onTriggered: {
            keys.forceActiveFocus();
            armGrab.restart();
        }
    }
    Timer {
        id: armGrab
        interval: 150
        onTriggered: grab.armed = root.wantsKeys
    }

    Item {
        id: keys
        focus: true
        Keys.onTabPressed: keys.nextItemInFocusChain(true)?.forceActiveFocus()
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.wantsKeys
        onActivated: root.expanded ? IslandState.close() : Notifications.closePopup()
    }

    HyprlandFocusGrab {
        id: grab
        property bool armed: false
        windows: [root]
        active: root.wantsKeys && armed
        onCleared: root.expanded ? IslandState.close() : (root.typing = false)
    }
}
