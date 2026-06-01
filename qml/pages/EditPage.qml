import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import AppTheme 1.0
import "../components"

ScrollView {
    id: root
    objectName: "EditPage"

    property int animeId: 0
    property bool isNew: animeId === 0

    signal back()
    signal saved()

    property var anime: isNew ? {
        title: "",
        score: 0,
        status: "未看",
        description: "",
        coverPath: "",
        tags: []
    } : animeController.getAnime(animeId)

    property string tagsText: (anime.tags || []).join(", ")

    clip: true

    Component.onCompleted: {
        if (!isNew) {
            anime = animeController.getAnime(animeId)
            tagsText = (anime.tags || []).join(", ")
        }
    }

    ColumnLayout {
        width: root.availableWidth
        spacing: Theme.spacing

        RowLayout {
            Layout.fillWidth: true

            Button {
                text: qsTr("← 返回")
                flat: true
                onClicked: root.back()
            }

            Label {
                Layout.fillWidth: true
                text: isNew ? qsTr("添加作品") : qsTr("编辑作品")
                font: Theme.titleFont
                color: Theme.textPrimary
            }

            Button {
                text: qsTr("保存")
                highlighted: true
                enabled: titleField.text.trim().length > 0
                onClicked: saveAnime()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing

            Rectangle {
                Layout.preferredWidth: 160
                Layout.preferredHeight: 220
                radius: Theme.radius
                color: Theme.surface
                clip: true

                Image {
                    id: coverPreview
                    anchors.fill: parent
                    source: coverPathField.text ? "file:///" + coverPathField.text.replace(/\\/g, "/") : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }

                Label {
                    anchors.centerIn: parent
                    visible: !coverPathField.text
                    text: qsTr("封面")
                    color: Theme.textSecondary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                Label { text: qsTr("标题 *"); color: Theme.textSecondary; font: Theme.captionFont }
                TextField {
                    id: titleField
                    Layout.fillWidth: true
                    text: anime.title || ""
                    placeholderText: qsTr("例如：葬送的芙莉莲")
                    color: Theme.textPrimary
                    background: Rectangle { radius: 8; color: Theme.surface; border.color: Theme.border }
                }

                Label { text: qsTr("评分 (0-10)"); color: Theme.textSecondary; font: Theme.captionFont }
                SpinBox {
                    id: scoreSpin
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    stepSize: 5
                    value: Math.round((anime.score || 0) * 10)
                    editable: true
                    textFromValue: function(v) { return (v / 10).toFixed(1) }
                    valueFromText: function(t) { return Math.round(parseFloat(t) * 10) }
                }

                Label { text: qsTr("观看状态"); color: Theme.textSecondary; font: Theme.captionFont }
                ComboBox {
                    id: statusCombo
                    Layout.fillWidth: true
                    model: ["未看", "在看", "看完", "弃坑"]
                    currentIndex: Math.max(0, model.indexOf(anime.status || "未看"))
                }
            }
        }

        Label { text: qsTr("封面路径"); color: Theme.textSecondary; font: Theme.captionFont }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            TextField {
                id: coverPathField
                Layout.fillWidth: true
                text: anime.coverPath || ""
                placeholderText: qsTr("选择本地图片")
                color: Theme.textPrimary
                background: Rectangle { radius: 8; color: Theme.surface; border.color: Theme.border }
            }

            Button {
                text: qsTr("浏览…")
                onClicked: fileDialog.open()
            }
        }

        Label { text: qsTr("标签（逗号分隔）"); color: Theme.textSecondary; font: Theme.captionFont }
        TextField {
            id: tagsField
            Layout.fillWidth: true
            text: tagsText
            placeholderText: qsTr("治愈, 奇幻, 公路片")
            color: Theme.textPrimary
            background: Rectangle { radius: 8; color: Theme.surface; border.color: Theme.border }
        }

        Label { text: qsTr("简介"); color: Theme.textSecondary; font: Theme.captionFont }
        TextArea {
            id: descField
            Layout.fillWidth: true
            Layout.preferredHeight: 160
            text: anime.description || ""
            wrapMode: TextArea.Wrap
            color: Theme.textPrimary
            placeholderText: qsTr("写一段简介…")
            background: Rectangle { radius: 8; color: Theme.surface; border.color: Theme.border }
        }
    }

    FileDialog {
        id: fileDialog
        title: qsTr("选择封面图片")
        nameFilters: [qsTr("图片 (*.png *.jpg *.jpeg *.webp *.bmp)")]
        onAccepted: {
            coverPathField.text = selectedFile.toLocalFile()
        }
    }

    function saveAnime() {
        var data = {
            animeId: animeId,
            title: titleField.text.trim(),
            score: scoreSpin.value / 10,
            status: statusCombo.currentText,
            description: descField.text,
            coverPath: coverPathField.text.trim(),
            tags: tagsField.text
        }

        var ok = isNew ? (animeController.addAnime(data) > 0)
                       : animeController.updateAnime(data)
        if (ok) {
            root.saved()
        }
    }
}
