import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0

Button {
    id: control

    property string actionType: "default"
    property string iconSource: ""
    property bool compact: false

    implicitHeight: compact ? 32 : 38
    implicitWidth: compact ? 32 : Math.max(contentRow.implicitWidth + leftPadding + rightPadding, 72)
    topPadding: compact ? 0 : 8
    bottomPadding: compact ? 0 : 8
    leftPadding: compact ? 0 : 12
    rightPadding: compact ? 0 : 12

    readonly property string resolvedIcon: {
        if (iconSource.length > 0)
            return iconSource
        if (actionType === "edit")
            return "pencil"
        if (actionType === "delete")
            return "trash-2"
        return ""
    }

    readonly property color fillColor: {
        if (actionType === "edit")
            return control.down ? Theme.accentMuted : (control.hovered ? Theme.accentMuted : Theme.surfaceElevated)
        if (actionType === "delete")
            return control.down ? "#4a2020" : (control.hovered ? "#3d1f1f" : "#2a1818")
        return control.down ? Theme.surfaceHover : Theme.surfaceElevated
    }

    readonly property color borderColor: {
        if (actionType === "edit")
            return control.hovered || control.down ? Theme.accent : Theme.border
        if (actionType === "delete")
            return control.hovered || control.down ? Theme.danger : "#7f3d3d"
        return Theme.border
    }

    readonly property color labelColor: {
        if (actionType === "edit")
            return control.hovered || control.down ? Theme.accentHover : Theme.textPrimary
        if (actionType === "delete")
            return control.hovered || control.down ? "#ffb4b4" : Theme.danger
        return Theme.textPrimary
    }

    background: Rectangle {
        radius: compact ? 16 : Theme.radiusSmall
        color: fillColor
        border.color: borderColor
        border.width: 1.5
        clip: true

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    contentItem: RowLayout {
        id: contentRow
        spacing: compact ? 0 : 6

        Icon {
            visible: resolvedIcon.length > 0
            iconSource: resolvedIcon
            size: compact ? Theme.iconSizeSmall : Theme.iconSizeSmall
            iconOpacity: 0.95
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: !compact && control.text.length > 0
            text: control.text
            font.pixelSize: Theme.bodyFont.pixelSize
            font.weight: Font.Medium
            color: labelColor
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
