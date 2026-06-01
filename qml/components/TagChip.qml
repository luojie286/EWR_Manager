import QtQuick
import QtQuick.Controls
import AppTheme 1.0

Rectangle {
    id: root
    property string tagName: ""
    property bool selected: false
    property bool removable: false

    property bool compact: false

    signal clicked()
    signal removeRequested()

    height: compact ? 22 : 28
    width: tagText.width + (removable ? 36 : (compact ? 20 : 24))
    radius: height / 2
    color: selected ? Theme.accentSoft : Theme.surface
    border.color: selected ? Theme.accent : Theme.border
    border.width: 1

    Text {
        id: tagText
        anchors.left: parent.left
        anchors.leftMargin: compact ? 8 : 12
        anchors.verticalCenter: parent.verticalCenter
        text: tagName
        font: Theme.captionFont
        color: selected ? Theme.textPrimary : Theme.textSecondary
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }

    ToolButton {
        visible: removable
        anchors.right: parent.right
        anchors.rightMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        height: 24
        text: "×"
        font.pixelSize: 14
        onClicked: root.removeRequested()
    }
}
