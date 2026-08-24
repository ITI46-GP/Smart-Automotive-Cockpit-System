// Ported from 02-Digital-Cluster/Gauge/GaugeSpeedNumber.qml — pure Text
// elements, no Canvas, no layer.enabled. Per PLAN.md's audit this component
// was already compliant before the rebuild started, so it's ported close to
// verbatim; the only changes are the Theme import (C++ QML_SINGLETON now, so
// it needs an explicit `import QnxCluster`) and the notes below.
//
// S5 RISK THIS COMPONENT CARRIES: this is the first glyph rendering in the
// ladder. Watch `polish` — text layout/shaping happens on the GUI thread, and
// a number whose *string* changes every frame re-lays-out every frame. The
// big number here is driven by `displayValue`, which by default is
// Math.round(value) — so it only changes when the rounded integer changes,
// not on every frame, which is exactly what you want. If a future call site
// passes an unrounded or high-precision string (e.g. value.toFixed(1) on a
// continuously animating value), it will re-shape glyphs on every frame.
// That is a real cost, not a hypothetical one: it is the same class of
// per-frame GUI-thread work that Rule 1 exists to prevent for Canvas.
//
// The RPM call site DOES pass toFixed(1). That is faithful to the original
// and is deliberately kept, so S5 measures the honest worst case rather than
// a flattering one — if it costs, we will see it in polish and can decide
// whether to quantise the string.

import QtQuick
import QnxCluster

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
    property string numberFontFamily: "Kdam Thmor Pro"
    property int    numberFontSize:   104
    property int    numberFontWeight: Theme.fontWeightRegular

    // ── UNIT LABEL typography ──────────────────────────
    property string unitFontFamily: Theme.fontPrimary
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
    readonly property color activeColor: {
        var pct = value / maxValue
        if (pct >= dangerThreshold) return colorDanger
        if (pct >= warnThreshold)   return colorWarning
        return colorNormal
    }


    // ════════════════════════════════════════════════════
    //  LAYER 1 — BIG NUMBER (HERO)
    // ════════════════════════════════════════════════════
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
