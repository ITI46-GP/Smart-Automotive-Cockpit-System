import QtQuick
import Digital_Cluster_DesignStudio

/*
 * ╔═══════════════════════════════════════════════════════════════╗
 * ║  GAUGE MODE BADGE (Drive Mode Display)                        ║
 * ║                                                               ║
 * ║  Displays the current drive mode (ECO / NORMAL / SPORT) as    ║
 * ║  a pill-shaped badge with color-coded background.             ║
 * ║                                                               ║
 * ║  Modes:                                                       ║
 * ║    - ECO    → green (efficiency)                              ║
 * ║    - NORMAL → white/neutral                                   ║
 * ║    - SPORT  → red (performance)                               ║
 * ║                                                               ║
 * ║  Mode strings are case-insensitive (matches "eco", "ECO").    ║
 * ║                                                               ║
 * ╚═══════════════════════════════════════════════════════════════╝
 */
Item {
    id: badgeRoot

    // ════════════════════════════════════════════════════
    //  PUBLIC API
    // ════════════════════════════════════════════════════

    // Current mode (case-insensitive: ECO, NORMAL, SPORT)
    property string mode: "NORMAL"

    // Badge dimensions
    property real badgeHeight:  28
    property real badgeRadius:  6
    property real paddingH:     14
    property real paddingV:     4

    // Typography
    property string fontFamily: Theme.fontPrimary
    property int    fontSize:   14
    property int    fontWeight: Theme.fontWeightBold
    property real   letterSpacing: 2

    // Mode color overrides (defaults to Theme + green for ECO)
    property color colorEco:      Theme.colorSuccess
    property color colorNormal:   Theme.colorTextPrimary
    property color colorSport:    Theme.colorAccentPrimary
    property color colorTextEco:    Theme.colorBackgroundDeepest
    property color colorTextNormal: Theme.colorBackgroundDeepest
    property color colorTextSport:  Theme.colorTextPrimary


    // ════════════════════════════════════════════════════
    //  INTERNAL — mode normalization & color logic
    // ════════════════════════════════════════════════════

    // Normalize mode string to uppercase for matching
    readonly property string normalizedMode: mode.toUpperCase()

    // Background color based on mode
    readonly property color bgColor: {
        if (normalizedMode === "ECO")   return colorEco
        if (normalizedMode === "SPORT") return colorSport
        return colorNormal
    }

    // Text color based on mode (for contrast)
    readonly property color textColor: {
        if (normalizedMode === "ECO")   return colorTextEco
        if (normalizedMode === "SPORT") return colorTextSport
        return colorTextNormal
    }


    // ════════════════════════════════════════════════════
    //  AUTO-SIZE based on text content + padding
    // ════════════════════════════════════════════════════
    implicitWidth:  modeText.implicitWidth + paddingH * 2
    implicitHeight: badgeHeight


    // ════════════════════════════════════════════════════
    //  LAYER 1 — BACKGROUND PILL
    // ════════════════════════════════════════════════════
    Rectangle {
        id: bgPill
        anchors.fill: parent
        radius: badgeRoot.badgeRadius
        color: badgeRoot.bgColor

        // Smooth color transition when mode changes
        Behavior on color {
            ColorAnimation { duration: Theme.durationNormal }
        }

        // Subtle outline for depth
        border.color: Qt.darker(badgeRoot.bgColor, 1.4)
        border.width: 1
    }


    // ════════════════════════════════════════════════════
    //  LAYER 2 — MODE TEXT
    // ════════════════════════════════════════════════════
    Text {
        id: modeText
        anchors.centerIn: parent
        text: badgeRoot.normalizedMode

        color: badgeRoot.textColor

        Behavior on color {
            ColorAnimation { duration: Theme.durationNormal }
        }

        font.family:        badgeRoot.fontFamily
        font.pixelSize:     badgeRoot.fontSize
        font.weight:        badgeRoot.fontWeight
        font.letterSpacing: badgeRoot.letterSpacing
    }
}
