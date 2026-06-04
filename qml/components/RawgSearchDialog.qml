import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0

Dialog {
    id: root

    property string initialKeyword: ""
    property var results: []
    property bool editingApiKey: false

    signal gameSelected(int gameId)

    title: qsTr("从 RAWG 搜索游戏")
    modal: true
    anchors.centerIn: parent
    width: Math.min(560, parent ? parent.width - 80 : 560)
    height: Math.min(editingApiKey || !rawgClient.hasApiKey ? 580 : 520, parent ? parent.height - 80 : 580)

    onOpened: {
        editingApiKey = !rawgClient.hasApiKey
        apiKeyField.text = ""
        searchField.text = initialKeyword
        results = []
        errorLabel.text = ""
        if (rawgClient.hasApiKey && searchField.text.trim().length > 0)
            rawgClient.search(searchField.text)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacing

        RowLayout {
            Layout.fillWidth: true
            visible: rawgClient.hasApiKey && !editingApiKey
            spacing: 8

            Label {
                Layout.fillWidth: true
                text: qsTr("RAWG API Key 已配置")
                font: Theme.captionFont
                color: Theme.textSecondary
            }

            Button {
                text: qsTr("更改")
                flat: true
                onClicked: {
                    editingApiKey = true
                    apiKeyField.text = ""
                    apiKeyField.forceActiveFocus()
                }
            }

            Button {
                text: qsTr("清除")
                flat: true
                onClicked: {
                    rawgClient.clearApiKey()
                    editingApiKey = true
                    apiKeyField.text = ""
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: editingApiKey || !rawgClient.hasApiKey
            spacing: 6

            Label {
                Layout.fillWidth: true
                text: rawgClient.hasApiKey
                    ? qsTr("输入新的 RAWG API Key")
                    : qsTr("首次使用需填写 RAWG API Key")
                font: Theme.captionFont
                color: Theme.textSecondary
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                TextField {
                    id: apiKeyField
                    Layout.fillWidth: true
                    placeholderText: qsTr("在 rawg.io/apidocs 免费注册获取")
                    echoMode: TextInput.Password
                    color: Theme.textPrimary
                    placeholderTextColor: Theme.textSecondary

                    background: Rectangle {
                        radius: 8
                        color: Theme.surface
                        border.color: apiKeyField.activeFocus ? Theme.accent : Theme.border
                    }
                }

                Button {
                    text: qsTr("保存")
                    enabled: apiKeyField.text.trim().length > 0
                    onClicked: {
                        rawgClient.setApiKey(apiKeyField.text.trim())
                        editingApiKey = false
                        apiKeyField.text = ""
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: qsTr("输入游戏名，如：Elden Ring 或 艾尔登法环")
                color: Theme.textPrimary
                placeholderTextColor: Theme.textSecondary
                enabled: rawgClient.hasApiKey
                onAccepted: rawgClient.search(text)

                background: Rectangle {
                    radius: 8
                    color: Theme.surface
                    border.color: searchField.activeFocus ? Theme.accent : Theme.border
                }
            }

            Button {
                text: qsTr("搜索")
                enabled: rawgClient.hasApiKey && !rawgClient.busy
                onClicked: rawgClient.search(searchField.text)
            }
        }

        Label {
            visible: results.length === 0 && !rawgClient.busy && rawgClient.hasApiKey
            text: qsTr("导入时自动翻译为中文，并下载封面")
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
                            text: {
                                var parts = []
                                if (modelData.released)
                                    parts.push(modelData.released)
                                if (modelData.metacritic > 0)
                                    parts.push("MC " + modelData.metacritic)
                                else if (modelData.rating > 0)
                                    parts.push(modelData.rating.toFixed(1) + "/5")
                                if (modelData.genres)
                                    parts.push(modelData.genres)
                                return parts.join(" · ")
                            }
                            font: Theme.captionFont
                            color: Theme.textSecondary
                            elide: Text.ElideRight
                        }
                    }
                }

                MouseArea {
                    id: rowMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !rawgClient.busy
                    onClicked: {
                        root.close()
                        root.gameSelected(modelData.gameId)
                    }
                }
            }
        }

        BusyIndicator {
            Layout.alignment: Qt.AlignHCenter
            running: rawgClient.busy
        }
    }

    Connections {
        target: rawgClient
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
