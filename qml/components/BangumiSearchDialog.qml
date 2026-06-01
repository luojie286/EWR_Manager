import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0

Dialog {
    id: root

    property string initialKeyword: ""
    property var results: []

    signal subjectSelected(int subjectId)

    title: qsTr("从 Bangumi 搜索")
    modal: true
    anchors.centerIn: parent
    width: Math.min(560, parent ? parent.width - 80 : 560)
    height: Math.min(520, parent ? parent.height - 80 : 520)

    onOpened: {
        searchField.text = initialKeyword
        results = []
        if (searchField.text.trim().length > 0) {
            bangumiClient.search(searchField.text)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacing

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: qsTr("输入作品名，如：葬送的芙莉莲")
                color: Theme.textPrimary
                placeholderTextColor: Theme.textSecondary
                onAccepted: bangumiClient.search(text)

                background: Rectangle {
                    radius: 8
                    color: Theme.surface
                    border.color: searchField.activeFocus ? Theme.accent : Theme.border
                }
            }

            Button {
                text: qsTr("搜索")
                enabled: !bangumiClient.busy
                onClicked: bangumiClient.search(searchField.text)
            }
        }

        Label {
            visible: results.length === 0 && !bangumiClient.busy
            text: qsTr("输入关键词搜索 Bangumi 动画条目")
            color: Theme.textSecondary
            font: Theme.captionFont
        }

        ListView {
            id: resultList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8
            model: results

            delegate: Rectangle {
                width: resultList.width
                height: 72
                radius: Theme.radius
                color: rowMouseArea.containsMouse ? Theme.surfaceHover : Theme.surface
                border.color: Theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 56
                        radius: 6
                        color: Theme.surfaceHover
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: modelData.imageUrl || ""
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }

                        Label {
                            anchors.centerIn: parent
                            visible: !modelData.imageUrl
                            text: "?"
                            color: Theme.textSecondary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            Layout.fillWidth: true
                            text: modelData.title || ""
                            font.pixelSize: Theme.bodyFont.pixelSize
                            font.weight: Font.DemiBold
                            color: Theme.textPrimary
                            elide: Text.ElideRight
                        }

                        Label {
                            Layout.fillWidth: true
                            visible: (modelData.subtitle || "").length > 0
                            text: modelData.subtitle || ""
                            font: Theme.captionFont
                            color: Theme.textSecondary
                            elide: Text.ElideRight
                        }

                        Label {
                            text: {
                                var parts = []
                                if (modelData.date)
                                    parts.push(modelData.date)
                                if (modelData.bangumiScore > 0)
                                    parts.push("BGM " + modelData.bangumiScore.toFixed(1))
                                return parts.join(" · ")
                            }
                            font: Theme.captionFont
                            color: Theme.textSecondary
                        }
                    }
                }

                MouseArea {
                    id: rowMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !bangumiClient.busy
                    onClicked: {
                        root.close()
                        root.subjectSelected(modelData.subjectId)
                    }
                }
            }
        }

        BusyIndicator {
            Layout.alignment: Qt.AlignHCenter
            running: bangumiClient.busy
        }
    }

    Connections {
        target: bangumiClient
        function onSearchFinished(list) {
            results = list
        }
        function onErrorOccurred(message) {
            errorLabel.text = message
        }
    }

    Label {
        id: errorLabel
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        color: Theme.danger
        font: Theme.captionFont
    }
}
