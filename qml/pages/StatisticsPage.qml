import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0
import "../components"

Item {
    id: root
    objectName: "StatisticsPage"

    signal back()

    property var stats: animeController.statistics()

    Component.onCompleted: refreshStats()
    StackView.onActivated: refreshStats()

    function refreshStats() {
        stats = animeController.statistics()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

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

                Item { Layout.preferredHeight: 4 }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.spacing
                    Layout.rightMargin: Theme.spacing
                    columns: 3
                    rowSpacing: Theme.spacing
                    columnSpacing: Theme.spacing

                    Repeater {
                        model: [
                            { label: qsTr("总作品数"), value: stats.totalCount, color: Theme.accent },
                            { label: qsTr("已看完"), value: stats.finishedCount, color: Theme.success },
                            { label: qsTr("在看"), value: stats.watchingCount, color: Theme.warning },
                            { label: qsTr("未看"), value: stats.plannedCount, color: Theme.textSecondary },
                            { label: qsTr("弃坑"), value: stats.droppedCount, color: Theme.danger },
                            { label: qsTr("平均评分"), value: stats.averageScore, color: Theme.warning }
                        ]

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 100
                            radius: Theme.radius
                            color: Theme.surface
                            border.color: Theme.border

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 8

                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.label
                                    font: Theme.captionFont
                                    color: Theme.textSecondary
                                }

                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.value
                                    font: Theme.titleFont
                                    color: modelData.color
                                }
                            }
                        }
                    }
                }

                Label {
                    Layout.leftMargin: Theme.spacing
                    text: qsTr("标签排行榜")
                    font: Theme.headingFont
                    color: Theme.textPrimary
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.spacing
                    Layout.rightMargin: Theme.spacing
                    Layout.preferredHeight: Math.max(120, tagColumn.implicitHeight + 24)
                    radius: Theme.radius
                    color: Theme.surface
                    border.color: Theme.border

                    Column {
                        id: tagColumn
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Repeater {
                            model: stats.tagRanking || []

                            delegate: RowLayout {
                                width: parent.width
                                spacing: 12

                                Label {
                                    Layout.preferredWidth: 24
                                    text: (index + 1).toString()
                                    color: Theme.textSecondary
                                    font: Theme.captionFont
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
                                    Layout.preferredHeight: 8

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width
                                        height: 8
                                        radius: 4
                                        color: Theme.surfaceHover
                                    }

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: {
                                            var maxCount = stats.tagRanking.length > 0
                                                ? stats.tagRanking[0].count : 1
                                            return parent.width * (modelData.count / maxCount)
                                        }
                                        height: 8
                                        radius: 4
                                        color: Theme.accent
                                    }
                                }

                                Label {
                                    text: modelData.count
                                    color: Theme.textSecondary
                                    font: Theme.captionFont
                                }
                            }
                        }

                        Label {
                            visible: !stats.tagRanking || stats.tagRanking.length === 0
                            text: qsTr("暂无标签数据")
                            color: Theme.textSecondary
                            font: Theme.bodyFont
                        }
                    }
                }

                Item { Layout.preferredHeight: Theme.spacing }
            }
        }
    }
}
