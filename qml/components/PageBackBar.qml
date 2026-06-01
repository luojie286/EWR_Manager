import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0

Rectangle {
    id: root

    property string title: ""
    property string backLabel: qsTr("返回")

    signal backClicked()

    default property alias actions: actionsLayout.data

    implicitHeight: 60
    radius: Theme.radiusLarge
    color: Theme.surface
    border.color: Theme.borderLight
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: Theme.spacing
        spacing: 12

        Button {
            id: backButton
            Layout.preferredHeight: 40
            Layout.minimumWidth: 100
            onClicked: root.backClicked()

            contentItem: RowLayout {
                spacing: 6

                Icon {
                    iconSource: "arrow-left"
                    size: Theme.iconSizeSmall
                }

                Text {
                    text: root.backLabel.replace("← ", "")
                    font.pixelSize: Theme.bodyFont.pixelSize
                    font.weight: Font.Medium
                    color: Theme.textPrimary
                }
            }

            background: Rectangle {
                radius: Theme.radius
                color: backButton.pressed ? Theme.accentMuted
                      : (backButton.hovered ? Theme.surfaceElevated : Theme.surfaceHover)
                border.color: backButton.hovered ? Theme.accent : Theme.border
                border.width: 1
            }
        }

        Label {
            Layout.fillWidth: true
            text: root.title
            font: Theme.headingFont
            color: Theme.textPrimary
            elide: Text.ElideRight
        }

        RowLayout {
            id: actionsLayout
            spacing: 8
        }
    }
}
