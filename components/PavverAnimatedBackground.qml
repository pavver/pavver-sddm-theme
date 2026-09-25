import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects

Item {
    id: root
    anchors.fill: parent

    // Configurable parameters
    property real widthPercent: 0.85
    property real topMarginPercent: 0.048
    property alias bannerItem: bannerContainer
    property bool isBannerVisible: true

    property real customBannerWidth: -1
    property real customBannerHeight: -1
    property real customTopMargin: -1

    readonly property real bannerBottom: (isBannerVisible && bannerContainer.visible && bannerContainer.height > 0) ? (bannerContainer.y + bannerContainer.height) : 0

    // Main background canvas color matching #555
    Rectangle {
        anchors.fill: parent
        color: "#555555"
    }

    // Centered banner item: scaled proportionally by both width AND height
    Item {
        id: bannerContainer
        visible: root.isBannerVisible

        readonly property real bannerRatio: 675.0 / 190.0

        height: {
            if (!root.isBannerVisible) return 0;
            if (root.customBannerHeight > 0) return root.customBannerHeight;
            var fromWidth = (parent.width * root.widthPercent) / bannerRatio;
            var maxHeight = parent.height * 0.45;
            return Math.min(fromWidth, maxHeight);
        }
        width: {
            if (!root.isBannerVisible) return 0;
            if (root.customBannerWidth > 0) return root.customBannerWidth;
            return height * bannerRatio;
        }

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.customTopMargin >= 0 ? root.customTopMargin : Math.round(Math.max(16, parent.height * root.topMarginPercent))

        Behavior on opacity {
            NumberAnimation { duration: 300 }
        }

        readonly property real scaleFactor: width / 675.0
        property real animTime: 0

        // Single unified hardware-synchronized master timeline (6000ms loop)
        NumberAnimation on animTime {
            from: 0
            to: 6000
            duration: 6000
            loops: Animation.Infinite
            running: true
        }

        // Pure mathematical scale function: zero drift, perfectly synchronized
        // Uses smooth sine easing to eliminate harsh velocity jumps at direction changes
        function getScale(index) {
            var startTime = index * 1000.0;
            var dt = (animTime - startTime) % 6000.0;
            if (dt < 0) dt += 6000.0;
            if (dt < 2000.0) {
                return 1.0 + 0.3 * Math.sin((dt / 2000.0) * Math.PI);
            }
            return 1.0;
        }

        // 1. Static background: #333 box + inner glow + embossed "PAVVER" text with shadow
        // Rendered and cached at crisp native resolution
        Image {
            id: bgImage
            source: Qt.resolvedUrl("../assets/pavver_static_bg.svg")
            anchors.fill: parent
            sourceSize.width: bannerContainer.width
            sourceSize.height: bannerContainer.height
        }

        // 2. The 6 animated triangles - Full native resolution, 8x MSAA, no pixelation!
        Item {
            id: trianglesLayer
            anchors.fill: parent

            layer.enabled: true
            layer.samples: 8
            layer.effect: GaussianBlur {
                radius: 1.5 * 2.0 * bannerContainer.scaleFactor
                samples: 16
                transparentBorder: true
            }

            Item {
                id: trianglesOrigin
                x: 70 * bannerContainer.scaleFactor
                y: 60 * bannerContainer.scaleFactor

                Shape {
                    id: t1
                    preferredRendererType: Shape.GeometryRenderer
                    ShapePath {
                        fillColor: "yellow"
                        strokeWidth: 0
                        strokeColor: "transparent"
                        PathSvg { path: "M -49 0 L 0 0 L -30 -40 Z" }
                    }
                    transform: Scale {
                        origin.x: 0; origin.y: 0
                        xScale: bannerContainer.scaleFactor * bannerContainer.getScale(0)
                        yScale: bannerContainer.scaleFactor * bannerContainer.getScale(0)
                    }
                }

                Shape {
                    id: t2
                    preferredRendererType: Shape.GeometryRenderer
                    ShapePath {
                        fillColor: "blue"
                        strokeWidth: 0
                        strokeColor: "transparent"
                        PathSvg { path: "M 24 -40 L 0 0 L -30 -40 Z" }
                    }
                    transform: Scale {
                        origin.x: 0; origin.y: 0
                        xScale: bannerContainer.scaleFactor * bannerContainer.getScale(1)
                        yScale: bannerContainer.scaleFactor * bannerContainer.getScale(1)
                    }
                }

                Shape {
                    id: t3
                    preferredRendererType: Shape.GeometryRenderer
                    ShapePath {
                        fillColor: "yellow"
                        strokeWidth: 0
                        strokeColor: "transparent"
                        PathSvg { path: "M 24 -40 L 0 0 L 24 56 Z" }
                    }
                    transform: Scale {
                        origin.x: 0; origin.y: 0
                        xScale: bannerContainer.scaleFactor * bannerContainer.getScale(2)
                        yScale: bannerContainer.scaleFactor * bannerContainer.getScale(2)
                    }
                }

                Shape {
                    id: t4
                    preferredRendererType: Shape.GeometryRenderer
                    ShapePath {
                        fillColor: "blue"
                        strokeWidth: 0
                        strokeColor: "transparent"
                        PathSvg { path: "M 0 96 L 0 0 L 24 56 Z" }
                    }
                    transform: Scale {
                        origin.x: 0; origin.y: 0
                        xScale: bannerContainer.scaleFactor * bannerContainer.getScale(3)
                        yScale: bannerContainer.scaleFactor * bannerContainer.getScale(3)
                    }
                }

                Shape {
                    id: t5
                    preferredRendererType: Shape.GeometryRenderer
                    ShapePath {
                        fillColor: "yellow"
                        strokeWidth: 0
                        strokeColor: "transparent"
                        PathSvg { path: "M 0 96 L 0 0 L -48 96 Z" }
                    }
                    transform: Scale {
                        origin.x: 0; origin.y: 0
                        xScale: bannerContainer.scaleFactor * bannerContainer.getScale(4)
                        yScale: bannerContainer.scaleFactor * bannerContainer.getScale(4)
                    }
                }

                Shape {
                    id: t6
                    preferredRendererType: Shape.GeometryRenderer
                    ShapePath {
                        fillColor: "blue"
                        strokeWidth: 0
                        strokeColor: "transparent"
                        PathSvg { path: "M -48 0 L 0 0 L -48 96 Z" }
                    }
                    transform: Scale {
                        origin.x: 0; origin.y: 0
                        xScale: bannerContainer.scaleFactor * bannerContainer.getScale(5)
                        yScale: bannerContainer.scaleFactor * bannerContainer.getScale(5)
                    }
                }
            }
        }

        // 3. Cat sitting on top of the triangles
        Image {
            id: catImage
            source: Qt.resolvedUrl("../assets/cat.svg")
            anchors.fill: parent
            sourceSize.width: bannerContainer.width
            sourceSize.height: bannerContainer.height
        }
    }
}
