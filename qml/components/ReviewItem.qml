import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0
import "../components"

Rectangle {
    id: root
    property string date: ""
    property string title: ""
    property string content: ""

    signal clicked()
    signal deleteRequested()

    width: parent ? parent.width : 400
    height: contentColumn.implicitHeight + 28
    radius: Theme.radius
    color: reviewMouse.containsMouse ? Theme.surfaceElevated : Theme.surface
    border.color: reviewMouse.containsMouse ? Theme.accent : Theme.border
    border.width: 1

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 4
        radius: 2
        color: Theme.accent
        opacity: reviewMouse.containsMouse ? 0.9 : 0.45
    }

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 12
        anchors.topMargin: 14
        anchors.bottomMargin: 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: dateLabel.implicitWidth + 16
                Layout.preferredHeight: 24
                radius: 12
                color: Theme.backgroundAlt

                Label {
                    id: dateLabel
                    anchors.centerIn: parent
                    text: date
                    font: Theme.labelFont
                    color: Theme.textMuted
                }
            }

            Label {
                Layout.fillWidth: true
                text: title
                font: Theme.headingFont
                color: Theme.textPrimary
                elide: Text.ElideRight
            }

            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: deleteMouse.containsMouse ? "#3d1f1f" : "transparent"

                Icon {
                    anchors.centerIn: parent
                    iconSource: "trash-2"
                    size: Theme.iconSizeSmall
                    iconOpacity: deleteMouse.containsMouse ? 1.0 : 0.45
                }

                MouseArea {
                    id: deleteMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.deleteRequested()
                }
            }
        }

        Label {
            Layout.fillWidth: true
            text: content
            font: Theme.bodyFont
            color: Theme.textSecondary
            wrapMode: Text.WordWrap
            maximumLineCount: 4
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: reviewMouse
        anchors.fill: parent
        hoverEnabled: true
        z: -1
        onClicked: root.clicked()
    }
}
