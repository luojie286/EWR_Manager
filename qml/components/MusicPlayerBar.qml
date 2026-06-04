import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0

Rectangle {
    id: root

    implicitWidth: 320
    height: 44
    radius: Theme.radius
    color: "#161922cc"
    border.color: Theme.borderLight
    border.width: 1
    clip: true

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 4

        MusicIconButton {
            iconSource: musicController.playing ? "pause" : "play"
            enabled: musicController.trackCount > 0
            ToolTip.text: musicController.playing ? qsTr("暂停") : qsTr("播放")
            ToolTip.visible: hovered
            onClicked: musicController.togglePlay()
        }

        MusicIconButton {
            iconSource: "skip-forward"
            enabled: musicController.trackCount > 0
            ToolTip.text: qsTr("随机下一首")
            ToolTip.visible: hovered
            onClicked: musicController.skipNext()
        }

        Icon {
            iconSource: "music"
            size: 14
            iconOpacity: musicController.enabled ? 0.85 : 0.35
            Layout.leftMargin: 2
        }

        Label {
            Layout.fillWidth: true
            Layout.minimumWidth: 40
            text: musicController.trackCount > 0
                  ? (musicController.currentTrackName || qsTr("准备播放…"))
                  : qsTr("未添加音乐")
            font: Theme.captionFont
            color: musicController.trackCount > 0 ? Theme.textPrimary : Theme.textMuted
            elide: Text.ElideRight
        }

        MusicIconButton {
            Layout.leftMargin: 2
            iconSource: musicController.muted ? "volume-x" : "volume-2"
            ToolTip.text: musicController.muted ? qsTr("取消静音") : qsTr("静音")
            ToolTip.visible: hovered
            onClicked: musicController.toggleMute()
        }

        MusicIconButton {
            iconSource: "folder-open"
            ToolTip.text: qsTr("音乐列表")
            ToolTip.visible: hovered
            onClicked: musicSettingsDialog.open()
        }
    }

    MusicSettingsDialog {
        id: musicSettingsDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
    }
}
