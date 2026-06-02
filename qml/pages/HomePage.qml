import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0
import "../components"

Item {
    id: root
    objectName: "HomePage"

    property string section: "anime"
    readonly property var ctrl: section === "game" ? gameController : animeController
    readonly property var listModel: section === "game" ? gameModel : animeModel
    readonly property bool isGame: section === "game"

    StackView.onActivated: {
        tagCombo.model = [qsTr("全部标签")].concat(ctrl.allTags())
    }

    signal openWork(int workId)
    signal openEdit(int workId)

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacing

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: searchRow.implicitHeight + 24
            radius: Theme.radiusLarge
            color: Theme.surface
            border.color: Theme.borderLight
            border.width: 1

            RowLayout {
                id: searchRow
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: Theme.radius
                    color: Theme.backgroundAlt
                    border.color: searchField.activeFocus ? Theme.accent : Theme.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 10
                        spacing: 10

                        Icon {
                            iconSource: "search"
                            size: Theme.iconSize
                            iconOpacity: searchField.activeFocus ? 0.95 : 0.55
                        }

                        TextField {
                            id: searchField
                            Layout.fillWidth: true
                            placeholderText: isGame
                                ? qsTr("搜索游戏名、简介或标签…")
                                : qsTr("搜索作品名、简介或标签…")
                            font: Theme.bodyFont
                            color: Theme.textPrimary
                            placeholderTextColor: Theme.textMuted
                            background: Item {}
                            onTextChanged: listModel.searchText = text
                        }
                    }
                }

                ComboBox {
                    id: tagCombo
                    Layout.preferredWidth: 160
                    Layout.preferredHeight: 44
                    model: [qsTr("全部标签")].concat(ctrl.allTags())
                    font: Theme.bodyFont
                    onActivated: function(index) {
                        listModel.tagFilter = index === 0 ? "" : tagCombo.textAt(index)
                    }

                    background: Rectangle {
                        radius: Theme.radius
                        color: Theme.backgroundAlt
                        border.color: tagCombo.activeFocus ? Theme.accent : Theme.border
                        border.width: 1
                    }
                }
            }
        }

        StatusFilter {
            id: statusFilter
            section: root.section
            currentFilter: listModel.statusFilter || "全部"
            onFilterChanged: function(filter) {
                listModel.statusFilter = filter === "全部" ? "" : filter
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: isGame
                    ? qsTr("共 %1 部游戏").arg(listModel.rowCount())
                    : qsTr("共 %1 部作品").arg(listModel.rowCount())
                font: Theme.captionFont
                color: Theme.textSecondary
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                visible: searchField.text.length > 0 || (listModel.statusFilter && listModel.statusFilter.length > 0) || (listModel.tagFilter && listModel.tagFilter.length > 0)
                radius: Theme.radiusSmall
                color: Theme.accentMuted
                implicitWidth: filterLabel.implicitWidth + 16
                implicitHeight: 26

                Label {
                    id: filterLabel
                    anchors.centerIn: parent
                    text: qsTr("已筛选")
                    font: Theme.labelFont
                    color: Theme.accent
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridView {
                id: gridView
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                visible: listModel.rowCount() > 0

                cellWidth: Theme.cardWidth + Theme.spacing
                cellHeight: Theme.cardHeight + Theme.spacing + Theme.gridCellPadding
                topMargin: 8
                leftMargin: 4
                rightMargin: 4
                bottomMargin: Theme.spacing

                model: listModel

                delegate: Item {
                    width: gridView.cellWidth
                    height: gridView.cellHeight

                    property int workId: isGame ? model.gameId : model.animeId

                    AnimeCard {
                        width: Theme.cardWidth
                        height: Theme.cardHeight
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter

                        animeId: workId
                        title: model.title
                        score: model.score
                        status: model.status
                        coverPath: model.coverPath
                        tags: model.tags

                        onClicked: root.openWork(workId)
                        onEditRequested: root.openEdit(workId)
                    }
                }
            }

            EmptyState {
                anchors.centerIn: parent
                visible: listModel.rowCount() === 0
                iconSource: searchField.text.length > 0 ? "search" : "inbox"
                title: searchField.text.length > 0
                    ? qsTr("没有找到匹配的内容")
                    : (isGame ? qsTr("还没有游戏") : qsTr("还没有作品"))
                subtitle: searchField.text.length > 0
                    ? qsTr("试试换个关键词，或清除筛选条件")
                    : (isGame
                        ? qsTr("点击右上角「添加游戏」开始建立你的游戏库")
                        : qsTr("点击右上角「添加作品」开始建立你的收藏"))
            }
        }
    }

    Connections {
        target: listModel
        function onSearchTextChanged() {
            tagCombo.model = [qsTr("全部标签")].concat(ctrl.allTags())
        }
    }
}
