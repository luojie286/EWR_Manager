import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0
import "../components"

Item {
    id: root
    objectName: "DetailPage"

    property string section: "anime"
    required property int workId
    property var work: ({})

    readonly property var ctrl: section === "game" ? gameController : animeController
    readonly property var revModel: section === "game" ? gameReviewModel : reviewModel
    readonly property bool isGame: section === "game"
    readonly property string defaultStatus: isGame ? "未玩" : "未看"

    signal back()
    signal editWork(int workId)
    signal addReview(int workId)
    signal editReview(int reviewId)
    signal deleted()

    function refresh() {
        if (workId > 0) {
            work = isGame ? gameController.getGame(workId) : animeController.getAnime(workId)
            if (isGame) {
                gameReviewModel.gameId = workId
                gameReviewModel.refresh()
            } else {
                reviewModel.animeId = workId
                reviewModel.refresh()
            }
        }
    }

    Component.onCompleted: refresh()
    onWorkIdChanged: refresh()
    StackView.onActivated: refresh()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PageBackBar {
            Layout.fillWidth: true
            backLabel: qsTr("← 返回首页")
            title: work.title || (isGame ? qsTr("游戏详情") : qsTr("作品详情"))
            onBackClicked: root.back()

            ActionButton {
                Layout.preferredHeight: 38
                text: qsTr("编辑")
                actionType: "edit"
                onClicked: root.editWork(workId)
            }

            ActionButton {
                Layout.preferredHeight: 38
                text: qsTr("删除")
                actionType: "delete"
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
                        Layout.preferredWidth: 240
                        Layout.preferredHeight: 340
                        radius: Theme.radiusLarge
                        color: Theme.surfaceHover
                        clip: true
                        border.color: Theme.borderLight
                        border.width: 1

                        CoverImage {
                            id: detailCoverDisplay
                            anchors.fill: parent
                            anchors.margins: 1
                            source: work.coverPath ? "file:///" + work.coverPath.replace(/\\/g, "/") : ""
                        }

                        Rectangle {
                            anchors.fill: parent
                            visible: !work.coverPath || !detailCoverDisplay.ready
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0.0; color: Theme.accentMuted }
                                GradientStop { position: 1.0; color: Theme.surfaceHover }
                            }

                            Icon {
                                anchors.centerIn: parent
                                iconSource: isGame ? "sparkles" : "film"
                                size: 56
                                iconOpacity: 0.3
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        Label {
                            text: work.title || ""
                            font: Theme.titleFont
                            color: Theme.textPrimary
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            spacing: 10

                            Rectangle {
                                implicitWidth: scoreRow.implicitWidth + 20
                                implicitHeight: 34
                                radius: 17
                                color: Theme.backgroundAlt
                                border.color: Theme.border
                                border.width: 1

                                RowLayout {
                                    id: scoreRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Icon {
                                        iconSource: "star"
                                        size: Theme.iconSizeSmall
                                    }

                                    Label {
                                        text: work.score > 0 ? work.score.toFixed(1) : "—"
                                        font: Theme.headingFont
                                        color: Theme.warning
                                    }
                                }
                            }

                            Rectangle {
                                implicitWidth: statusChip.implicitWidth + 20
                                implicitHeight: 34
                                radius: 17
                                color: Theme.statusBgColor(work.status || defaultStatus)
                                border.color: Theme.statusColor(work.status || defaultStatus)
                                border.width: 1

                                Label {
                                    id: statusChip
                                    anchors.centerIn: parent
                                    text: work.status || defaultStatus
                                    font: Theme.bodyFont
                                    color: Theme.statusColor(work.status || defaultStatus)
                                }
                            }

                            Rectangle {
                                visible: (work.bgmId || 0) > 0
                                implicitWidth: bgmChip.implicitWidth + 20
                                implicitHeight: 34
                                radius: 17
                                color: Theme.accentMuted
                                border.color: Theme.accent
                                border.width: 1

                                Label {
                                    id: bgmChip
                                    anchors.centerIn: parent
                                    text: qsTr("BGM #%1").arg(work.bgmId)
                                    font: Theme.captionFont
                                    color: Theme.accentHover
                                }
                            }
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 8
                            Repeater {
                                model: work.tags || []
                                TagChip { tagName: modelData }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: descColumn.implicitHeight + 24
                            radius: Theme.radius
                            color: Theme.surface
                            border.color: Theme.borderLight
                            border.width: 1

                            ColumnLayout {
                                id: descColumn
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 8

                                Label {
                                    text: qsTr("简介")
                                    font: Theme.headingFont
                                    color: Theme.textPrimary
                                }

                                Label {
                                    text: work.description || qsTr("暂无简介")
                                    font: Theme.bodyFont
                                    color: Theme.textSecondary
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
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
                        onClicked: root.addReview(workId)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.spacing
                    Layout.rightMargin: Theme.spacing
                    spacing: 8

                    Repeater {
                        model: revModel

                        delegate: ReviewItem {
                            Layout.fillWidth: true
                            width: contentLayout.width - Theme.spacing * 2
                            date: model.date
                            title: model.title
                            content: model.content
                            onClicked: root.editReview(model.reviewId)
                            onDeleteRequested: {
                                ctrl.deleteReview(model.reviewId)
                                revModel.refresh()
                            }
                        }
                    }

                    Label {
                        visible: revModel.rowCount() === 0
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
            text: qsTr("确定要删除「%1」吗？所有感想也会一并删除。").arg(work.title)
            wrapMode: Text.WordWrap
        }

        onAccepted: {
            if (isGame ? gameController.deleteGame(workId) : animeController.deleteAnime(workId)) {
                root.deleted()
            }
        }
    }
}
