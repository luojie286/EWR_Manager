import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import AppTheme 1.0
import "../components"

Item {
    id: root
    objectName: "EditPage"

    property string section: "anime"
    property int workId: 0
    property bool isNew: workId === 0
    property int bgmId: 0

    readonly property var ctrl: section === "game" ? gameController : animeController
    readonly property bool isGame: section === "game"
    readonly property string defaultStatus: isGame ? "未玩" : "未看"
    readonly property bool importBusy: isGame
        ? (rawgClient.busy || gameBangumiClient.busy)
        : bangumiClient.busy

    signal back()
    signal saved()

    property var work: isNew ? {
        title: "",
        score: 0,
        status: defaultStatus,
        description: "",
        coverPath: "",
        bgmId: 0,
        tags: []
    } : (isGame ? gameController.getGame(workId) : animeController.getAnime(workId))

    property string tagsText: (work.tags || []).join(", ")

    Component.onCompleted: {
        if (!isNew) {
            work = isGame ? gameController.getGame(workId) : animeController.getAnime(workId)
            tagsText = (work.tags || []).join(", ")
            bgmId = work.bgmId || 0
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PageBackBar {
            Layout.fillWidth: true
            title: isNew
                ? (isGame ? qsTr("添加游戏") : qsTr("添加作品"))
                : (isGame ? qsTr("编辑游戏") : qsTr("编辑作品"))
            onBackClicked: root.back()

            Button {
                text: qsTr("保存")
                highlighted: true
                enabled: titleField.text.trim().length > 0 && !importBusy
                onClicked: saveWork()
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

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.spacing
                    Layout.rightMargin: Theme.spacing
                    spacing: 8
                    visible: isGame

                    Button {
                        text: qsTr("从 RAWG 搜索")
                        Layout.fillWidth: true
                        enabled: !importBusy
                        onClicked: {
                            rawgSearchDialog.initialKeyword = titleField.text
                            rawgSearchDialog.open()
                        }
                    }

                    Button {
                        text: qsTr("从 Bangumi 搜索")
                        Layout.fillWidth: true
                        enabled: !importBusy
                        flat: true
                        onClicked: {
                            bangumiSearchDialog.section = "game"
                            bangumiSearchDialog.initialKeyword = titleField.text
                            bangumiSearchDialog.open()
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.spacing
                    Layout.rightMargin: Theme.spacing
                    spacing: 8
                    visible: !isGame

                    Button {
                        text: qsTr("从 Bangumi 搜索")
                        Layout.fillWidth: true
                        enabled: !importBusy
                        onClicked: {
                            bangumiSearchDialog.section = "anime"
                            bangumiSearchDialog.initialKeyword = titleField.text
                            bangumiSearchDialog.open()
                        }
                    }

                    Label {
                        visible: bgmId > 0
                        text: qsTr("BGM #%1").arg(bgmId)
                        font: Theme.captionFont
                        color: Theme.accent
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.spacing
                    Layout.rightMargin: Theme.spacing
                    visible: isGame && bgmId > 0

                    Label {
                        text: qsTr("关联 ID #%1").arg(bgmId)
                        font: Theme.captionFont
                        color: Theme.accent
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.spacing
                    Layout.rightMargin: Theme.spacing
                    spacing: Theme.spacing

                    Rectangle {
                        Layout.preferredWidth: 160
                        Layout.preferredHeight: 240
                        radius: Theme.radius
                        color: "#0a0c10"
                        clip: true

                        CoverImage {
                            id: coverPreviewDisplay
                            anchors.fill: parent
                            source: coverPathField.text ? "file:///" + coverPathField.text.replace(/\\/g, "/") : ""
                        }

                        Label {
                            anchors.centerIn: parent
                            visible: !coverPathField.text || !coverPreviewDisplay.ready
                            text: qsTr("封面")
                            color: Theme.textSecondary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Label { text: qsTr("标题 *"); color: Theme.textSecondary; font: Theme.captionFont }
                        TextField {
                            id: titleField
                            Layout.fillWidth: true
                            text: work.title || ""
                            placeholderText: isGame ? qsTr("例如：塞尔达传说") : qsTr("例如：葬送的芙莉莲")
                            color: Theme.textPrimary
                            background: Rectangle { radius: 8; color: Theme.surface; border.color: Theme.border }
                        }

                        Label { text: qsTr("评分 (0-10)"); color: Theme.textSecondary; font: Theme.captionFont }
                        SpinBox {
                            id: scoreSpin
                            Layout.fillWidth: true
                            from: 0
                            to: 100
                            stepSize: 5
                            value: Math.round((work.score || 0) * 10)
                            editable: true
                            textFromValue: function(v) { return (v / 10).toFixed(1) }
                            valueFromText: function(t) { return Math.round(parseFloat(t) * 10) }
                        }

                        Label {
                            text: isGame ? qsTr("游玩状态") : qsTr("观看状态")
                            color: Theme.textSecondary
                            font: Theme.captionFont
                        }
                        ComboBox {
                            id: statusCombo
                            Layout.fillWidth: true
                            model: isGame ? ["未玩", "在玩", "玩完", "弃坑"] : ["未看", "在看", "看完", "弃坑"]
                            currentIndex: Math.max(0, model.indexOf(work.status || defaultStatus))
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.spacing
                    Layout.rightMargin: Theme.spacing
                    spacing: Theme.spacing

                    Label { text: qsTr("封面路径"); color: Theme.textSecondary; font: Theme.captionFont }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        TextField {
                            id: coverPathField
                            Layout.fillWidth: true
                            text: work.coverPath || ""
                            placeholderText: isGame
                                ? qsTr("选择本地图片，或从 RAWG / Bangumi 自动下载")
                                : qsTr("选择本地图片，或从 Bangumi 自动下载")
                            color: Theme.textPrimary
                            background: Rectangle { radius: 8; color: Theme.surface; border.color: Theme.border }
                        }

                        Button {
                            text: qsTr("浏览…")
                            onClicked: fileDialog.open()
                        }
                    }

                    Label { text: qsTr("标签（逗号分隔）"); color: Theme.textSecondary; font: Theme.captionFont }
                    TextField {
                        id: tagsField
                        Layout.fillWidth: true
                        text: tagsText
                        placeholderText: isGame ? qsTr("RPG, 开放世界, 神作") : qsTr("治愈, 奇幻, 公路片")
                        color: Theme.textPrimary
                        background: Rectangle { radius: 8; color: Theme.surface; border.color: Theme.border }
                    }

                    Label { text: qsTr("简介"); color: Theme.textSecondary; font: Theme.captionFont }
                    TextArea {
                        id: descField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 160
                        text: work.description || ""
                        wrapMode: TextArea.Wrap
                        color: Theme.textPrimary
                        placeholderText: qsTr("写一段简介…")
                        background: Rectangle { radius: 8; color: Theme.surface; border.color: Theme.border }
                    }
                }

                Item { Layout.preferredHeight: Theme.spacing }
            }
        }
    }

    BangumiSearchDialog {
        id: bangumiSearchDialog
        onSubjectSelected: function(subjectId) {
            if (bangumiSearchDialog.section === "game")
                gameBangumiClient.importSubject(subjectId)
            else
                bangumiClient.importSubject(subjectId)
        }
    }

    RawgSearchDialog {
        id: rawgSearchDialog
        onGameSelected: function(gameId) {
            rawgClient.importGame(gameId)
        }
    }

    FileDialog {
        id: fileDialog
        title: qsTr("选择封面图片")
        nameFilters: [qsTr("图片 (*.png *.jpg *.jpeg *.webp *.bmp)")]
        onAccepted: {
            coverPathField.text = selectedFile.toLocalFile()
        }
    }

    Dialog {
        id: errorDialog
        title: qsTr("导入错误")
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Ok
        property alias text: errorText.text
        Label { id: errorText; wrapMode: Text.WordWrap }
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: importBusy
    }

    Connections {
        target: bangumiClient
        function onImportFinished(data) {
            applyImportData(data)
        }
        function onErrorOccurred(message) {
            errorDialog.text = message
            errorDialog.open()
        }
    }

    Connections {
        target: gameBangumiClient
        function onImportFinished(data) {
            applyImportData(data)
        }
        function onErrorOccurred(message) {
            errorDialog.text = message
            errorDialog.open()
        }
    }

    Connections {
        target: rawgClient
        function onImportFinished(data) {
            applyImportData(data)
        }
        function onErrorOccurred(message) {
            errorDialog.text = message
            errorDialog.open()
        }
    }

    function applyImportData(data) {
        titleField.text = data.title || ""
        descField.text = data.description || ""
        tagsField.text = (data.tags || []).join(", ")
        coverPathField.text = data.coverPath || ""
        if (data.score > 0)
            scoreSpin.value = Math.round(data.score * 10)
        bgmId = data.bgmId || 0
    }

    function saveWork() {
        var data = {
            title: titleField.text.trim(),
            score: scoreSpin.value / 10,
            status: statusCombo.currentText,
            description: descField.text,
            coverPath: coverPathField.text.trim(),
            bgmId: bgmId,
            tags: tagsField.text
        }

        var ok
        if (isGame) {
            data.gameId = workId
            ok = isNew ? (gameController.addGame(data) > 0) : gameController.updateGame(data)
        } else {
            data.animeId = workId
            ok = isNew ? (animeController.addAnime(data) > 0) : animeController.updateAnime(data)
        }

        if (ok) {
            root.saved()
        }
    }
}
