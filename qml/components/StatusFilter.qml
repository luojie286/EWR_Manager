import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0

RowLayout {
    id: root
    property string section: "anime"
    property string currentFilter: "全部"

    signal filterChanged(string filter)

    spacing: 8

    Repeater {
        model: section === "game" ? gameController.statusOptions() : animeController.statusOptions()
        delegate: TagChip {
            tagName: modelData
            selected: root.currentFilter === modelData
            onClicked: {
                root.currentFilter = modelData
                root.filterChanged(modelData)
            }
        }
    }
}
