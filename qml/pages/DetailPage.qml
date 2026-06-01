import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0
import "../components"

ScrollView {
    id: root
    objectName: "DetailPage"

    property int animeId: 0
    property var anime: ({})

    signal back()
    signal editAnime(int animeId)
    signal addReview(int animeId)
    signal editReview(int reviewId)
    signal deleted()

    clip: true

    StackView.onActivated: loadAnime()

    Component.onCompleted: loadAnime()
    onAnimeIdChanged: loadAnime()

    function loadAnime() {
        if (animeId > 0) {
            anime = animeController.getAnime(animeId)
            reviewModel.animeId = animeId
        }
    }

    ColumnLayout {
        width: root.availableWidth
        spacing: Theme.spacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing

            Button {
                text: qsTr("← 返回")
                flat: true
                onClicked: root.back()
            }

            Item { Layout.fillWidth: true }

            Button {
                text: qsTr("编辑")
                onClicked: root.editAnime(animeId)
            }

            Button {
                text: qsTr("删除")
                onClicked: deleteDialog.open()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing

            Rectangle {
                Layout.preferredWidth: 220
                Layout.preferredHeight: 320
                radius: Theme.radius
                color: Theme.surface
                clip: true

                Image {
                    anchors.fill: parent
                    source: anime.coverPath ? "file:///" + anime.coverPath.replace(/\\/g, "/") : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }

                Label {
                    anchors.centerIn: parent
                    visible: !anime.coverPath
                    text: anime.title ? anime.title.charAt(0) : "?"
                    font.pixelSize: 72
                    color: Theme.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                Label {
                    text: anime.title || ""
                    font: Theme.titleFont
                    color: Theme.textPrimary
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: 16

                    Label {
                        text: qsTr("评分：%1").arg(anime.score > 0 ? anime.score.toFixed(1) : "—")
                        font: Theme.headingFont
                        color: Theme.warning
                    }

                    Rectangle {
                        width: 1
                        height: 20
                        color: Theme.border
                    }

                    Label {
                        text: qsTr("状态：%1").arg(anime.status || "未看")
                        font: Theme.bodyFont
                        color: Theme.textPrimary
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: anime.tags || []
                        TagChip { tagName: modelData }
                    }
                }

                Label {
                    text: qsTr("简介")
                    font: Theme.headingFont
                    color: Theme.textPrimary
                }

                Label {
                    text: anime.description || qsTr("暂无简介")
                    font: Theme.bodyFont
                    color: Theme.textSecondary
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: qsTr("感想")
                font: Theme.titleFont
                color: Theme.textPrimary
            }

            Item { Layout.fillWidth: true }

            Button {
                text: qsTr("+ 写感想")
                highlighted: true
                onClicked: root.addReview(animeId)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: reviewModel

                delegate: ReviewItem {
                    Layout.fillWidth: true
                    date: model.date
                    title: model.title
                    content: model.content
                    onClicked: root.editReview(model.reviewId)
                    onDeleteRequested: {
                        animeController.deleteReview(model.reviewId)
                        reviewModel.refresh()
                    }
                }
            }

            Label {
                visible: reviewModel.rowCount() === 0
                text: qsTr("还没有感想，点击上方按钮写下第一条吧。")
                font: Theme.bodyFont
                color: Theme.textSecondary
            }
        }
    }

    Dialog {
        id: deleteDialog
        title: qsTr("确认删除")
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Yes | Dialog.No

        Label {
            text: qsTr("确定要删除「%1」吗？所有感想也会一并删除。").arg(anime.title)
            wrapMode: Text.WordWrap
        }

        onAccepted: {
            if (animeController.deleteAnime(animeId)) {
                root.deleted()
            }
        }
    }
}
