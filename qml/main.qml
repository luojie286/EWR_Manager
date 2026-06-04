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

    property string currentSection: "anime"

    background: ParticleBackground {
        anchors.fill: parent
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
                text: qsTr("动漫")
                iconSource: "film"
                active: currentSection === "anime" && stackView.depth <= 1
                onClicked: switchSection("anime")
            }

            NavButton {
                text: qsTr("游戏")
                iconSource: "sparkles"
                active: currentSection === "game" && stackView.depth <= 1
                onClicked: switchSection("game")
            }

            NavButton {
                text: qsTr("统计")
                iconSource: "chart-column"
                active: stackView.currentItem && stackView.currentItem.objectName === "StatisticsPage"
                onClicked: openStatistics()
            }

            MusicPlayerBar {
                Layout.minimumWidth: 300
                Layout.preferredWidth: 320
            }

            Button {
                id: addButton
                text: currentSection === "game" ? qsTr("添加游戏") : qsTr("添加作品")
                highlighted: true
                font: Theme.bodyFont
                onClicked: stackView.push(editPageComponent, {
                    section: currentSection,
                    workId: 0
                })

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

    function switchSection(section) {
        if (currentSection === section && stackView.depth <= 1)
            return
        currentSection = section
        while (stackView.depth > 1)
            stackView.pop()
        stackView.replace(homePageComponent, { section: section })
    }

    function openStatistics() {
        while (stackView.depth > 1)
            stackView.pop()
        var page = stackView.push(statisticsPageComponent)
        if (page && page.refreshStats)
            page.refreshStats()
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

    function refreshStatisticsIfVisible() {
        if (stackView.currentItem && stackView.currentItem.objectName === "StatisticsPage"
                && stackView.currentItem.refreshStats) {
            stackView.currentItem.refreshStats()
        }
    }

    Component {
        id: homePageComponent
        HomePage {
            section: root.currentSection
            onWorksDeleted: refreshStatisticsIfVisible()
            onOpenWork: function(workId) {
                stackView.push(detailPageComponent, {
                    section: currentSection,
                    workId: workId
                })
            }
            onOpenEdit: function(workId) {
                stackView.push(editPageComponent, {
                    section: currentSection,
                    workId: workId
                })
            }
        }
    }

    Component {
        id: detailPageComponent
        DetailPage {
            onBack: stackView.pop()
            onEditWork: function(id) {
                stackView.push(editPageComponent, {
                    section: currentSection,
                    workId: id
                })
            }
            onAddReview: function(id) {
                stackView.push(reviewPageComponent, {
                    section: currentSection,
                    workId: id,
                    reviewId: 0
                })
            }
            onEditReview: function(reviewId) {
                stackView.push(reviewPageComponent, {
                    section: currentSection,
                    workId: workId,
                    reviewId: reviewId
                })
            }
            onDeleted: {
                if (currentSection === "game")
                    gameModel.refresh()
                else
                    animeModel.refresh()
                stackView.pop()
                refreshStatisticsIfVisible()
            }
        }
    }

    Component {
        id: editPageComponent
        EditPage {
            onBack: stackView.pop()
            onSaved: {
                if (currentSection === "game")
                    gameModel.refresh()
                else
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
                if (currentSection === "game")
                    gameReviewModel.refresh()
                else
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
