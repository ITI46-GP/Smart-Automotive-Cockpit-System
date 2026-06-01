import QtQuick
import Digital_Cluster_DesignStudio

/*
 * ╔═══════════════════════════════════════════════════════════════╗
 * ║  GAUGE LABELS                                                 ║
 * ║                                                               ║
 * ║  Number labels (0, 30, 60, 90, ...) positioned around the     ║
 * ║  gauge at the big tick positions.                             ║
 * ║                                                               ║
 * ║  Each label is a Text element, positioned by polar math       ║
 * ║  (no rotation — labels stay upright for readability).         ║
 * ║                                                               ║
 * ║  Active state (label ≤ current value) → bright color          ║
 * ║  Passive state (label > current value) → muted color          ║
 * ║                                                               ║
 * ║  IMPLEMENTATION:                                              ║
 * ║    Pure Text elements positioned via x/y bindings.            ║
 * ║    NO Canvas, NO rotation per label, GPU-rendered.            ║
 * ║                                                               ║
 * ║  ANGLE CONVENTION:                                            ║
 * ║    Same as GaugeActiveArc:                                    ║
 * ║      startAngle = math angle (0=right, +CW)                   ║
 * ║      We use Math.cos/sin which expect radians.                ║
 * ╚═══════════════════════════════════════════════════════════════╝
 */
Item {
    id: labelsRoot

    // ════════════════════════════════════════════════════
    //  PUBLIC API
    // ════════════════════════════════════════════════════

    // Driving value
    property real value:    0
    property real maxValue: 240

    // Step between labels (should match GaugeTickMarks.bigStep)
    property int labelStep: 30

    // Where labels sit (distance from center)
    property real labelRadius: 160

    // Angle range — MUST match GaugeActiveArc and GaugeTickMarks
    property real startAngle: 135   // 0 value sits here
    property real sweepAngle: 270   // full sweep span

    // Typography
    property string fontFamily: Theme.fontPrimary
    property int    fontSize:   18
    property int    fontWeight: Theme.fontWeightMedium

    // Colors
    property color colorActive:  Theme.colorTextPrimary
    property color colorPassive: Theme.colorTextMuted


    // ════════════════════════════════════════════════════
    //  INTERNAL — generate the label model
    // ════════════════════════════════════════════════════
    //
    // Builds a list of label values: [0, 30, 60, ..., maxValue]
    readonly property var labelModel: {
        var arr = []
        for (var v = 0; v <= maxValue; v += labelStep) {
            arr.push(v)
        }
        return arr
    }

    // Center of the gauge area
    readonly property real centerX: width  / 2
    readonly property real centerY: height / 2


    // ════════════════════════════════════════════════════
    //  LABEL RENDERING
    // ════════════════════════════════════════════════════
    //
    // For each label, compute its (x, y) position using polar math:
    //   angle = startAngle + (val / maxValue) * sweepAngle
    //   x = centerX + cos(angle) * labelRadius
    //   y = centerY + sin(angle) * labelRadius
    //
    // Then subtract half width/height so the label is CENTERED at (x, y).

    Repeater {
        model: labelsRoot.labelModel

        delegate: Text {
            // The value this label represents
            property int labelValue: modelData

            // Compute the angle for this label (in math degrees)
            property real angleDeg:
                labelsRoot.startAngle
                + (labelValue / labelsRoot.maxValue) * labelsRoot.sweepAngle

            // Convert to radians for trig
            property real angleRad: angleDeg * Math.PI / 180.0

            // Polar → Cartesian conversion
            // Subtract half size to center the label on the point
            x: labelsRoot.centerX + Math.cos(angleRad) * labelsRoot.labelRadius - width / 2
            y: labelsRoot.centerY + Math.sin(angleRad) * labelsRoot.labelRadius - height / 2

            // Display the number
            text: labelValue

            // Active = label is below or at current value
            color: labelValue <= labelsRoot.value
                   ? labelsRoot.colorActive
                   : labelsRoot.colorPassive

            // Smooth color animation
            Behavior on color {
                ColorAnimation { duration: Theme.durationFast }
            }

            // Typography
            font.family:    labelsRoot.fontFamily
            font.pixelSize: labelsRoot.fontSize
            font.weight:    labelsRoot.fontWeight

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment:   Text.AlignVCenter
        }
    }
}
