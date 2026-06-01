import QtQuick
import QtQuick.Studio.DesignEffects

Item {
    id: bezelFrame
    width: 1200
    height: 600

    // ── tunable properties ────────────────────────────
    property real frameRadius: 200
    property real bezelWidth: 20
    property color innerColor: "#000000"

    // symmetric coloring
    property color bezelEdgeColor: "#15161a"
    property color bezelMidColor:  "#3a3b3f"

    // bottom curve properties
    property real bottomCurveWidth: 600
    property real bottomCurveDepth: 80

    // ══════════════════════════════════════════════════
    // FRAME — drawn with Canvas using stroke for border
    // ══════════════════════════════════════════════════

    Canvas {
        id: frameCanvas
        anchors.fill: parent
        z: -1

        Component.onCompleted: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        // builds the CENTERLINE path (the middle of the bezel ring)
        function buildCenterPath(ctx, W, H, r, cw, cd, bw) {
            // offset everything inward by bw/2 so the stroke fills from edge inward
            var off = bw / 2
            ctx.beginPath()
            ctx.moveTo(r, off)
            ctx.lineTo(W - r, off)
            ctx.arcTo(W - off, off, W - off, r, r - off)
            ctx.lineTo(W - off, H - r)
            ctx.arcTo(W - off, H - off, W - r, H - off, r - off)
            ctx.lineTo(W / 2 + cw / 2, H - off)
            ctx.quadraticCurveTo(W / 2, H - cd - off, W / 2 - cw / 2, H - off)
            ctx.lineTo(r, H - off)
            ctx.arcTo(off, H - off, off, H - r, r - off)
            ctx.lineTo(off, r)
            ctx.arcTo(off, off, r, off, r - off)
            ctx.closePath()
        }

        // builds the OUTER path (for clipping the inner hole)
        function buildOuterPath(ctx, W, H, r, cw, cd) {
            ctx.beginPath()
            ctx.moveTo(r, 0)
            ctx.lineTo(W - r, 0)
            ctx.arcTo(W, 0, W, r, r)
            ctx.lineTo(W, H - r)
            ctx.arcTo(W, H, W - r, H, r)
            ctx.lineTo(W / 2 + cw / 2, H)
            ctx.quadraticCurveTo(W / 2, H - cd, W / 2 - cw / 2, H)
            ctx.lineTo(r, H)
            ctx.arcTo(0, H, 0, H - r, r)
            ctx.lineTo(0, r)
            ctx.arcTo(0, 0, r, 0, r)
            ctx.closePath()
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var W  = width
            var H  = height
            var r  = bezelFrame.frameRadius
            var cw = bezelFrame.bottomCurveWidth
            var cd = bezelFrame.bottomCurveDepth
            var bw = bezelFrame.bezelWidth

            // ── STEP 1: fill the OUTER shape with inner-cutout color
            // (this becomes the background, only the bezel ring will cover it)
            buildOuterPath(ctx, W, H, r, cw, cd)

            var innerGrad = ctx.createLinearGradient(0, 0, 0, H)
            innerGrad.addColorStop(0.0,  "#1a1a1d")
            innerGrad.addColorStop(0.05, "#08080a")
            innerGrad.addColorStop(0.5,  "#0a0a0c")
            innerGrad.addColorStop(0.95, "#08080a")
            innerGrad.addColorStop(1.0,  "#000000")
            ctx.fillStyle = innerGrad
            ctx.fill()

            // ── STEP 2: STROKE the centerline path with bezel width
            // This is the key — stroke gives PERFECTLY UNIFORM thickness everywhere
            buildCenterPath(ctx, W, H, r, cw, cd, bw)

            // create a gradient for the stroke
            var grad = ctx.createLinearGradient(0, 0, 0, H)
            grad.addColorStop(0.0,  bezelFrame.bezelEdgeColor)
            grad.addColorStop(0.5,  bezelFrame.bezelMidColor)
            grad.addColorStop(1.0,  bezelFrame.bezelEdgeColor)

            ctx.strokeStyle = grad
            ctx.lineWidth = bw
            ctx.lineJoin = "round"
            ctx.lineCap = "round"
            ctx.stroke()

            // ── STEP 3: subtle highlights on the bezel
            // top edge highlight
            ctx.beginPath()
            ctx.moveTo(r + 30, 1)
            ctx.lineTo(W - r - 30, 1)
            ctx.strokeStyle = "rgba(120, 120, 130, 0.3)"
            ctx.lineWidth = 1
            ctx.stroke()

            // bottom straight edges highlight
            ctx.beginPath()
            ctx.moveTo(r + 30, H - 1)
            ctx.lineTo(W / 2 - cw / 2, H - 1)
            ctx.strokeStyle = "rgba(120, 120, 130, 0.3)"
            ctx.lineWidth = 1
            ctx.stroke()

            ctx.beginPath()
            ctx.moveTo(W / 2 + cw / 2, H - 1)
            ctx.lineTo(W - r - 30, H - 1)
            ctx.strokeStyle = "rgba(120, 120, 130, 0.3)"
            ctx.lineWidth = 1
            ctx.stroke()

            // curve highlight (along the dip)
            ctx.beginPath()
            ctx.moveTo(W / 2 + cw / 2, H - 1)
            ctx.quadraticCurveTo(W / 2, H - cd - 1, W / 2 - cw / 2, H - 1)
            ctx.strokeStyle = "rgba(140, 140, 145, 0.35)"
            ctx.lineWidth = 1
            ctx.stroke()
        }
    }

    // ── Drop shadow under the frame ───────────────────
    Canvas {
        id: shadowCanvas
        anchors.fill: parent
        z: -2
        opacity: 0.7

        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var W  = width
            var H  = height
            var r  = bezelFrame.frameRadius
            var cw = bezelFrame.bottomCurveWidth
            var cd = bezelFrame.bottomCurveDepth

            ctx.save()
            ctx.shadowColor = "rgba(0, 0, 0, 0.9)"
            ctx.shadowBlur = 25
            ctx.shadowOffsetY = 12

            ctx.beginPath()
            ctx.moveTo(r, 0)
            ctx.lineTo(W - r, 0)
            ctx.arcTo(W, 0, W, r, r)
            ctx.lineTo(W, H - r)
            ctx.arcTo(W, H, W - r, H, r)
            ctx.lineTo(W / 2 + cw / 2, H)
            ctx.quadraticCurveTo(W / 2, H - cd, W / 2 - cw / 2, H)
            ctx.lineTo(r, H)
            ctx.arcTo(0, H, 0, H - r, r)
            ctx.lineTo(0, r)
            ctx.arcTo(0, 0, r, 0, r)
            ctx.closePath()

            ctx.fillStyle = "#000000"
            ctx.fill()
            ctx.restore()
        }
    }
}
