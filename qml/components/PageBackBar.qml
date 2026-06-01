import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0

Rectangle {
    id: root

    property string title: ""
    property string backLabel: qsTr("← 返回")

    signal backClicked()

    default property alias actions: actionsLayout.data

    implicitHeight: 56
    color: Theme.surface

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.border
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: Theme.spacing
        spacing: 12

        Button {
            id: backButton
            text: root.backLabel
            Layout.preferredHeight: 40
            Layout.minimumWidth: 96
            onClicked: root.backClicked()

            background: Rectangle {
                radius: Theme.radius
                color: backButton.pressed ? Theme.accent
                      : (backButton.hovered ? Theme.accentSoft : Theme.accentSoft)
                border.color: Theme.accent
                border.width: 1
            }

            contentItem: Text {
                text: backButton.text
                font.pixelSize: Theme.bodyFont.pixelSize
                font.weight: Font.DemiBold
                color: Theme.textPrimary
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
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
