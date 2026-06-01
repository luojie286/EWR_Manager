import QtQuick
import AppTheme 1.0

Image {
    id: root

    property string iconSource: "house"
    property int size: Theme.iconSize
    property real iconOpacity: 1.0

    width: size
    height: size
    source: "qrc:/icons/" + iconSource + ".svg"
    sourceSize: Qt.size(size * 2, size * 2)
    fillMode: Image.PreserveAspectFit
    smooth: true
    opacity: iconOpacity
}
