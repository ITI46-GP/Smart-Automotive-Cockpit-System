import QtQuick
import Digital_Cluster_DesignStudio

/*
 * ╔═══════════════════════════════════════════════════════════════╗
 * ║  GAUGE SPEED NUMBER                                           ║
 * ║                                                               ║
 * ║  The big hero number in the center of the gauge + unit label. ║
 * ║                                                               ║
 * ║  Features:                                                    ║
 * ║    - Large bold display number using Kdam Thmor Pro           ║
 * ║    - Color shifts based on percentage of max:                 ║
 * ║        < warnThreshold   → primary text (white)               ║
 * ║        ≥ warnThreshold   → warning (amber)                    ║
 * ║        ≥ dangerThreshold → danger (red)                       ║
 * ║    - Unit label below in smaller, muted text                  ║
 * ║                                                               ║
 * ║  Pure Text elements — GPU rendered, no Canvas.                ║
 * ║                                                               ║
 * ║  REUSABLE: Works for speed, RPM, or any numeric value.        ║
 * ║    For RPM: pass formatted string like "3.5" and unit "RPM"   ║
 * ╚═══════════════════════════════════════════════════════════════╝
 */
Item {
    id: numberRoot

    // ════════════════════════════════════════════════════
    //  PUBLIC API
    // ════════════════════════════════════════════════════

    // The driving value
    property real value:    0
    property real maxValue: 240

    // What to display (formatted string)
    // Default: rounded integer of value
    // For RPM: override to value.toFixed(1)
    property string displayValue: Math.round(value).toString()

    // Unit label below the number
    property string unitText: "KM/H"

    // Color-shift thresholds (% of maxValue)
    property real warnThreshold:   0.80   // 80% → amber
    property real dangerThreshold: 0.95   // 95% → red

    // Vertical offset of the number from center (negative = up)
    property real numberOffsetY: -10

    // Spacing between number and unit label
    property real unitSpacing: -20   // negative pulls unit closer

    // ── BIG NUMBER typography ──────────────────────────
    property string numberFontFamily: "Kdam Thmor Pro"   // your preferred font
    property int    numberFontSize:   104
    property int    numberFontWeight: Theme.fontWeightRegular

    // ── UNIT LABEL typography ──────────────────────────
    property string unitFontFamily: Theme.fontPrimary    // uses Inter from theme
    property int    unitFontSize:   Theme.fontSizeLarge
    property int    unitFontWeight: Theme.fontWeightMedium
    property real   unitLetterSpacing: 2

    // Colors
    property color colorNormal:  Theme.colorTextPrimary
    property color colorWarning: Theme.colorWarning
    property color colorDanger:  Theme.colorDanger
    property color colorUnit:    Theme.colorTextSecondary


    // ════════════════════════════════════════════════════
    //  INTERNAL — color logic
    // ════════════════════════════════════════════════════

    // Compute the active color based on current value percentage
    readonly property color activeColor: {
        var pct = value / maxValue
        if (pct >= dangerThreshold) return colorDanger
        if (pct >= warnThreshold)   return colorWarning
        return colorNormal
    }


    // ════════════════════════════════════════════════════
    //  LAYER 1 — BIG NUMBER (HERO)
    // ════════════════════════════════════════════════════
    //
    // Uses Kdam Thmor Pro at large size.
    // Color smoothly transitions when crossing thresholds.
    Text {
        id: bigNumber
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: numberRoot.numberOffsetY

        text: numberRoot.displayValue

        color: numberRoot.activeColor

        // Smooth color transitions when crossing warn/danger thresholds
        Behavior on color {
            ColorAnimation { duration: Theme.durationNormal }
        }

        font.family:    numberRoot.numberFontFamily
        font.pixelSize: numberRoot.numberFontSize
        font.weight:    numberRoot.numberFontWeight

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment:   Text.AlignVCenter
    }


    // ════════════════════════════════════════════════════
    //  LAYER 2 — UNIT LABEL
    // ════════════════════════════════════════════════════
    //
    // Small letter-spaced text below the number.
    // Always uses the secondary text color (muted).
    Text {
        id: unitLabel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: bigNumber.bottom
        anchors.topMargin: numberRoot.unitSpacing

        text: numberRoot.unitText

        color: numberRoot.colorUnit

        font.family:        numberRoot.unitFontFamily
        font.pixelSize:     numberRoot.unitFontSize
        font.weight:        numberRoot.unitFontWeight
        font.letterSpacing: numberRoot.unitLetterSpacing

        horizontalAlignment: Text.AlignHCenter
    }
}
