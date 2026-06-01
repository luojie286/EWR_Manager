import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0
import "../components"

Item {
    id: root
    objectName: "DetailPage"

    required property int animeId
    property var anime: ({})

    signal back()
    signal editAnime(int animeId)
    signal addReview(int animeId)
    signal editReview(int reviewId)
    signal deleted()

    function refresh() {
        if (animeId > 0) {
            anime = animeController.getAnime(animeId)
            reviewModel.animeId = animeId
            reviewModel.refresh()
        }
    }

    Component.onCompleted: refresh()
    onAnimeIdChanged: refresh()
    StackView.onActivated: refresh()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PageBackBar {
            Layout.fillWidth: true
            backLabel: qsTr("← 返回首页")
            title: anime.title || qsTr("作品详情")
            onBackClicked: root.back()

            Button {
                text: qsTr("编辑")
                flat: true
                onClicked: root.editAnime(animeId)
            }

            Button {
                text: qsTr("删除")
                flat: true
                onClicked: deleteDialog.open()
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                id: contentLayout
                width: root.width
                spacing: Theme.spacing

                Item { Layout.preferredHeight: 4 }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.spacing
                    Layout.rightMargin: Theme.spacing
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

                            Label {
                                visible: (anime.bgmId || 0) > 0
                                text: qsTr("BGM #%1").arg(anime.bgmId)
                                font: Theme.captionFont
                                color: Theme.accent
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
                    Layout.leftMargin: Theme.spacing
                    Layout.rightMargin: Theme.spacing

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
                    Layout.leftMargin: Theme.spacing
                    Layout.rightMargin: Theme.spacing
                    spacing: 8

                    Repeater {
                        model: reviewModel

                        delegate: ReviewItem {
                            Layout.fillWidth: true
                            width: contentLayout.width - Theme.spacing * 2
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

                Item { Layout.preferredHeight: Theme.spacing }
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
