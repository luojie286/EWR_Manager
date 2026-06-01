import QtQuick
import QtQuick.Controls
import AppTheme 1.0

Button {
    id: control
    property bool active: false
    property string iconSource: ""

    flat: true
    font: Theme.bodyFont
    padding: 12

    background: Rectangle {
        radius: Theme.radius
        color: control.active ? Theme.accentMuted
                              : (control.down ? Theme.surfaceHover
                                              : (control.hovered ? Theme.surfaceElevated : "transparent"))
        border.color: control.active ? Theme.accent : (control.hovered ? Theme.border : "transparent")
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }
    }

    contentItem: Row {
        spacing: 8
        anchors.centerIn: parent

        Icon {
            visible: control.iconSource.length > 0
            iconSource: control.iconSource
            size: Theme.iconSizeSmall
            iconOpacity: control.active ? 1.0 : 0.75
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: control.text
            font: control.font
            color: control.active ? Theme.textPrimary : Theme.textSecondary
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
