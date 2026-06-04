import QtQuick
import AppTheme 1.0

Item {
    id: root

    property url source: ""
    property int fillMode: Image.PreserveAspectFit
    property int horizontalAlignment: Image.AlignHCenter
    property int verticalAlignment: Image.AlignVCenter

    readonly property bool isLandscapeCover:
        coverImage.status === Image.Ready
        && coverImage.sourceSize.width > 0
        && coverImage.sourceSize.height > 0
        && coverImage.sourceSize.width > coverImage.sourceSize.height

    readonly property bool ready: coverImage.status === Image.Ready

    Image {
        id: backdropImage
        anchors.fill: parent
        source: root.source
        visible: root.source.toString().length > 0 && isLandscapeCover
        fillMode: Image.PreserveAspectCrop
        horizontalAlignment: Image.AlignHCenter
        verticalAlignment: Image.AlignVCenter
        opacity: 0.45
        smooth: true
        mipmap: true
    }

    Rectangle {
        anchors.fill: parent
        visible: backdropImage.visible
        color: "#66000000"
    }

    Image {
        id: coverImage
        anchors.fill: parent
        source: root.source
        visible: status === Image.Ready
        smooth: true
        mipmap: true
        fillMode: isLandscapeCover ? Image.PreserveAspectCrop : Image.PreserveAspectFit
        horizontalAlignment: isLandscapeCover ? Image.AlignHCenter : root.horizontalAlignment
        verticalAlignment: isLandscapeCover ? Image.AlignVCenter : root.verticalAlignment
    }
}
