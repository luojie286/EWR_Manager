import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0
import "components"
import "pages"

ApplicationWindow {
    id: root
    width: 1200
    height: 800
    visible: true
    title: qsTr("EWR_Manager")
    color: Theme.background

    property var currentAnime: ({})
    property var currentReview: ({})

    header: Rectangle {
        height: 64
        color: Theme.surface

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacing
            anchors.rightMargin: Theme.spacing
            spacing: Theme.spacing

            Label {
                text: qsTr("EWR_Manager")
                font: Theme.titleFont
                color: Theme.textPrimary
            }

            Item { Layout.fillWidth: true }

            NavButton {
                text: qsTr("首页")
                active: stackView.depth <= 1
                onClicked: {
                    while (stackView.depth > 1)
                        stackView.pop()
                }
            }

            NavButton {
                text: qsTr("统计")
                active: stackView.currentItem && stackView.currentItem.objectName === "StatisticsPage"
                onClicked: stackView.push(statisticsPageComponent)
            }

            Button {
                text: qsTr("+ 添加作品")
                highlighted: true
                onClicked: stackView.push(editPageComponent, { animeId: 0 })
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Theme.border
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        anchors.margins: Theme.spacing
        initialItem: homePageComponent

        pushEnter: Transition {
            PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 180 }
            PropertyAnimation { property: "x"; from: 40; to: 0; duration: 180; easing.type: Easing.OutCubic }
        }
        popExit: Transition {
            PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: 150 }
            PropertyAnimation { property: "x"; from: 0; to: 40; duration: 150; easing.type: Easing.InCubic }
        }
    }

    Component {
        id: homePageComponent
        HomePage {
            onOpenAnime: function(animeId) {
                currentAnime = animeController.getAnime(animeId)
                reviewModel.animeId = animeId
                stackView.push(detailPageComponent, { animeId: animeId })
            }
            onOpenEdit: function(animeId) {
                stackView.push(editPageComponent, { animeId: animeId })
            }
        }
    }

    Component {
        id: detailPageComponent
        DetailPage {
            onBack: stackView.pop()
            onEditAnime: function(id) {
                stackView.push(editPageComponent, { animeId: id })
            }
            onAddReview: function(id) {
                stackView.push(reviewPageComponent, { animeId: id, reviewId: 0 })
            }
            onEditReview: function(reviewId) {
                stackView.push(reviewPageComponent, {
                    animeId: animeId,
                    reviewId: reviewId
                })
            }
            onDeleted: {
                animeModel.refresh()
                stackView.pop()
            }
        }
    }

    Component {
        id: editPageComponent
        EditPage {
            onBack: stackView.pop()
            onSaved: {
                animeModel.refresh()
                stackView.pop()
            }
        }
    }

    Component {
        id: reviewPageComponent
        ReviewPage {
            onBack: stackView.pop()
            onSaved: {
                reviewModel.refresh()
                stackView.pop()
            }
        }
    }

    Component {
        id: statisticsPageComponent
        StatisticsPage {
            objectName: "StatisticsPage"
            onBack: stackView.pop()
        }
    }
}
