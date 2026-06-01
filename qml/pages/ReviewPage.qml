import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0

ScrollView {
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

    clip: true

    Component.onCompleted: {
        if (!isNew) {
            review = animeController.getReview(reviewId)
        }
    }

    ColumnLayout {
        width: root.availableWidth
        spacing: Theme.spacing

        RowLayout {
            Layout.fillWidth: true

            Button {
                text: qsTr("← 返回")
                flat: true
                onClicked: root.back()
            }

            Label {
                Layout.fillWidth: true
                text: isNew ? qsTr("写感想") : qsTr("编辑感想")
                font: Theme.titleFont
                color: Theme.textPrimary
            }

            Button {
                text: qsTr("保存")
                highlighted: true
                enabled: contentField.text.trim().length > 0
                onClicked: saveReview()
            }
        }

        Label {
            text: qsTr("作品：%1").arg(animeController.getAnime(animeId).title || "")
            font: Theme.bodyFont
            color: Theme.textSecondary
        }

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

        Item {
            visible: !isNew
            Layout.fillWidth: true

            Button {
                anchors.right: parent.right
                text: qsTr("删除感想")
                onClicked: deleteDialog.open()
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
