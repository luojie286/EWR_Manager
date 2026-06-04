import QtQuick
import AppTheme 1.0

Item {
    id: root

    readonly property int particleCount: 52
    readonly property string coverSource: {
        if (!musicController.currentCoverPath)
            return ""
        return "file:///" + musicController.currentCoverPath.replace(/\\/g, "/")
    }
    readonly property bool hasCover: coverSource.length > 0 && coverImage.status === Image.Ready

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#04060c" }
            GradientStop { position: 0.38; color: Theme.background }
            GradientStop { position: 0.72; color: "#0b1222" }
            GradientStop { position: 1.0; color: "#081428" }
        }
    }

    Repeater {
        model: [
            { xRatio: -0.12, yRatio: -0.08, size: 540, orbColor: Theme.accent, alpha: 0.075, dx: 28, dy: 18, dur: 24000 },
            { xRatio: 0.68, yRatio: 0.48, size: 460, orbColor: "#3d6fd8", alpha: 0.06, dx: -22, dy: 14, dur: 30000 },
            { xRatio: 0.22, yRatio: 0.78, size: 380, orbColor: "#5b8def", alpha: 0.045, dx: 16, dy: -20, dur: 27000 }
        ]

        delegate: Rectangle {
            required property real xRatio
            required property real yRatio
            required property real size
            required property color orbColor
            required property real alpha
            required property real dx
            required property real dy
            required property int dur

            width: size
            height: size
            radius: width / 2
            color: orbColor
            opacity: alpha

            x: xRatio * root.width
            y: yRatio * root.height

            SequentialAnimation on x {
                loops: Animation.Infinite
                running: root.visible
                NumberAnimation {
                    from: xRatio * root.width
                    to: xRatio * root.width + dx
                    duration: dur
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: xRatio * root.width - dx * 0.6
                    duration: dur * 0.9
                    easing.type: Easing.InOutSine
                }
            }

            SequentialAnimation on y {
                loops: Animation.Infinite
                running: root.visible
                NumberAnimation {
                    from: yRatio * root.height
                    to: yRatio * root.height + dy
                    duration: dur * 1.1
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: yRatio * root.height - dy * 0.7
                    duration: dur
                    easing.type: Easing.InOutSine
                }
            }
        }
    }

    Repeater {
        model: root.particleCount

        delegate: Rectangle {
            required property int index

            width: 1.4 + (index % 5) * 0.65
            height: width
            radius: width / 2
            color: index % 7 === 0 ? "#8ec0ff" : "#ffffff"

            property real anchorX: ((index * 137) % 997) / 997
            property real anchorY: ((index * 293) % 991) / 991
            property real driftX: 18 + (index % 9) * 4
            property real driftY: 55 + (index % 11) * 8

            x: anchorX * Math.max(0, root.width - width)
            y: anchorY * Math.max(0, root.height - height)
            opacity: 0.05 + (index % 9) * 0.016

            SequentialAnimation on y {
                loops: Animation.Infinite
                running: root.visible
                NumberAnimation {
                    from: anchorY * Math.max(0, root.height - height)
                    to: Math.max(0, anchorY * Math.max(0, root.height - height) - driftY)
                    duration: 7000 + (index % 8) * 900
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: Math.min(root.height - height, anchorY * Math.max(0, root.height - height) + driftY * 0.45)
                    duration: 8500 + (index % 6) * 1100
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: anchorY * Math.max(0, root.height - height)
                    duration: 6500 + (index % 5) * 800
                    easing.type: Easing.InOutSine
                }
            }

            SequentialAnimation on x {
                loops: Animation.Infinite
                running: root.visible
                NumberAnimation {
                    from: anchorX * Math.max(0, root.width - width)
                    to: anchorX * Math.max(0, root.width - width) + (index % 2 === 0 ? driftX : -driftX)
                    duration: 10000 + (index % 7) * 700
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: anchorX * Math.max(0, root.width - width) - (index % 2 === 0 ? driftX * 0.5 : -driftX * 0.5)
                    duration: 11000 + (index % 4) * 600
                    easing.type: Easing.InOutSine
                }
            }

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: root.visible
                NumberAnimation {
                    from: 0.05 + (index % 9) * 0.016
                    to: 0.22 + (index % 4) * 0.03
                    duration: 2800 + (index % 6) * 400
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    to: 0.04 + (index % 5) * 0.012
                    duration: 3200 + (index % 7) * 350
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    Item {
        id: coverLayer
        anchors.fill: parent
        visible: hasCover
        opacity: hasCover ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

        Image {
            id: coverImage
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.height
            fillMode: Image.PreserveAspectFit
            source: root.coverSource
            opacity: 0.36
            smooth: true

            Behavior on opacity { NumberAnimation { duration: 450 } }
        }

        Rectangle {
            anchors.left: coverImage.left
            anchors.top: coverImage.top
            anchors.bottom: coverImage.bottom
            width: Math.min(120, coverImage.width * 0.35)
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#0b0d12ee" }
                GradientStop { position: 1.0; color: "#00000000" }
            }
        }

        Rectangle {
            anchors.right: coverImage.right
            anchors.top: coverImage.top
            anchors.bottom: coverImage.bottom
            width: Math.min(120, coverImage.width * 0.35)
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#00000000" }
                GradientStop { position: 1.0; color: "#0b0d12ee" }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "#00000000" }
            GradientStop { position: 0.55; color: "#00000000" }
            GradientStop { position: 1.0; color: "#0b0d1200" }
        }
        opacity: 0.35
    }
}
