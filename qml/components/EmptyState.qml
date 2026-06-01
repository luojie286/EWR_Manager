import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0

Item {
    id: root

    property string iconSource: "inbox"
    property string title: qsTr("暂无内容")
    property string subtitle: ""
    property alias actionButton: actionBtn

    implicitWidth: column.implicitWidth
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column
        anchors.centerIn: parent
        spacing: 12

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 88
            height: 88
            radius: 44
            color: Theme.accentMuted
            border.color: Theme.borderLight
            border.width: 1

            Icon {
                anchors.centerIn: parent
                iconSource: root.iconSource
                size: 36
                iconOpacity: 0.85
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.title
            font: Theme.headingFont
            color: Theme.textPrimary
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            visible: subtitle.length > 0
            text: root.subtitle
            font: Theme.bodyFont
            color: Theme.textSecondary
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.maximumWidth: 320
        }

        Item {
            id: actionBtn
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: childrenRect.height
            Layout.preferredWidth: childrenRect.width
        }
    }
}
