import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0
import "../components"

Item {
    id: root
    objectName: "StatisticsPage"

    signal back()

    property string statsSection: "anime"
    property var stats: statsSection === "game" ? gameController.statistics() : animeController.statistics()

    Component.onCompleted: refreshStats()
    StackView.onActivated: refreshStats()

    function refreshStats() {
        stats = statsSection === "game" ? gameController.statistics() : animeController.statistics()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacing

        PageBackBar {
            Layout.fillWidth: true
            backLabel: qsTr("← 返回首页")
            title: qsTr("数据统计")
            onBackClicked: root.back()

            Button {
                text: qsTr("刷新")
                flat: true
                onClicked: refreshStats()
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: root.width
                spacing: Theme.spacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { id: "anime", label: qsTr("动漫") },
                            { id: "game", label: qsTr("游戏") }
                        ]

                        delegate: NavButton {
                            text: modelData.label
                            active: statsSection === modelData.id
                            onClicked: {
                                statsSection = modelData.id
                                refreshStats()
                            }
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    rowSpacing: Theme.spacing
                    columnSpacing: Theme.spacing

                    Repeater {
                        model: [
                            { label: qsTr("总作品数"), value: stats.totalCount, color: Theme.accent, icon: "book-open" },
                            { label: statsSection === "game" ? qsTr("已玩完") : qsTr("已看完"), value: stats.finishedCount, color: Theme.success, icon: "star" },
                            { label: statsSection === "game" ? qsTr("在玩") : qsTr("在看"), value: stats.watchingCount, color: Theme.warning, icon: statsSection === "game" ? "sparkles" : "film" },
                            { label: statsSection === "game" ? qsTr("未玩") : qsTr("未看"), value: stats.plannedCount, color: Theme.textSecondary, icon: "inbox" },
                            { label: qsTr("弃坑"), value: stats.droppedCount, color: Theme.danger, icon: "trash-2" },
                            { label: qsTr("平均评分"), value: stats.averageScore, color: Theme.warning, icon: "chart-column" }
                        ]

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 118
                            radius: Theme.radiusLarge
                            color: Theme.surface
                            border.color: Theme.borderLight
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 14

                                Rectangle {
                                    Layout.preferredWidth: 48
                                    Layout.preferredHeight: 48
                                    radius: 14
                                    color: Theme.backgroundAlt
                                    border.color: Theme.border
                                    border.width: 1

                                    Icon {
                                        anchors.centerIn: parent
                                        iconSource: modelData.icon
                                        size: 22
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Label {
                                        text: modelData.label
                                        font: Theme.captionFont
                                        color: Theme.textSecondary
                                    }

                                    Label {
                                        text: modelData.value
                                        font: Theme.titleFont
                                        color: modelData.color
                                    }
                                }
                            }
                        }
                    }
                }

                Label {
                    text: qsTr("标签排行榜")
                    font: Theme.headingFont
                    color: Theme.textPrimary
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(160, tagColumn.implicitHeight + 32)
                    radius: Theme.radiusLarge
                    color: Theme.surface
                    border.color: Theme.borderLight
                    border.width: 1

                    Column {
                        id: tagColumn
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        Repeater {
                            model: stats.tagRanking || []

                            delegate: RowLayout {
                                width: parent.width
                                spacing: 12

                                Rectangle {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    radius: 14
                                    color: index < 3 ? Theme.accentMuted : Theme.backgroundAlt

                                    Label {
                                        anchors.centerIn: parent
                                        text: (index + 1).toString()
                                        color: index < 3 ? Theme.accentHover : Theme.textMuted
                                        font: Theme.labelFont
                                    }
                                }

                                Label {
                                    Layout.preferredWidth: 120
                                    text: modelData.name
                                    color: Theme.textPrimary
                                    font: Theme.bodyFont
                                    elide: Text.ElideRight
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 10

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width
                                        height: 10
                                        radius: 5
                                        color: Theme.backgroundAlt
                                    }

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: {
                                            var maxCount = stats.tagRanking.length > 0
                                                ? stats.tagRanking[0].count : 1
                                            return parent.width * (modelData.count / maxCount)
                                        }
                                        height: 10
                                        radius: 5
                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0.0; color: Theme.accent }
                                            GradientStop { position: 1.0; color: Theme.accentHover }
                                        }
                                    }
                                }

                                Label {
                                    text: modelData.count
                                    color: Theme.textSecondary
                                    font: Theme.captionFont
                                }
                            }
                        }

                        EmptyState {
                            width: parent.width
                            visible: !stats.tagRanking || stats.tagRanking.length === 0
                            iconSource: "tag"
                            title: qsTr("暂无标签数据")
                            subtitle: qsTr("给作品添加标签后，这里会显示使用频率排行")
                        }
                    }
                }

                Item { Layout.preferredHeight: Theme.spacing }
            }
        }
    }
}
