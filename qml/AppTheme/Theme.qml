pragma Singleton
import QtQuick

QtObject {
    readonly property color background: "#0b0d12"
    readonly property color backgroundAlt: "#10131a"
    readonly property color surface: "#161922"
    readonly property color surfaceElevated: "#1e2230"
    readonly property color surfaceHover: "#252a3a"
    readonly property color border: "#2a3044"
    readonly property color borderLight: "#ffffff12"
    readonly property color accent: "#8b7cff"
    readonly property color accentHover: "#a599ff"
    readonly property color accentSoft: "#3d3566"
    readonly property color accentMuted: "#2a2640"
    readonly property color textPrimary: "#f4f6fb"
    readonly property color textSecondary: "#9aa3b8"
    readonly property color textMuted: "#6b7289"
    readonly property color success: "#4ade80"
    readonly property color warning: "#fbbf24"
    readonly property color danger: "#f87171"

    readonly property int radius: 14
    readonly property int radiusSmall: 8
    readonly property int radiusLarge: 20
    readonly property int spacing: 16
    readonly property int headerHeight: 72
    readonly property int cardWidth: 188
    readonly property int cardCoverHeight: 282
    readonly property int cardInfoHeight: 108
    readonly property int cardHeight: cardCoverHeight + cardInfoHeight
    readonly property int gridCellPadding: 12
    readonly property int iconSize: 20
    readonly property int iconSizeSmall: 16

    readonly property font titleFont: Qt.font({ pixelSize: 26, weight: Font.DemiBold, letterSpacing: -0.5 })
    readonly property font headingFont: Qt.font({ pixelSize: 18, weight: Font.DemiBold })
    readonly property font bodyFont: Qt.font({ pixelSize: 14 })
    readonly property font captionFont: Qt.font({ pixelSize: 12 })
    readonly property font labelFont: Qt.font({ pixelSize: 11, weight: Font.Medium })

    function statusColor(status) {
        switch (status) {
        case "看完": return success
        case "玩完": return success
        case "在看": return warning
        case "弃坑": return danger
        case "未看": return accent
        case "未玩": return accent
        default: return textSecondary
        }
    }

    function statusBgColor(status) {
        switch (status) {
        case "看完": return "#1a3d2a"
        case "玩完": return "#1a3d2a"
        case "在看": return "#3d3218"
        case "弃坑": return "#3d1f1f"
        case "未看": return accentMuted
        case "未玩": return accentMuted
        default: return surfaceHover
        }
    }
}
