import QtQuick 2.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.private.keyboardindicator as KeyboardIndicator

import "components"

Item {
    id: root

    readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software

    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
    Kirigami.Theme.inherit: false

    width: 1600
    height: 900

    property bool isLoggingIn: false

    KeyboardIndicator.KeyState {
        id: capsLockState
        key: Qt.Key_CapsLock
    }

    // Responsive visibility thresholds for compact displays
    readonly property bool showBanner: root.height >= 520 && root.width >= 750
    readonly property bool showClock: root.width >= 750

    // Card scaling calculated from available dimensions
    readonly property real horizontalCardScale: {
        if (!showClock) {
            return Math.min(1.0, Math.max(0.55, (root.width - 40) / 680.0));
        }
        return Math.min(1.0, Math.max(0.55, (root.width - 60) / 1176.0));
    }
    readonly property real verticalCardScale: {
        var availH = showBanner ? (root.height - wallpaper.bannerBottom - 20) : (root.height - 40);
        return Math.min(1.0, Math.max(0.55, availH / (compactLoginCard.height + 40.0)));
    }
    readonly property real cardScale: Math.min(horizontalCardScale, verticalCardScale)

    // Dynamic vertical positioning: centers card and clock in the space below banner
    readonly property real cardTargetY: {
        if (!showBanner) {
            return Math.round((root.height - (compactLoginCard.height * cardScale)) / 2.0);
        }
        var availSpace = root.height - wallpaper.bannerBottom;
        var cardH = compactLoginCard.height * cardScale;
        return Math.round(wallpaper.bannerBottom + Math.max(16, (availSpace - cardH) / 2.0));
    }

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    FontLoader {
        id: cascadiaFont
        source: Qt.resolvedUrl("fonts/CascadiaCode.ttf")
    }

    PavverAnimatedBackground {
        id: wallpaper
        anchors.fill: parent
        isBannerVisible: root.showBanner && !root.isLoggingIn
        bannerItem.opacity: (root.showBanner && !root.isLoggingIn) ? 1.0 : 0.0

        customBannerHeight: {
            if (!root.showBanner) return 0;
            var fromWidth = (root.width * 0.85) / (675.0 / 190.0);
            var maxRatioHeight = root.height * 0.45;
            var minCardSpace = (compactLoginCard.height * root.horizontalCardScale) + 60;
            var topMargin = Math.round(Math.max(16, root.height * 0.048));
            var maxSpaceHeight = Math.max(100, root.height - topMargin - minCardSpace);
            return Math.min(fromWidth, Math.min(maxRatioHeight, maxSpaceHeight));
        }
        customBannerWidth: customBannerHeight * (675.0 / 190.0)
        customTopMargin: Math.round(Math.max(16, root.height * 0.048))
    }

    MouseArea {
        id: loginScreenRoot
        anchors.fill: parent

        property bool uiVisible: true
        property bool blockUI: false

        focus: true
        hoverEnabled: true
        drag.filterChildren: true
        onPressed: uiVisible = true;
        onPositionChanged: uiVisible = true;
        onUiVisibleChanged: {
            if (blockUI) {
                fadeoutTimer.running = false;
            } else if (uiVisible) {
                fadeoutTimer.restart();
            }
        }
        onBlockUIChanged: {
            if (blockUI) {
                fadeoutTimer.running = false;
                uiVisible = true;
            } else {
                fadeoutTimer.restart();
            }
        }

        Keys.onPressed: function(event) {
            uiVisible = true;
            if (event.key === Qt.Key_Escape) {
                if (compactLoginCard.closePopups()) {
                    event.accepted = true;
                } else if (virtualKeyboard.keyboardActive) {
                    virtualKeyboard.hide();
                    compactLoginCard.focusPassword();
                    event.accepted = true;
                } else {
                    event.accepted = false;
                }
            } else {
                event.accepted = false;
            }
        }

        // Timer for idle screen fade
        Timer {
            id: fadeoutTimer
            running: false
            interval: 60000
            onTriggered: {
                if (!loginScreenRoot.blockUI) {
                    loginScreenRoot.uiVisible = false;
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            visible: compactLoginCard.hasOpenPopup
            z: 1
            onClicked: compactLoginCard.closePopups()
        }

        // Row containing Clock and Login Card, perfectly centered as a unified group
        Row {
            id: bottomRow
            z: 2
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.cardTargetY
            spacing: Math.round(36 * root.cardScale)

            // Clock & Date (Left)
            Clock {
                id: clock
                visible: root.showClock && !root.isLoggingIn
                anchors.verticalCenter: parent.verticalCenter
                scaleFactor: root.cardScale
                opacity: (root.showClock && !root.isLoggingIn) ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation { duration: 300 }
                }
            }

            // Login Card (Right, or centered automatically when clock is hidden)
            Item {
                id: cardWrapper
                width: compactLoginCard.width * root.cardScale
                height: compactLoginCard.height * root.cardScale
                anchors.verticalCenter: parent.verticalCenter
                opacity: root.isLoggingIn ? 0.0 : 1.0
                enabled: !root.isLoggingIn

                Behavior on opacity {
                    NumberAnimation { duration: 300 }
                }

                CompactLoginCard {
                    id: compactLoginCard
                    anchors.top: parent.top
                    anchors.left: parent.left
                    transformOrigin: Item.TopLeft
                    scale: root.cardScale
                    userListModel: userModel
                    showSessionBadge: true
                    capsLockActive: capsLockState.locked
                    virtualKeyboardActive: virtualKeyboard.keyboardActive

                    onVirtualKeyboardRequested: {
                        virtualKeyboard.showHide()
                    }

                    onLoginRequested: function(username, password, sessionIndex) {
                        virtualKeyboard.hide()
                        root.isLoggingIn = true
                        sddm.login(username, password, sessionIndex)
                    }
                }
            }
        }

        // Login loader: Cat silhouette on pulsing blurred triangles (Center of screen)
        PavverCatLoader {
            id: catLoader
            anchors.centerIn: parent
            opacity: root.isLoggingIn ? 1.0 : 0.0
            visible: opacity > 0.0

            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }
        }

        VirtualKeyboard {
            id: virtualKeyboard
            z: 100
            inputField: compactLoginCard.virtualKeyboardTarget
            onEnterPressed: compactLoginCard.handleVirtualKeyboardEnter()
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.isLoggingIn = false
            compactLoginCard.onLoginFailed()
        }
        function onLoginSucceeded() {
            virtualKeyboard.hide()
            compactLoginCard.closePopups()
            root.isLoggingIn = true
        }
    }
}
