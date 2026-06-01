import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppTheme 1.0

RowLayout {
    id: root
    property string currentFilter: "全部"

    signal filterChanged(string filter)

    spacing: 8

    Repeater {
        model: animeController.statusOptions()
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
