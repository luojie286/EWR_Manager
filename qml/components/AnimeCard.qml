import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0

Item {
    id: root

    property int animeId: 0
    property string title: ""
    property real score: 0
    property string status: ""
    property string coverPath: ""
    property var tags: []

    signal clicked()
    signal editRequested()

    width: Theme.cardWidth
    height: Theme.cardHeight

    scale: cardMouse.containsMouse ? 1.02 : 1.0
    transformOrigin: Item.Top
    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: cardMouse.containsMouse ? 4 : 2
        radius: Theme.radiusLarge
        color: "#50000000"
        opacity: cardMouse.containsMouse ? 0.55 : 0.35
        z: -1
    }

    Rectangle {
        id: cardBody
        anchors.fill: parent
        radius: Theme.radiusLarge
        color: Theme.surface
        border.color: cardMouse.containsMouse ? Theme.accent : Theme.border
        border.width: cardMouse.containsMouse ? 1.5 : 1
        clip: true

        Behavior on border.color { ColorAnimation { duration: 140 } }

        Rectangle {
            id: coverArea
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Theme.cardCoverHeight
            color: "#0a0c10"
            clip: true

            Image {
                id: coverImage
                anchors.fill: parent
                source: coverPath ? "file:///" + coverPath.replace(/\\/g, "/") : ""
                fillMode: Image.PreserveAspectFit
                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter
                visible: coverImage.status === Image.Ready

                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            Rectangle {
                anchors.fill: parent
                visible: !coverPath || coverImage.status !== Image.Ready
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Theme.accentMuted }
                    GradientStop { position: 1.0; color: Theme.surfaceHover }
                }

                Icon {
                    anchors.centerIn: parent
                    iconSource: "film"
                    size: 44
                    iconOpacity: 0.35
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 16
                    text: title.length > 0 ? title.charAt(0).toUpperCase() : "?"
                    font.pixelSize: 28
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                    opacity: 0.55
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 40
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: "#cc161922" }
                }
            }

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 10
                height: 26
                width: statusPill.implicitWidth + 16
                radius: 13
                color: Theme.statusBgColor(status)
                border.color: Theme.statusColor(status)
                border.width: 1
                opacity: 0.92

                Label {
                    id: statusPill
                    anchors.centerIn: parent
                    text: status
                    font: Theme.labelFont
                    color: Theme.statusColor(status)
                }
            }
        }

        ColumnLayout {
            anchors.top: coverArea.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 10
            spacing: 4

            Label {
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                text: title
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: Theme.textPrimary
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                spacing: 4

                Icon {
                    iconSource: "star"
                    size: Theme.iconSizeSmall
                    iconOpacity: score > 0 ? 1.0 : 0.35
                }

                Label {
                    text: score > 0 ? score.toFixed(1) : "—"
                    font: Theme.bodyFont
                    color: score > 0 ? Theme.warning : Theme.textMuted
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: editMouseArea.containsMouse ? Theme.accentMuted : "transparent"
                    border.color: editMouseArea.containsMouse ? Theme.accent : "transparent"
                    border.width: 1

                    Icon {
                        anchors.centerIn: parent
                        iconSource: "pencil"
                        size: Theme.iconSizeSmall
                        iconOpacity: editMouseArea.containsMouse ? 1.0 : 0.55
                    }

                    MouseArea {
                        id: editMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.editRequested()
                    }
                }
            }

            Flow {
                id: tagFlow
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(implicitHeight, 52)
                clip: true
                spacing: 4

                Repeater {
                    model: tags.slice(0, 3)
                    TagChip {
                        compact: true
                        tagName: modelData
                    }
                }
            }
        }
    }

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
