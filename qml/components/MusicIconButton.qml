import QtQuick
import QtQuick.Controls
import AppTheme 1.0

Button {
    id: control

    property string iconSource: ""
    property int iconSize: 14

    implicitWidth: 26
    implicitHeight: 26
    padding: 0

    background: Rectangle {
        radius: 13
        color: control.down ? Theme.surfaceHover
              : (control.hovered ? Theme.surfaceElevated : "#ffffff08")
        border.color: control.hovered ? Theme.border : "transparent"
        border.width: 1
    }

    contentItem: Icon {
        anchors.centerIn: parent
        iconSource: control.iconSource
        size: control.iconSize
        iconOpacity: control.enabled ? 0.9 : 0.35
    }
}
