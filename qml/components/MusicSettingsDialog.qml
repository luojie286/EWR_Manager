import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import AppTheme 1.0

Dialog {
    id: root

    title: qsTr("音乐列表")
    modal: true
    anchors.centerIn: parent
    width: Math.min(560, parent ? parent.width - 80 : 560)
    height: Math.min(480, parent ? parent.height - 80 : 480)
    padding: Theme.spacing

    background: Rectangle {
        radius: Theme.radiusLarge
        color: Theme.surface
        border.color: Theme.borderLight
        border.width: 1
    }

    header: Label {
        text: root.title
        font: Theme.headingFont
        color: Theme.textPrimary
        padding: Theme.spacing
    }

    contentItem: ColumnLayout {
        spacing: Theme.spacing

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTr("将音频文件放入音乐文件夹，或点击下方按钮添加。支持 mp3、flac、ogg、wav、m4a 等格式。")
            font: Theme.captionFont
            color: Theme.textSecondary
        }

        Label {
            Layout.fillWidth: true
            text: qsTr("文件夹：%1").arg(musicController.musicDir)
            font: Theme.labelFont
            color: Theme.textMuted
            elide: Text.ElideMiddle
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Button {
                text: qsTr("添加文件")
                font: Theme.bodyFont
                onClicked: addMusicDialog.open()

                contentItem: RowLayout {
                    spacing: 6
                    Icon { iconSource: "plus"; size: Theme.iconSizeSmall }
                    Text { text: parent.parent.text; font: parent.parent.font; color: Theme.textPrimary }
                }
            }

            Button {
                text: qsTr("扫描文件夹")
                font: Theme.bodyFont
                onClicked: musicController.scanMusicDirectory()

                contentItem: RowLayout {
                    spacing: 6
                    Icon { iconSource: "search"; size: Theme.iconSizeSmall }
                    Text { text: parent.parent.text; font: parent.parent.font; color: Theme.textPrimary }
                }
            }

            Button {
                text: qsTr("打开文件夹")
                font: Theme.bodyFont
                onClicked: musicController.openMusicFolder()

                contentItem: RowLayout {
                    spacing: 6
                    Icon { iconSource: "folder-open"; size: Theme.iconSizeSmall }
                    Text { text: parent.parent.text; font: parent.parent.font; color: Theme.textPrimary }
                }
            }

            Item { Layout.fillWidth: true }

            Label {
                text: qsTr("共 %1 首").arg(musicController.trackCount)
                font: Theme.captionFont
                color: Theme.textSecondary
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.radius
            color: Theme.backgroundAlt
            border.color: Theme.border
            border.width: 1
            clip: true

            ListView {
                id: trackList
                anchors.fill: parent
                anchors.margins: 4
                model: musicController.trackCount
                spacing: 2
                clip: true
                visible: count > 0

                delegate: ItemDelegate {
                    width: trackList.width
                    height: 40
                    text: musicController.trackNameAt(index)

                    background: Rectangle {
                        radius: Theme.radiusSmall
                        color: parent.highlighted ? Theme.accentMuted
                              : (parent.hovered ? Theme.surfaceHover : "transparent")
                    }

                    contentItem: RowLayout {
                        spacing: 8

                        Icon {
                            iconSource: "music"
                            size: Theme.iconSizeSmall
                            iconOpacity: 0.7
                        }

                        Text {
                            Layout.fillWidth: true
                            text: musicController.trackNameAt(index)
                            font: Theme.bodyFont
                            color: Theme.textPrimary
                            elide: Text.ElideRight
                        }

                        ActionButton {
                            compact: true
                            actionType: "delete"
                            ToolTip.text: qsTr("从列表移除")
                            ToolTip.visible: hovered
                            onClicked: musicController.removeTrackAt(index)
                        }
                    }
                }
            }

            Label {
                anchors.centerIn: parent
                visible: musicController.trackCount === 0
                text: qsTr("暂无音乐，请添加文件或放入音乐文件夹")
                font: Theme.bodyFont
                color: Theme.textMuted
                horizontalAlignment: Text.AlignHCenter
                width: parent.width - 32
                wrapMode: Text.WordWrap
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            CheckBox {
                text: qsTr("启动时自动播放")
                font: Theme.bodyFont
                checked: musicController.autoplay
                onToggled: musicController.setAutoplay(checked)
            }

            CheckBox {
                text: qsTr("启用背景音乐")
                font: Theme.bodyFont
                checked: musicController.enabled
                onToggled: musicController.setEnabled(checked)
            }

            Item { Layout.fillWidth: true }

            Button {
                text: qsTr("清空列表")
                font: Theme.bodyFont
                enabled: musicController.trackCount > 0
                onClicked: musicController.clearTracks()
            }
        }
    }

    FileDialog {
        id: addMusicDialog
        title: qsTr("选择音乐文件")
        fileMode: FileDialog.OpenFiles
        nameFilters: [
            qsTr("音频文件 (*.mp3 *.flac *.ogg *.wav *.m4a *.aac *.wma *.opus)")
        ]
        onAccepted: {
            var urls = []
            for (var i = 0; i < selectedFiles.length; ++i)
                urls.push(selectedFiles[i])
            musicController.addTrackUrls(urls)
        }
    }
}
