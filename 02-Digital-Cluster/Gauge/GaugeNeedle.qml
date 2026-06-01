import QtQuick
import Digital_Cluster_DesignStudio

/*
 * ╔═══════════════════════════════════════════════════════════════╗
 * ║  GAUGE NEEDLE                                                 ║
 * ║                                                               ║
 * ║  A pointer that rotates around the gauge center to            ║
 * ║  indicate the current value.                                  ║
 * ║                                                               ║
 * ║  ORIGINAL DESIGN PRESERVED:                                   ║
 * ║    - Tapered shape (base → tip)                               ║
 * ║    - Red gradient with bright white tip                       ║
 * ║    - Soft red glow halo                                       ║
 * ║    - Tip flare radial gradient                                ║
 * ║                                                               ║
 * ║  PERFORMANCE OPTIMIZED:                                       ║
 * ║    - Canvas painted ONCE (not on every speed change)          ║
 * ║    - Only rotation is animated (GPU op)                       ║
 * ║    - Smooth easing between value changes                      ║
 * ║                                                               ║
 * ║  Reuses Theme colors via Theme.colorAccent* properties.       ║
 * ╚═══════════════════════════════════════════════════════════════╝
 */
Item {
    id: needleRoot

    // ════════════════════════════════════════════════════
    //  PUBLIC API
    // ════════════════════════════════════════════════════

    // Driving value
    property real value:    0
    property real maxValue: 240

    // Angle range — should match the rest of the gauge components
    property real startAngle: 135   // where value=0 points
    property real sweepAngle: 270   // total sweep

    // Needle geometry (in same coordinate space as the gauge)
    property real innerRadius:  115    // where the needle starts (from center)
    property real outerRadius:  215    // where the needle tip is
    property real needleWidth:  3      // half-width at the base

    // Animation
    property int animationDuration: Theme.durationNormal

    // Center hub cap (the small circle at the rotation point)
    property bool  showHub:        false
    property real  hubRadius:      7
    property color hubColor:       Theme.colorAccentPrimary
    property color hubBorderColor: Theme.colorAccentBright

    // Needle colors
    property color colorBase:   Theme.colorAccentPrimary
    property color colorMid:    Theme.colorAccentBright
    property color colorTip:    Theme.colorTextPrimary
    property color glowColor:   Theme.colorAccentBright
    property real  glowOpacity: 0.30


    // ════════════════════════════════════════════════════
    //  INTERNAL — smooth angle math
    // ════════════════════════════════════════════════════
    //
    // Math angle (0=right, +CW): startAngle + (value/max)*sweep
    //
    // Item rotation (0=up, +CW): math angle + 90
    //
    // The needle Item is laid out HORIZONTALLY (pointing right by default).
    // We rotate it so its tip points along the math angle:
    //   itemRotation = mathAngle  (because horizontal = 0° in math)

    // Target angle in math degrees
    readonly property real targetMathAngle:
        startAngle + (Math.max(0, Math.min(value / maxValue, 1.0))) * sweepAngle

    // Smoothly animated angle (what the needle actually shows)

    property bool enableSmoothing: true

    property real animatedAngle: targetMathAngle
    Behavior on animatedAngle {
        enabled: needleRoot.enableSmoothing // Tied to the toggle
        NumberAnimation {
            duration: needleRoot.animationDuration
            easing.type: Easing.OutCubic
        }
    }
    onTargetMathAngleChanged: animatedAngle = targetMathAngle
    Component.onCompleted:    animatedAngle = targetMathAngle

    // Center of the gauge
    readonly property real centerX: width  / 2
    readonly property real centerY: height / 2


    // ════════════════════════════════════════════════════
    //  NEEDLE BODY — drawn once, then just rotated
    // ════════════════════════════════════════════════════
    //
    // We create a small Item that contains a Canvas drawing
    // of the needle pointing RIGHT (along +X axis).
    // Then we rotate that Item around the gauge center.
    Item {
        id: needlePivot

        // size only big enough to contain the needle drawing
        // (width = outerRadius so the canvas starts at center)
        // (height fits the widest part + glow padding)
        width:  needleRoot.outerRadius + 20
        height: 40

        // Anchor: left edge at gauge center, vertically centered
        x: needleRoot.centerX
        y: needleRoot.centerY - height / 2

        // Rotate around the left-middle point (which is the gauge center)
        transform: Rotation {
            origin.x: 0
            origin.y: needlePivot.height / 2
            angle: needleRoot.animatedAngle
        }

        // ── Canvas: painted ONCE on completion ──────────
        Canvas {
            id: needleCanvas
            anchors.fill: parent

            Component.onCompleted: requestPaint()

            // NOTE: this canvas is NOT repainted when value changes.
            // Only the rotation transform above changes — which is
            // a cheap GPU operation.

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var cY    = height / 2
                var inner = needleRoot.innerRadius
                var outer = needleRoot.outerRadius
                var hw    = needleRoot.needleWidth

                // ── Layer 1: soft red glow halo ──
                ctx.save()
                ctx.shadowColor = Qt.rgba(0.90, 0.04, 0.08, needleRoot.glowOpacity * 2)
                ctx.shadowBlur  = 18

                ctx.beginPath()
                ctx.moveTo(outer, cY)
                ctx.lineTo(inner, cY - hw)
                ctx.lineTo(inner, cY + hw)
                ctx.closePath()

                ctx.fillStyle = Qt.rgba(0.65, 0.03, 0.05, needleRoot.glowOpacity)
                ctx.fill()
                ctx.restore()

                // ── Layer 2: tapered needle body ──
                ctx.beginPath()
                ctx.moveTo(outer, cY)
                ctx.lineTo(inner, cY - hw)
                ctx.lineTo(inner, cY + hw)
                ctx.closePath()

                // gradient from base (red) → mid (bright red) → tip (white)
                var grad = ctx.createLinearGradient(inner, 0, outer, 0)
                grad.addColorStop(0.0, needleRoot.colorBase.toString())
                grad.addColorStop(0.7, needleRoot.colorMid.toString())
                grad.addColorStop(1.0, needleRoot.colorTip.toString())
                ctx.fillStyle = grad
                ctx.fill()

                // ── Layer 3: bright center spine line ──
                ctx.beginPath()
                ctx.moveTo(inner, cY)
                ctx.lineTo(outer, cY)
                ctx.strokeStyle = Qt.rgba(1, 0.74, 0.74, 0.7)
                ctx.lineWidth = 1.1
                ctx.stroke()

                // ── Layer 4: hot white tip flare ──
                var flare = ctx.createRadialGradient(outer, cY, 0, outer, cY, 10)
                flare.addColorStop(0.0, "rgba(255, 255, 255, 0.95)")
                flare.addColorStop(0.5, "rgba(230, 9, 20, 0.45)")
                flare.addColorStop(1.0, "rgba(230, 9, 20, 0.0)")

                ctx.beginPath()
                ctx.arc(outer, cY, 10, 0, Math.PI * 2)
                ctx.fillStyle = flare
                ctx.fill()
            }
        }
    }


    // ════════════════════════════════════════════════════
    //  HUB CAP (small circle at the center)
    // ════════════════════════════════════════════════════
    //
    // The button-like dot at the rotation pivot point.
    // Doesn't rotate — stays static.
    Rectangle {
        id: hubCap
        visible: needleRoot.showHub

        width:  needleRoot.hubRadius * 2
        height: width
        radius: width / 2

        x: needleRoot.centerX - width  / 2
        y: needleRoot.centerY - height / 2

        color: needleRoot.hubColor
        border.color: needleRoot.hubBorderColor
        border.width: 1
    }
}
