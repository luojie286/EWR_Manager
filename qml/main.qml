import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0
import "components"
import "pages"

ApplicationWindow {
    id: root
    width: 1280
    height: 840
    minimumWidth: 960
    minimumHeight: 640
    visible: true
    title: qsTr("EWR_Manager")
    color: Theme.background

    property var currentAnime: ({})
    property var currentReview: ({})

    background: Item {
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.background }
                GradientStop { position: 0.45; color: Theme.backgroundAlt }
                GradientStop { position: 1.0; color: "#0d1018" }
            }
        }

        Rectangle {
            width: 520
            height: 520
            x: -180
            y: -120
            radius: width / 2
            color: Theme.accent
            opacity: 0.06
        }

        Rectangle {
            width: 420
            height: 420
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: -100
            anchors.bottomMargin: -80
            radius: width / 2
            color: "#5b8def"
            opacity: 0.05
        }
    }

    header: Rectangle {
        height: Theme.headerHeight
        color: Theme.surface
        border.color: Theme.borderLight
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacing + 4
            anchors.rightMargin: Theme.spacing
            spacing: Theme.spacing

            RowLayout {
                spacing: 12

                Rectangle {
                    width: 42
                    height: 42
                    radius: 12
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Theme.accentHover }
                        GradientStop { position: 1.0; color: Theme.accent }
                    }

                    Icon {
                        anchors.centerIn: parent
                        iconSource: "book-open"
                        size: 22
                        iconOpacity: 0.95
                    }
                }

                ColumnLayout {
                    spacing: 0

                    Label {
                        text: qsTr("EWR_Manager")
                        font: Theme.titleFont
                        color: Theme.textPrimary
                    }

                    Label {
                        text: qsTr("娱乐作品感想管理")
                        font: Theme.labelFont
                        color: Theme.textMuted
                    }
                }
            }

            Item { Layout.fillWidth: true }

            NavButton {
                text: qsTr("首页")
                iconSource: "house"
                active: stackView.depth <= 1
                onClicked: {
                    while (stackView.depth > 1)
                        stackView.pop()
                }
            }

            NavButton {
                text: qsTr("统计")
                iconSource: "chart-column"
                active: stackView.currentItem && stackView.currentItem.objectName === "StatisticsPage"
                onClicked: stackView.push(statisticsPageComponent)
            }

            Button {
                id: addButton
                text: qsTr("添加作品")
                highlighted: true
                font: Theme.bodyFont
                onClicked: stackView.push(editPageComponent, { animeId: 0 })

                contentItem: RowLayout {
                    spacing: 8

                    Icon {
                        iconSource: "plus"
                        size: Theme.iconSizeSmall
                        iconOpacity: 0.95
                    }

                    Text {
                        text: addButton.text
                        font: addButton.font
                        color: "#ffffff"
                    }
                }

                background: Rectangle {
                    radius: Theme.radius
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: addButton.down ? Theme.accent : Theme.accentHover }
                        GradientStop { position: 1.0; color: Theme.accent }
                    }
                    opacity: addButton.enabled ? 1.0 : 0.45
                }
            }
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        anchors.margins: Theme.spacing
        initialItem: homePageComponent

        pushEnter: Transition {
            PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
            PropertyAnimation { property: "x"; from: 32; to: 0; duration: 220; easing.type: Easing.OutCubic }
        }
        popExit: Transition {
            PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: 160; easing.type: Easing.InCubic }
            PropertyAnimation { property: "x"; from: 0; to: 24; duration: 160; easing.type: Easing.InCubic }
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
