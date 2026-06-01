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

    height: compact ? 24 : 30
    width: tagText.width + (removable ? 36 : (compact ? 18 : 22))
    radius: height / 2
    color: selected ? Theme.accentMuted : Theme.surfaceElevated
    border.color: selected ? Theme.accent : Theme.border
    border.width: 1

    Text {
        id: tagText
        anchors.left: parent.left
        anchors.leftMargin: compact ? 9 : 12
        anchors.verticalCenter: parent.verticalCenter
        text: tagName
        font: Theme.captionFont
        color: selected ? Theme.accentHover : Theme.textSecondary
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
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
