import QtQuick
import Digital_Cluster_DesignStudio

/*
 * ╔═══════════════════════════════════════════════════════════════╗
 * ║  GAUGE REDLINE ZONE                                           ║
 * ║                                                               ║
 * ║  Draws RED tick marks in the "danger" portion of the gauge.   ║
 * ║  Overlays on top of the normal GaugeTickMarks.                ║
 * ║                                                               ║
 * ║  Use cases:                                                   ║
 * ║    - RPM gauge: last 1000 RPM (5–6 range)                     ║
 * ║    - Speed gauge: last 30 km/h (210–240 range)                ║
 * ║    - Temperature gauge: last 10° before overheating           ║
 * ║                                                               ║
 * ║  Uses the same tick model as GaugeTickMarks — keep step       ║
 * ║  values matching for visual consistency.                      ║
 * ║                                                               ║
 * ║  Pure rotated Rectangles, GPU-rendered, no Canvas.            ║
 * ╚═══════════════════════════════════════════════════════════════╝
 */
Item {
    id: redlineRoot

    // ════════════════════════════════════════════════════
    //  PUBLIC API
    // ════════════════════════════════════════════════════

    // Range where the redline starts (in value units)
    property real redlineStart: 5      // e.g., 5 (= 5000 RPM) or 210 (= 210 km/h)
    property real maxValue:     6      // gauge max

    // Step sizes — should match GaugeTickMarks
    property real bigStep:    1
    property real mediumStep: 0.5
    property real smallStep:  0.1

    // Tick geometry — should match GaugeTickMarks
    property real tickOuterRadius: 220
    property real tickLengthBig:    35
    property real tickLengthMedium: 20
    property real tickLengthSmall:  12

    property real tickWidthBig:    3
    property real tickWidthMedium: 1.8
    property real tickWidthSmall:  1.0

    // Angle range — must match the rest of the gauge
    property real startAngle: 135
    property real sweepAngle: 270

    // Redline color (use Theme by default)
    property color redlineColor: Theme.colorDanger


    // ════════════════════════════════════════════════════
    //  INTERNAL — build only the redline ticks
    // ════════════════════════════════════════════════════
    //
    // We iterate from redlineStart to maxValue, generating
    // tick descriptors just like GaugeTickMarks does.
    readonly property var tickModel: {
        var arr = []
        var eps = 0.0001

        function isMultipleOf(value, step) {
            var remainder = value % step
            return remainder < eps || (step - remainder) < eps
        }

        for (var v = redlineStart; v <= maxValue + eps; v += smallStep) {
            var roundedV = Math.round(v / smallStep) * smallStep

            var kind
            if (isMultipleOf(roundedV, bigStep)) {
                kind = "big"
            } else if (isMultipleOf(roundedV, mediumStep)) {
                kind = "medium"
            } else {
                kind = "small"
            }
            arr.push({ val: roundedV, kind: kind })
        }
        return arr
    }

    readonly property real centerX: width  / 2
    readonly property real centerY: height / 2


    // ════════════════════════════════════════════════════
    //  TICK RENDERING (same logic as GaugeTickMarks)
    // ════════════════════════════════════════════════════
    Repeater {
        model: redlineRoot.tickModel

        delegate: Item {
            property real tickAngleDeg:
                redlineRoot.startAngle
                + (modelData.val / redlineRoot.maxValue) * redlineRoot.sweepAngle
                + 90

            property real tickLength:
                modelData.kind === "big"    ? redlineRoot.tickLengthBig    :
                modelData.kind === "medium" ? redlineRoot.tickLengthMedium :
                                              redlineRoot.tickLengthSmall

            property real tickWidth:
                modelData.kind === "big"    ? redlineRoot.tickWidthBig    :
                modelData.kind === "medium" ? redlineRoot.tickWidthMedium :
                                              redlineRoot.tickWidthSmall

            anchors.fill: parent
            transform: Rotation {
                origin.x: redlineRoot.centerX
                origin.y: redlineRoot.centerY
                angle:    tickAngleDeg
            }

            Rectangle {
                width:  tickWidth
                height: tickLength
                radius: tickWidth / 2

                x: redlineRoot.centerX - width / 2
                y: redlineRoot.centerY - redlineRoot.tickOuterRadius

                color: redlineRoot.redlineColor
            }
        }
    }
}
