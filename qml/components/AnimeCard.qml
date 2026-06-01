import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0

Rectangle {
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
    radius: Theme.radius
    color: Theme.surface
    border.color: Theme.border
    border.width: 1
    clip: true

    Rectangle {
        id: coverArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 180
        color: Theme.surfaceHover

        Image {
            id: coverImage
            anchors.fill: parent
            source: coverPath ? "file:///" + coverPath.replace(/\\/g, "/") : ""
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
        }

        Label {
            anchors.centerIn: parent
            visible: !coverPath || coverImage.status !== Image.Ready
            text: title.length > 0 ? title.charAt(0).toUpperCase() : "?"
            font.pixelSize: 48
            color: Theme.accent
        }

        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 8
            width: statusLabel.implicitWidth + 16
            height: 24
            radius: 12
            color: "#99000000"

            Label {
                id: statusLabel
                anchors.centerIn: parent
                text: status
                font: Theme.captionFont
                color: Theme.textPrimary
            }
        }
    }

    ColumnLayout {
        anchors.top: coverArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        spacing: 6

        Label {
            Layout.fillWidth: true
            text: title
            font: Theme.headingFont
            color: Theme.textPrimary
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Label {
                text: score > 0 ? score.toFixed(1) : "—"
                font: Theme.bodyFont
                color: Theme.warning
            }

            Label {
                text: "★"
                color: Theme.warning
            }

            Item { Layout.fillWidth: true }

            ToolButton {
                text: "✎"
                onClicked: root.editRequested()
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 4
            Repeater {
                model: tags.slice(0, 3)
                TagChip {
                    tagName: modelData
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
