import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0
import "../components"

Item {
    id: root
    objectName: "HomePage"

    StackView.onActivated: {
        tagCombo.model = [qsTr("全部标签")].concat(animeController.allTags())
    }

    signal openAnime(int animeId)
    signal openEdit(int animeId)

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing

            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: qsTr("搜索作品名、简介或标签…")
                font: Theme.bodyFont
                color: Theme.textPrimary
                placeholderTextColor: Theme.textSecondary
                onTextChanged: animeModel.searchText = text

                background: Rectangle {
                    radius: Theme.radius
                    color: Theme.surface
                    border.color: searchField.activeFocus ? Theme.accent : Theme.border
                }
            }

            ComboBox {
                id: tagCombo
                model: [qsTr("全部标签")].concat(animeController.allTags())
                font: Theme.bodyFont
                onActivated: function(index) {
                    animeModel.tagFilter = index === 0 ? "" : tagCombo.textAt(index)
                }

                background: Rectangle {
                    radius: Theme.radius
                    color: Theme.surface
                    border.color: Theme.border
                }
            }
        }

        StatusFilter {
            id: statusFilter
            currentFilter: animeModel.statusFilter || "全部"
            onFilterChanged: function(filter) {
                animeModel.statusFilter = filter === "全部" ? "" : filter
            }
        }

        Label {
            text: qsTr("共 %1 部作品").arg(animeModel.rowCount())
            font: Theme.captionFont
            color: Theme.textSecondary
        }

        GridView {
            id: gridView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            cellWidth: Theme.cardWidth + Theme.spacing
            cellHeight: Theme.cardHeight + Theme.spacing
            topMargin: 4
            leftMargin: 4
            rightMargin: 4
            bottomMargin: Theme.spacing

            model: animeModel

            delegate: Item {
                width: gridView.cellWidth
                height: gridView.cellHeight

                AnimeCard {
                    width: Theme.cardWidth
                    height: Theme.cardHeight
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter

                    animeId: model.animeId
                    title: model.title
                    score: model.score
                    status: model.status
                    coverPath: model.coverPath
                    tags: model.tags

                    onClicked: root.openAnime(model.animeId)
                    onEditRequested: root.openEdit(model.animeId)
                }
            }
        }
    }

    Connections {
        target: animeModel
        function onSearchTextChanged() {
            tagCombo.model = [qsTr("全部标签")].concat(animeController.allTags())
        }
    }
}
