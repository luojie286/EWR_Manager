import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0
import "../components"

Item {
    id: root
    objectName: "ReviewPage"

    property int animeId: 0
    property int reviewId: 0
    property bool isNew: reviewId === 0
    property var review: isNew ? {
        animeId: animeId,
        date: Qt.formatDate(new Date(), "yyyy-MM-dd"),
        title: "",
        content: ""
    } : animeController.getReview(reviewId)

    signal back()
    signal saved()

    Component.onCompleted: {
        if (!isNew) {
            review = animeController.getReview(reviewId)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PageBackBar {
            Layout.fillWidth: true
            title: isNew ? qsTr("写感想") : qsTr("编辑感想")
            onBackClicked: root.back()

            Button {
                text: qsTr("保存")
                highlighted: true
                enabled: contentField.text.trim().length > 0
                onClicked: saveReview()
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

                Label {
                    Layout.leftMargin: Theme.spacing
                    Layout.rightMargin: Theme.spacing
                    text: qsTr("作品：%1").arg(animeController.getAnime(animeId).title || "")
                    font: Theme.bodyFont
                    color: Theme.textSecondary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.spacing
                    Layout.rightMargin: Theme.spacing
                    spacing: Theme.spacing

                    Label { text: qsTr("日期"); color: Theme.textSecondary; font: Theme.captionFont }
                    TextField {
                        id: dateField
                        Layout.fillWidth: true
                        text: review.date || Qt.formatDate(new Date(), "yyyy-MM-dd")
                        placeholderText: "yyyy-MM-dd"
                        color: Theme.textPrimary
                        background: Rectangle { radius: 8; color: Theme.surface; border.color: Theme.border }
                    }

                    Label { text: qsTr("标题"); color: Theme.textSecondary; font: Theme.captionFont }
                    TextField {
                        id: titleField
                        Layout.fillWidth: true
                        text: review.title || ""
                        placeholderText: qsTr("例如：二刷、神作")
                        color: Theme.textPrimary
                        background: Rectangle { radius: 8; color: Theme.surface; border.color: Theme.border }
                    }

                    Label { text: qsTr("内容 *"); color: Theme.textSecondary; font: Theme.captionFont }
                    TextArea {
                        id: contentField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 240
                        text: review.content || ""
                        wrapMode: TextArea.Wrap
                        placeholderText: qsTr("写下你的观感…")
                        color: Theme.textPrimary
                        background: Rectangle { radius: 8; color: Theme.surface; border.color: Theme.border }
                    }

                    Button {
                        visible: !isNew
                        Layout.alignment: Qt.AlignRight
                        text: qsTr("删除感想")
                        onClicked: deleteDialog.open()
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

        Label { text: qsTr("确定要删除这条感想吗？") }

        onAccepted: {
            if (animeController.deleteReview(reviewId)) {
                root.saved()
            }
        }
    }

    function saveReview() {
        var data = {
            reviewId: reviewId,
            animeId: animeId,
            date: dateField.text.trim(),
            title: titleField.text.trim(),
            content: contentField.text.trim()
        }

        var ok = isNew ? (animeController.addReview(data) > 0)
                       : animeController.updateReview(data)
        if (ok) {
            root.saved()
        }
    }
}
