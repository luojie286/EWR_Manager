import QtQuick
import QtQuick.Controls
import AppTheme 1.0

Button {
    id: control
    property bool active: false

    flat: true
    font: Theme.bodyFont

    background: Rectangle {
        radius: Theme.radius
        color: control.active ? Theme.accentSoft
                              : (control.down ? Theme.surfaceHover
                                              : (control.hovered ? Theme.surfaceHover : "transparent"))
        border.color: control.active ? Theme.accent : Theme.border
        border.width: control.active ? 1 : 0
    }

    contentItem: Text {
        text: control.text
        font: control.font
        color: control.active ? Theme.textPrimary : Theme.textSecondary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
