pragma Singleton
import QtQuick

QtObject {
    readonly property color background: "#0f1117"
    readonly property color surface: "#1a1d27"
    readonly property color surfaceHover: "#242836"
    readonly property color border: "#2e3344"
    readonly property color accent: "#7c6cff"
    readonly property color accentSoft: "#3d3566"
    readonly property color textPrimary: "#f0f2f8"
    readonly property color textSecondary: "#9aa3b8"
    readonly property color success: "#4ade80"
    readonly property color warning: "#fbbf24"
    readonly property color danger: "#f87171"

    readonly property int radius: 12
    readonly property int spacing: 16
    readonly property int cardWidth: 180
    readonly property int cardHeight: 280

    readonly property font titleFont: Qt.font({ pixelSize: 24, weight: Font.DemiBold })
    readonly property font headingFont: Qt.font({ pixelSize: 18, weight: Font.DemiBold })
    readonly property font bodyFont: Qt.font({ pixelSize: 14 })
    readonly property font captionFont: Qt.font({ pixelSize: 12 })
}
