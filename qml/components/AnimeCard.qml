import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0

Item {
    id: root

    property int animeId: 0
    property string title: ""
    property real score: 0
    property string status: ""
    property string coverPath: ""
    property var tags: []
    property bool selectionMode: false
    property bool selected: false

    signal clicked()
    signal editRequested()
    signal selectionToggled()

    width: Theme.cardWidth
    height: Theme.cardHeight

    TextMetrics {
        id: tagMetrics
        font: Theme.captionFont
    }

    readonly property int tagChipHeight: 24
    readonly property int tagSpacing: 4
    readonly property real tagFlowMaxHeight: Theme.cardInfoHeight - 56 - 20
    readonly property real tagFlowWidth: cardBody.width - 20

    readonly property var visibleTags: {
        var result = []
        var x = 0
        var y = 0
        var maxW = tagFlowWidth
        var maxH = tagFlowMaxHeight
        if (maxW <= 0 || maxH <= 0 || !tags || tags.length === 0)
            return result

        for (var i = 0; i < tags.length; i++) {
            tagMetrics.text = tags[i]
            var w = tagMetrics.width + 18
            if (w > maxW)
                continue

            if (x > 0 && x + tagSpacing + w > maxW) {
                y += tagChipHeight + tagSpacing
                x = 0
            }

            if (y + tagChipHeight > maxH)
                break

            result.push(tags[i])
            x += (x > 0 ? tagSpacing : 0) + w
        }
        return result
    }

    scale: cardMouse.containsMouse ? 1.02 : 1.0
    transformOrigin: Item.Top
    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: cardMouse.containsMouse ? 4 : 2
        radius: Theme.radiusLarge
        color: "#50000000"
        opacity: cardMouse.containsMouse ? 0.55 : 0.35
        z: -1
    }

    Rectangle {
        id: cardBody
        anchors.fill: parent
        radius: Theme.radiusLarge
        color: Theme.surface
        border.color: cardMouse.containsMouse ? Theme.accent : Theme.border
        border.width: cardMouse.containsMouse ? 1.5 : 1
        clip: true

        Behavior on border.color { ColorAnimation { duration: 140 } }

        Rectangle {
            id: coverArea
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Theme.cardCoverHeight
            color: "#0a0c10"
            clip: true

            CoverImage {
                id: coverDisplay
                anchors.fill: parent
                source: coverPath ? "file:///" + coverPath.replace(/\\/g, "/") : ""
            }

            Rectangle {
                anchors.fill: parent
                visible: !coverPath || !coverDisplay.ready
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Theme.accentMuted }
                    GradientStop { position: 1.0; color: Theme.surfaceHover }
                }

                Icon {
                    anchors.centerIn: parent
                    iconSource: "film"
                    size: 44
                    iconOpacity: 0.35
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 16
                    text: title.length > 0 ? title.charAt(0).toUpperCase() : "?"
                    font.pixelSize: 28
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                    opacity: 0.55
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 40
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: "#cc161922" }
                }
            }

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 10
                height: 26
                width: statusPill.implicitWidth + 16
                radius: 13
                color: Theme.statusBgColor(status)
                border.color: Theme.statusColor(status)
                border.width: 1
                opacity: 0.92
                visible: !selectionMode

                Label {
                    id: statusPill
                    anchors.centerIn: parent
                    text: status
                    font: Theme.labelFont
                    color: Theme.statusColor(status)
                }
            }

            Rectangle {
                visible: selectionMode
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 10
                width: 26
                height: 26
                radius: 8
                color: selected ? Theme.accent : "#66000000"
                border.color: selected ? Theme.accentHover : Theme.border
                border.width: 2

                Label {
                    anchors.centerIn: parent
                    visible: selected
                    text: "✓"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: "#ffffff"
                }
            }
        }

        ColumnLayout {
            anchors.top: coverArea.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 10
            spacing: 4

            Label {
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                text: title
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: Theme.textPrimary
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                spacing: 4

                Icon {
                    iconSource: "star"
                    size: Theme.iconSizeSmall
                    iconOpacity: score > 0 ? 1.0 : 0.35
                }

                Label {
                    text: score > 0 ? score.toFixed(1) : "—"
                    font: Theme.bodyFont
                    color: score > 0 ? Theme.warning : Theme.textMuted
                }

                Item { Layout.fillWidth: true }

                ActionButton {
                    visible: !selectionMode
                    actionType: "edit"
                    compact: true
                    ToolTip.text: qsTr("编辑")
                    ToolTip.visible: hovered
                    onClicked: root.editRequested()
                }
            }

            Flow {
                id: tagFlow
                Layout.fillWidth: true
                Layout.preferredHeight: visibleTags.length > 0 ? implicitHeight : 0
                spacing: root.tagSpacing

                Repeater {
                    model: root.visibleTags
                    TagChip {
                        compact: true
                        tagName: modelData
                    }
                }
            }
        }
    }

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: selectionMode ? root.selectionToggled() : root.clicked()
    }
}
