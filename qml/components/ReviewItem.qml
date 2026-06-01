import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0

Rectangle {
    id: root
    property string date: ""
    property string title: ""
    property string content: ""

    signal clicked()
    signal deleteRequested()

    width: parent ? parent.width : 400
    height: contentColumn.implicitHeight + 24
    radius: Theme.radius
    color: Theme.surface
    border.color: Theme.border
    border.width: 1

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: date
                font: Theme.captionFont
                color: Theme.textSecondary
            }

            Label {
                Layout.fillWidth: true
                text: title
                font: Theme.headingFont
                color: Theme.textPrimary
                elide: Text.ElideRight
            }

            ToolButton {
                text: "🗑"
                onClicked: root.deleteRequested()
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
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
