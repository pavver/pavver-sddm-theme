import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.private.keyboardindicator as KeyboardIndicator

Item {
    id: root
    width: 680
    height: 180

    // Caps Lock state detection
    KeyboardIndicator.KeyState {
        id: capsLockState
        key: Qt.Key_CapsLock
    }

    property bool mockCapsLock: false
    readonly property bool isCapsLockOn: mockCapsLock || (typeof capsLockState !== "undefined" && capsLockState && capsLockState.locked)

    FontLoader {
        id: cascadiaFont
        source: Qt.resolvedUrl("../fonts/CascadiaCode.ttf")
    }

    readonly property string mainFontFamily: cascadiaFont.status === FontLoader.Ready ? cascadiaFont.name : (typeof config !== "undefined" && config.font ? config.font : "Cascadia Code")

    // Keyboard layouts handling
    readonly property var availableLayouts: {
        if (typeof keyboard !== "undefined" && keyboard && keyboard.layouts && keyboard.layouts.length > 0) {
            return keyboard.layouts;
        }
        // Fallback for test-mode / mock preview
        return [
            { shortName: "us", longName: "English (US)" },
            { shortName: "ua", longName: "Українська" }
        ];
    }

    property int mockLayoutIndex: 0

    readonly property int activeLayoutIndex: {
        if (typeof keyboard !== "undefined" && keyboard && typeof keyboard.currentLayout === "number") {
            return keyboard.currentLayout;
        }
        return mockLayoutIndex;
    }

    readonly property string currentLayoutShortName: {
        if (availableLayouts.length > activeLayoutIndex && activeLayoutIndex >= 0) {
            var l = availableLayouts[activeLayoutIndex];
            if (l && l.shortName) return l.shortName.toUpperCase();
        }
        return "US";
    }

    readonly property string currentLayoutFullName: {
        if (availableLayouts.length > activeLayoutIndex && activeLayoutIndex >= 0) {
            var l = availableLayouts[activeLayoutIndex];
            if (l && l.longName) return "Розкладка: " + l.longName;
        }
        return "Розкладка клавіатури";
    }

    function nextKeyboardLayout() {
        if (availableLayouts.length <= 1) return;
        var nextIdx = (activeLayoutIndex + 1) % availableLayouts.length;
        if (typeof keyboard !== "undefined" && keyboard && typeof keyboard.currentLayout === "number") {
            keyboard.currentLayout = nextIdx;
        }
        mockLayoutIndex = nextIdx;
    }

    property var userListModel: typeof userModel !== "undefined" ? userModel : null
    property int currentUserIndex: (userListModel && userListModel.lastIndex >= 0) ? userListModel.lastIndex : 0
    property var usersList: []

    // Helper item with Repeater to safely extract model roles from SDDM QAbstractItemModel
    Item {
        id: userExtractor
        visible: false

        Repeater {
            id: userRepeater
            model: root.userListModel

            Item {
                property string uName: (typeof model.name !== "undefined" && model.name) ? model.name : ""
                property string uRealName: (typeof model.realName !== "undefined" && model.realName) ? model.realName : ""
                property string uIcon: (typeof model.icon !== "undefined" && model.icon) ? model.icon : ""
                property string uIconName: (typeof model.iconName !== "undefined" && model.iconName) ? model.iconName : ""

                Component.onCompleted: root.rebuildUserList()
                Component.onDestruction: root.rebuildUserList()
            }
        }
    }

    function rebuildUserList() {
        var arr = [];
        for (var i = 0; i < userRepeater.count; ++i) {
            var it = userRepeater.itemAt(i);
            if (it) {
                arr.push({
                    name: it.uName,
                    realName: it.uRealName,
                    icon: it.uIcon,
                    iconName: it.uIconName
                });
            }
        }
        root.usersList = arr;
    }

    readonly property string currentUserName: {
        if (usersList.length > currentUserIndex && currentUserIndex >= 0) {
            var u = usersList[currentUserIndex];
            if (u && u.name) return u.name;
        }
        return (userListModel && userListModel.lastUser) ? userListModel.lastUser : "pavver";
    }

    // Desktop Session handling
    property bool showSessionBadge: true
    property var sessionListModel: typeof sessionModel !== "undefined" ? sessionModel : null
    property int currentSessionIndex: (sessionListModel && typeof sessionListModel.lastIndex === "number" && sessionListModel.lastIndex >= 0) ? sessionListModel.lastIndex : 0
    property var sessionsList: []

    Item {
        id: sessionExtractor
        visible: false
        Repeater {
            id: sessionRepeater
            model: root.sessionListModel
            Item {
                property string sName: (typeof model.name !== "undefined" && model.name) ? model.name : ""
                property string sFile: (typeof model.file !== "undefined" && model.file) ? model.file : ""
                Component.onCompleted: root.rebuildSessionList()
                Component.onDestruction: root.rebuildSessionList()
            }
        }
    }

    function rebuildSessionList() {
        var arr = [];
        for (var i = 0; i < sessionRepeater.count; ++i) {
            var it = sessionRepeater.itemAt(i);
            if (it && it.sName) {
                arr.push({
                    name: it.sName,
                    file: it.sFile,
                    index: i
                });
            }
        }
        root.sessionsList = arr;
    }

    readonly property string currentSessionDisplayName: {
        if (sessionsList.length > currentSessionIndex && currentSessionIndex >= 0) {
            var s = sessionsList[currentSessionIndex];
            if (s && s.name) return s.name;
        }
        if (sessionListModel && sessionListModel.get && currentSessionIndex >= 0 && sessionListModel.count > currentSessionIndex) {
            var item = sessionListModel.get(currentSessionIndex);
            if (item && item.name) return item.name;
        }
        return "Plasma (Wayland)";
    }

    readonly property string currentUserDisplayName: {
        if (usersList.length > currentUserIndex && currentUserIndex >= 0) {
            var u = usersList[currentUserIndex];
            if (u && u.realName) return u.realName;
            if (u && u.name) return u.name;
        }
        return currentUserName;
    }

    readonly property string currentUserAvatarUrl: {
        var path = "";
        if (usersList.length > currentUserIndex && currentUserIndex >= 0) {
            var u = usersList[currentUserIndex];
            if (u && u.icon) path = u.icon;
        }
        if (!path) {
            path = "/var/lib/AccountsService/icons/" + currentUserName;
        }
        if (path.length > 0 && path.indexOf("://") === -1) {
            return "file://" + path;
        }
        return path;
    }

    readonly property int userCount: {
        if (usersList.length > 0) return usersList.length;
        if (userListModel && typeof userListModel.count === "number") return userListModel.count;
        return 1;
    }

    signal loginRequested(string username, string password, int sessionIndex)

    property string inputFeedbackState: "idle" // "idle", "success", "error"
    property real pulseAlpha: 1.0
    property real pulseBorderWidth: 1.5

    // Success animation: pulse vibrant green border for 500ms, then trigger loader transition
    SequentialAnimation {
        id: successPulseAnim
        running: false
        ScriptAction {
            script: {
                root.inputFeedbackState = "success";
                root.pulseBorderWidth = 3.0;
                root.pulseAlpha = 1.0;
            }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "pulseAlpha"; from: 1.0; to: 0.55; duration: 250; easing.type: Easing.InOutQuad }
            NumberAnimation { target: root; property: "pulseBorderWidth"; from: 3.0; to: 2.2; duration: 250; easing.type: Easing.InOutQuad }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "pulseAlpha"; from: 0.55; to: 1.0; duration: 250; easing.type: Easing.InOutQuad }
            NumberAnimation { target: root; property: "pulseBorderWidth"; from: 2.2; to: 3.0; duration: 250; easing.type: Easing.InOutQuad }
        }
        ScriptAction {
            script: {
                root.loginRequested(currentUserName, passwordInput.text, currentSessionIndex);
            }
        }
    }

    function doLogin() {
        if (passwordInput.text.length > 0 && inputFeedbackState !== "success") {
            successPulseAnim.restart();
        }
    }

    // Error animation: clear text immediately, pulse red border twice with tactile micro-shake, then smooth exit fade
    SequentialAnimation {
        id: errorPulseAnim
        running: false
        ScriptAction {
            script: {
                passwordInput.text = "";
                root.inputFeedbackState = "error";
                root.pulseBorderWidth = 3.0;
                root.pulseAlpha = 1.0;
                passwordInput.forceActiveFocus();
            }
        }
        // Pulse 1 + Tactile Micro-shake
        ParallelAnimation {
            SequentialAnimation {
                NumberAnimation { target: root; property: "x"; to: root.x - 8; duration: 40; easing.type: Easing.InOutQuad }
                NumberAnimation { target: root; property: "x"; to: root.x + 8; duration: 70; easing.type: Easing.InOutQuad }
                NumberAnimation { target: root; property: "x"; to: root.x - 5; duration: 60; easing.type: Easing.InOutQuad }
                NumberAnimation { target: root; property: "x"; to: root.x + 5; duration: 60; easing.type: Easing.InOutQuad }
                NumberAnimation { target: root; property: "x"; to: root.x; duration: 40; easing.type: Easing.InOutQuad }
            }
            SequentialAnimation {
                ParallelAnimation {
                    NumberAnimation { target: root; property: "pulseAlpha"; from: 1.0; to: 0.55; duration: 200; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: root; property: "pulseBorderWidth"; from: 3.0; to: 2.2; duration: 200; easing.type: Easing.InOutQuad }
                }
                ParallelAnimation {
                    NumberAnimation { target: root; property: "pulseAlpha"; from: 0.55; to: 1.0; duration: 200; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: root; property: "pulseBorderWidth"; from: 2.2; to: 3.0; duration: 200; easing.type: Easing.InOutQuad }
                }
            }
        }
        // Pulse 2
        ParallelAnimation {
            NumberAnimation { target: root; property: "pulseAlpha"; from: 1.0; to: 0.55; duration: 200; easing.type: Easing.InOutQuad }
            NumberAnimation { target: root; property: "pulseBorderWidth"; from: 3.0; to: 2.2; duration: 200; easing.type: Easing.InOutQuad }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "pulseAlpha"; from: 0.55; to: 1.0; duration: 200; easing.type: Easing.InOutQuad }
            NumberAnimation { target: root; property: "pulseBorderWidth"; from: 2.2; to: 3.0; duration: 200; easing.type: Easing.InOutQuad }
        }
        // Smooth exit fade to idle (400 ms)
        ParallelAnimation {
            NumberAnimation { target: root; property: "pulseAlpha"; from: 1.0; to: 0.0; duration: 400; easing.type: Easing.InOutQuad }
            NumberAnimation { target: root; property: "pulseBorderWidth"; from: 3.0; to: 1.5; duration: 400; easing.type: Easing.InOutQuad }
        }
        ScriptAction {
            script: {
                root.inputFeedbackState = "idle";
                root.pulseAlpha = 1.0;
                root.pulseBorderWidth = 1.5;
            }
        }
    }

    function onLoginFailed() {
        errorPulseAnim.restart();
    }

    // Base dark grey rectangle (#222222, darker than banner background #333333)
    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: 20
        color: "#222222"
        visible: false
    }

    // Hardware-accelerated smooth inner shadow (matching banner inner glow effect)
    InnerShadow {
        id: bgInnerShadow
        anchors.fill: bgRect
        source: bgRect
        radius: 16.0
        samples: 32
        horizontalOffset: 0
        verticalOffset: 0
        color: "#dd000000"
        spread: 0.2
    }

    // Crisp outer border
    Rectangle {
        id: bgBorder
        anchors.fill: parent
        radius: 20
        color: "transparent"
        border.color: "#3a3a3a"
        border.width: 1.5
    }

    // Left: Round Avatar (~124x124 px)
    Item {
        id: avatarContainer
        width: 124
        height: 124
        anchors.left: parent.left
        anchors.leftMargin: 28
        anchors.verticalCenter: parent.verticalCenter

        // Avatar Image
        Image {
            id: avatarImg
            anchors.fill: parent
            source: root.currentUserAvatarUrl
            sourceSize: Qt.size(248, 248)
            fillMode: Image.PreserveAspectCrop
            smooth: true
            mipmap: true
            visible: false
        }

        // Circular mask for clean anti-aliased round avatar
        Rectangle {
            id: avatarMask
            anchors.fill: parent
            radius: width / 2
            visible: false
        }

        OpacityMask {
            anchors.fill: parent
            source: avatarImg
            maskSource: avatarMask
            visible: avatarImg.status === Image.Ready
        }

        // Fallback user icon if image fails to load
        Kirigami.Icon {
            anchors.centerIn: parent
            width: 60
            height: 60
            source: "user-identity"
            visible: avatarImg.status !== Image.Ready
        }

        // Cyan Neon Border Ring
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.color: "#00d2ff"
            border.width: 3
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: root.userCount > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (root.userCount > 1) {
                    userDropdown.visible = !userDropdown.visible;
                }
            }
        }
    }

    // Right Column (124px height, matching avatar)
    Item {
        anchors.left: avatarContainer.right
        anchors.leftMargin: 24
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        height: 124

        // Top Row: Username, Session Badge, and Power buttons
        Item {
            id: topRow
            width: parent.width
            height: root.showSessionBadge ? 50 : 46
            anchors.top: parent.top

            // User name & optional Session Selector column
            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                // User name & dropdown indicator
                Item {
                    width: userNameRow.width
                    height: userNameRow.height

                    Row {
                        id: userNameRow
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: root.currentUserDisplayName
                            color: "#ffffff"
                            font.family: root.mainFontFamily
                            font.pixelSize: root.showSessionBadge ? 20 : 22
                            font.bold: true
                        }

                        Text {
                            text: "▾"
                            color: "#00d2ff"
                            font.pixelSize: 18
                            visible: root.userCount > 1
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: root.userCount > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (root.userCount > 1) {
                                userDropdown.visible = !userDropdown.visible;
                                sessionDropdown.visible = false;
                            }
                        }
                    }
                }

                // Proposed Session Selector Badge (when enabled)
                Rectangle {
                    id: sessionBadge
                    visible: root.showSessionBadge
                    height: 22
                    width: sessionBadgeRow.width + 14
                    radius: 6
                    color: sessionBadgeMouse.containsMouse ? "#252525" : "#191919"
                    border.color: sessionBadgeMouse.containsMouse ? "#00d2ff" : "#383838"
                    border.width: 1

                    Row {
                        id: sessionBadgeRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: root.currentSessionDisplayName
                            color: sessionBadgeMouse.containsMouse ? "#00d2ff" : "#a0a0b0"
                            font.family: root.mainFontFamily
                            font.pixelSize: 12
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "▾"
                            color: sessionBadgeMouse.containsMouse ? "#00d2ff" : "#666677"
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: sessionBadgeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            sessionDropdown.visible = !sessionDropdown.visible;
                            if (sessionDropdown.visible) {
                                userDropdown.visible = false;
                            }
                        }
                    }
                }
            }

            // Action Buttons (Keyboard Layout Switcher + Power buttons)
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                // Keyboard Layout Switcher Button
                Rectangle {
                    id: kbBtn
                    width: 48
                    height: 48
                    radius: 24
                    color: kbMouse.containsMouse ? "#152535" : "#282828"
                    border.color: kbMouse.containsMouse ? "#00d2ff" : "#3c3c3c"
                    border.width: 1.5
                    visible: {
                        if (typeof keyboard !== "undefined" && keyboard && keyboard.layouts) {
                            if (keyboard.layouts.length > 1) return true;
                            if (keyboard.layouts.length === 1) return false;
                        }
                        return true;
                    }

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: root.currentLayoutShortName
                        color: kbMouse.containsMouse ? "#00d2ff" : "#d0d0dc"
                        font.family: root.mainFontFamily
                        font.pixelSize: 24
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: kbMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.nextKeyboardLayout()
                    }

                    ToolTip.visible: kbMouse.containsMouse
                    ToolTip.text: root.currentLayoutFullName
                    ToolTip.delay: 350
                }

                // Suspend
                Rectangle {
                    width: 48; height: 48; radius: 24
                    color: suspendMouse.containsMouse ? "#152535" : "#282828"
                    border.color: suspendMouse.containsMouse ? "#00d2ff" : "#3c3c3c"
                    border.width: 1.5

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Image {
                        anchors.centerIn: parent
                        width: 32; height: 32
                        source: suspendMouse.containsMouse ? Qt.resolvedUrl("../assets/suspend_hover.svg") : Qt.resolvedUrl("../assets/suspend_normal.svg")
                        sourceSize: Qt.size(128, 128)
                        smooth: true
                        mipmap: true
                    }

                    MouseArea {
                        id: suspendMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (typeof sddm !== "undefined" && sddm.canSuspend) sddm.suspend()
                    }

                    ToolTip.visible: suspendMouse.containsMouse
                    ToolTip.text: "Сон"
                    ToolTip.delay: 350
                }

                // Reboot
                Rectangle {
                    width: 48; height: 48; radius: 24
                    color: rebootMouse.containsMouse ? "#251835" : "#282828"
                    border.color: rebootMouse.containsMouse ? "#c77dff" : "#3c3c3c"
                    border.width: 1.5

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Image {
                        anchors.centerIn: parent
                        width: 32; height: 32
                        source: rebootMouse.containsMouse ? Qt.resolvedUrl("../assets/reboot_hover.svg") : Qt.resolvedUrl("../assets/reboot_normal.svg")
                        sourceSize: Qt.size(128, 128)
                        smooth: true
                        mipmap: true
                    }

                    MouseArea {
                        id: rebootMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (typeof sddm !== "undefined" && sddm.canReboot) sddm.reboot()
                    }

                    ToolTip.visible: rebootMouse.containsMouse
                    ToolTip.text: "Перезавантаження"
                    ToolTip.delay: 350
                }

                // Shutdown
                Rectangle {
                    width: 48; height: 48; radius: 24
                    color: powerMouse.containsMouse ? "#381520" : "#282828"
                    border.color: powerMouse.containsMouse ? "#ff4d6d" : "#3c3c3c"
                    border.width: 1.5

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Image {
                        anchors.centerIn: parent
                        width: 32; height: 32
                        source: powerMouse.containsMouse ? Qt.resolvedUrl("../assets/shutdown_hover.svg") : Qt.resolvedUrl("../assets/shutdown_normal.svg")
                        sourceSize: Qt.size(128, 128)
                        smooth: true
                        mipmap: true
                    }

                    MouseArea {
                        id: powerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (typeof sddm !== "undefined" && sddm.canPowerOff) sddm.powerOff()
                    }

                    ToolTip.visible: powerMouse.containsMouse
                    ToolTip.text: "Вимкнення"
                    ToolTip.delay: 350
                }
            }
        }

        // Bottom Row: Password Field with embedded submit arrow (56px height)
        Rectangle {
            id: passInputBox
            width: parent.width
            height: 56
            anchors.bottom: parent.bottom
            radius: 12
            color: {
                if (root.inputFeedbackState === "success") {
                    return Qt.rgba(0.0, 0.90, 0.46, 0.08 * root.pulseAlpha);
                } else if (root.inputFeedbackState === "error") {
                    return Qt.rgba(1.0, 0.20, 0.40, 0.08 * root.pulseAlpha);
                }
                return "#161616";
            }
            border.color: {
                if (root.inputFeedbackState === "success") {
                    return Qt.rgba(0.0, 0.90, 0.46, root.pulseAlpha);
                } else if (root.inputFeedbackState === "error") {
                    return Qt.rgba(1.0, 0.20, 0.40, root.pulseAlpha);
                }
                return passwordInput.activeFocus ? "#00d2ff" : "#2e2e2e";
            }
            border.width: {
                if (root.inputFeedbackState === "success" || root.inputFeedbackState === "error") {
                    return root.pulseBorderWidth;
                }
                return passwordInput.activeFocus ? 2 : 1.5;
            }

            Behavior on color { ColorAnimation { duration: 150 } }

            // Caps Lock Warning Badge (Inside input box on the left)
            Rectangle {
                id: capsLockBadge
                width: root.isCapsLockOn ? (capsBadgeRow.width + 16) : 0
                height: 32
                radius: 8
                anchors.left: parent.left
                anchors.leftMargin: root.isCapsLockOn ? 10 : 0
                anchors.verticalCenter: parent.verticalCenter
                color: capsMouse.containsMouse ? "#3d2700" : "#2a1c00"
                border.color: capsMouse.containsMouse ? "#ffc300" : "#ffb703"
                border.width: 1.5
                visible: width > 0
                opacity: root.isCapsLockOn ? 1.0 : 0.0
                clip: true

                Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Row {
                    id: capsBadgeRow
                    anchors.centerIn: parent
                    spacing: 6

                    Image {
                        width: 18
                        height: 18
                        source: Qt.resolvedUrl("../assets/capslock_warning.svg")
                        sourceSize: Qt.size(72, 72)
                        smooth: true
                        mipmap: true
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "CAPS"
                        color: "#ffb703"
                        font.family: root.mainFontFamily
                        font.pixelSize: 12
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: capsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                }

                ToolTip.visible: capsMouse.containsMouse
                ToolTip.text: "Caps Lock увімкнено! Пароль чутливий до регістру"
                ToolTip.delay: 150
            }

            TextInput {
                id: passwordInput
                anchors.left: capsLockBadge.right
                anchors.leftMargin: root.isCapsLockOn ? 10 : 16
                anchors.right: eyeBtn.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                echoMode: TextInput.Password
                color: "#ffffff"
                font.family: root.mainFontFamily
                font.pixelSize: 18
                focus: true

                Behavior on anchors.leftMargin { NumberAnimation { duration: 150 } }

                Text {
                    text: "Введіть пароль..."
                    color: "#555566"
                    font.family: root.mainFontFamily
                    font.pixelSize: 17
                    visible: !passwordInput.text && !passwordInput.activeFocus
                    anchors.verticalCenter: parent.verticalCenter
                }

                onAccepted: root.doLogin()

                Keys.onLeftPressed: {
                    if (!text && root.userCount > 1) {
                        root.currentUserIndex = (root.currentUserIndex - 1 + root.userCount) % root.userCount;
                    }
                }
                Keys.onRightPressed: {
                    if (!text && root.userCount > 1) {
                        root.currentUserIndex = (root.currentUserIndex + 1) % root.userCount;
                    }
                }
            }

            // Show / Hide Password Eye Toggle Button
            Rectangle {
                id: eyeBtn
                width: 38
                height: 38
                radius: 8
                anchors.right: submitBtn.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                color: eyeMouse.containsMouse ? "#22222c" : "transparent"
                opacity: passwordInput.text.length > 0 ? 1.0 : 0.45
                enabled: passwordInput.text.length > 0

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on opacity { NumberAnimation { duration: 150 } }

                readonly property bool isRevealed: passwordInput.echoMode === TextInput.Normal

                Image {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    source: {
                        if (eyeBtn.isRevealed) {
                            return eyeMouse.containsMouse ? Qt.resolvedUrl("../assets/eye_hide_hover.svg") : Qt.resolvedUrl("../assets/eye_hide_normal.svg")
                        } else {
                            return eyeMouse.containsMouse ? Qt.resolvedUrl("../assets/eye_show_hover.svg") : Qt.resolvedUrl("../assets/eye_show_normal.svg")
                        }
                    }
                    sourceSize: Qt.size(88, 88)
                    smooth: true
                    mipmap: true
                }

                MouseArea {
                    id: eyeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        passwordInput.echoMode = (passwordInput.echoMode === TextInput.Password) ? TextInput.Normal : TextInput.Password;
                        passwordInput.forceActiveFocus();
                    }
                }

                ToolTip.visible: eyeMouse.containsMouse && parent.enabled
                ToolTip.text: eyeBtn.isRevealed ? "Сховати пароль" : "Показати пароль"
                ToolTip.delay: 350
            }

            // Submit Button with Mathematically Centered Vector Arrow
            Rectangle {
                id: submitBtn
                width: 42
                height: 42
                radius: 8
                anchors.right: parent.right
                anchors.rightMargin: 7
                anchors.verticalCenter: parent.verticalCenter
                color: {
                    if (root.inputFeedbackState === "success") {
                        return "#00e676";
                    }
                    return passwordInput.text.length > 0 ? (submitMouse.containsMouse ? "#00e5ff" : "#00b4d8") : "#222222";
                }

                Behavior on color { ColorAnimation { duration: 150 } }

                Image {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    source: passwordInput.text.length > 0 ? Qt.resolvedUrl("../assets/arrow_submit_active.svg") : Qt.resolvedUrl("../assets/arrow_submit_inactive.svg")
                    sourceSize: Qt.size(88, 88)
                    smooth: true
                    mipmap: true
                }

                MouseArea {
                    id: submitMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: passwordInput.text.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.doLogin()
                }

                ToolTip.visible: submitMouse.containsMouse && passwordInput.text.length > 0
                ToolTip.text: "Увійти"
                ToolTip.delay: 350
            }
        }
    }

    // Multi-user dropdown
    Rectangle {
        id: userDropdown
        visible: false
        width: 240
        height: Math.min(root.userCount * 44 + 10, 220)
        color: "#222222"
        radius: 10
        border.color: "#3a3a3a"
        border.width: 1.5
        anchors.top: avatarContainer.bottom
        anchors.topMargin: 10
        anchors.left: avatarContainer.left
        z: 50

        ListView {
            anchors.fill: parent
            anchors.margins: 5
            clip: true
            model: root.usersList.length > 0 ? root.usersList : (root.userListModel ? root.userListModel : null)
            delegate: Rectangle {
                width: ListView.view.width
                height: 40
                radius: 6
                color: userMouse.containsMouse ? "#282836" : (index === root.currentUserIndex ? "#20202c" : "transparent")

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            if (modelData && (modelData.realName || modelData.name)) {
                                return modelData.realName || modelData.name;
                            }
                            if (model && (model.realName || model.name)) {
                                return model.realName || model.name;
                            }
                            return "";
                        }
                        color: index === root.currentUserIndex ? "#00d2ff" : "#dddddd"
                        font.family: root.mainFontFamily
                        font.pixelSize: 15
                        font.bold: index === root.currentUserIndex
                        elide: Text.ElideRight
                        width: parent.width - 20
                    }
                }

                MouseArea {
                    id: userMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentUserIndex = index;
                        userDropdown.visible = false;
                        passwordInput.forceActiveFocus();
                    }
                }
            }
        }
    }

    // Session dropdown
    Rectangle {
        id: sessionDropdown
        visible: false
        width: Math.max(220, sessionBadge.width + 20)
        height: Math.min((root.sessionsList.length > 0 ? root.sessionsList.length : (root.sessionListModel ? root.sessionListModel.count : 4)) * 42 + 10, 220)
        color: "#222222"
        radius: 10
        border.color: "#3a3a3a"
        border.width: 1.5
        x: avatarContainer.width + 24
        y: topRow.y + topRow.height + 4
        z: 60

        ListView {
            anchors.fill: parent
            anchors.margins: 5
            clip: true
            model: root.sessionsList.length > 0 ? root.sessionsList : (root.sessionListModel ? root.sessionListModel : null)
            delegate: Rectangle {
                width: ListView.view.width
                height: 38
                radius: 6
                color: sessMouse.containsMouse ? "#282836" : (index === root.currentSessionIndex ? "#1e2832" : "transparent")

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        text: index === root.currentSessionIndex ? "✓" : " "
                        color: "#00d2ff"
                        font.family: root.mainFontFamily
                        font.pixelSize: 14
                        font.bold: true
                        width: 16
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            if (modelData && modelData.name) return modelData.name;
                            if (model && model.name) return model.name;
                            return "";
                        }
                        color: index === root.currentSessionIndex ? "#00d2ff" : "#dddddd"
                        font.family: root.mainFontFamily
                        font.pixelSize: 13
                        font.bold: index === root.currentSessionIndex
                        elide: Text.ElideRight
                        width: parent.width - 34
                    }
                }

                MouseArea {
                    id: sessMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentSessionIndex = index;
                        sessionDropdown.visible = false;
                        passwordInput.forceActiveFocus();
                    }
                }
            }
        }
    }
}
