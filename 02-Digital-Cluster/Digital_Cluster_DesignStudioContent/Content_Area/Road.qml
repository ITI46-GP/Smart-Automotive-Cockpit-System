import QtQuick 2.15

Item {
    id: root
    width: 480
    height: 520

    // ── shared road geometry ──────────────────────────────
    readonly property real vpX: width * 0.50
    readonly property real vpY: height * 0.55
    readonly property real halfRoad: width * 0.30   // narrower road
    readonly property real dashSide: 0.28

    // ── 1. Road surface gradient ──────────────────────────
    Canvas {
        id: roadSurface
        anchors.fill: parent

        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            var W = width, H = height
            var vpx = root.vpX
            var vpy = root.vpY
            var hr = root.halfRoad

            ctx.clearRect(0, 0, W, H)

            var bL = vpx - hr
            var bR = vpx + hr

            ctx.beginPath()
            ctx.moveTo(vpx, vpy)
            ctx.lineTo(bR, H)
            ctx.lineTo(bL, H)
            ctx.closePath()

            var grad = ctx.createLinearGradient(0, vpy, 0, H)
            grad.addColorStop(0.00, "rgba(15, 15, 20, 0.0)")
            grad.addColorStop(0.20, "rgba(15, 15, 20, 0.3)")
            grad.addColorStop(0.50, "rgba(20, 20, 28, 0.5)")
            grad.addColorStop(1.00, "rgba(25, 25, 35, 0.7)")
            ctx.fillStyle = grad
            ctx.fill()
        }
    }

    // ── 2. Horizon fog / atmospheric haze ─────────────────
    Canvas {
        id: horizonFog
        anchors.fill: parent

        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            var W = width, H = height
            var vpx = root.vpX
            var vpy = root.vpY

            ctx.clearRect(0, 0, W, H)

            // soft radial fog at the vanishing point
            var fog = ctx.createRadialGradient(
                vpx, vpy, 5,
                vpx, vpy, 120
            )
            fog.addColorStop(0.0, "rgba(120, 140, 180, 0.30)")
            fog.addColorStop(0.4, "rgba(80, 100, 140, 0.15)")
            fog.addColorStop(1.0, "rgba(0, 0, 0, 0.0)")

            ctx.beginPath()
            ctx.arc(vpx, vpy, 120, 0, Math.PI * 2)
            ctx.fillStyle = fog
            ctx.fill()
        }
    }

    // ── 3. Centre lane highlight ─────────────────────────
    Canvas {
        id: laneHighlight
        anchors.fill: parent

        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            var W = width, H = height
            var vpx = root.vpX
            var vpy = root.vpY
            var hr = W * 0.6
            var ds = root.dashSide

            ctx.clearRect(0, 0, W, H)

            var lBotX = vpx + (-ds) * hr
            var rBotX = vpx + (ds) * hr

            ctx.beginPath()
            ctx.moveTo(vpx, vpy)
            ctx.lineTo(rBotX, H)
            ctx.lineTo(lBotX, H)
            ctx.closePath()

            var grad = ctx.createLinearGradient(0, vpy, 0, H)
            grad.addColorStop(0.00, "rgba(255,255,255,0.00)")
            grad.addColorStop(0.25, "rgba(255,255,255,0.03)")
            grad.addColorStop(0.60, "rgba(255,255,255,0.09)")
            grad.addColorStop(1.00, "rgba(255,255,255,0.20)")
            ctx.fillStyle = grad
            ctx.fill()

            // bright spine
            ctx.beginPath()
            ctx.moveTo(vpx, vpy)
            ctx.lineTo(vpx - 60, H)
            ctx.lineTo(vpx + 60, H)
            ctx.closePath()

            var spine = ctx.createLinearGradient(vpx - 60, 0, vpx + 60, 0)
            spine.addColorStop(0.0, "rgba(255,255,255,0.00)")
            spine.addColorStop(0.5, "rgba(255,255,255,0.14)")
            spine.addColorStop(1.0, "rgba(255,255,255,0.00)")
            ctx.fillStyle = spine
            ctx.fill()
        }
    }

    // ── 4. Scrolling dashes ──────────────────────────────
    Item {
        id: dashContainer
        anchors.fill: parent
        clip: true

        property real offset: 0.0

        NumberAnimation on offset {
            from: 0.0; to: 1.0
            duration: 300
            loops: Animation.Infinite
            running: true
        }

        Canvas {
            id: leftDashes
            anchors.fill: parent

            property real watchOffset: dashContainer.offset
            onWatchOffsetChanged: requestPaint()
            Component.onCompleted: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                var W = width, H = height
                var vpx = root.vpX
                var vpy = root.vpY
                var hr = W * 0.6
                var ds = -root.dashSide
                var N = 16
                var off = dashContainer.offset

                ctx.clearRect(0, 0, W, H)

                for (var i = 0; i < N; i++) {
                    var t0 = ((i + off) / N) % 1.0
                    var t1 = ((i + off + 0.38) / N) % 1.0
                    if (t0 >= t1 || t0 < 0.01) continue

                    var x0 = vpx + ds * hr * t0
                    var y0 = vpy + (H - vpy) * t0
                    var x1 = vpx + ds * hr * t1
                    var y1 = vpy + (H - vpy) * t1

                    var alpha = t0 < 0.06 ? t0 / 0.06 : 1.0
                    var lw = 1.0 + t0 * 3.0

                    // glow pass
                    ctx.beginPath()
                    ctx.moveTo(x0, y0)
                    ctx.lineTo(x1, y1)
                    ctx.strokeStyle = "rgba(255,255,255," + (0.15 * alpha) + ")"
                    ctx.lineWidth = lw + 4
                    ctx.lineCap = "round"
                    ctx.stroke()

                    // main dash
                    ctx.beginPath()
                    ctx.moveTo(x0, y0)
                    ctx.lineTo(x1, y1)
                    ctx.strokeStyle = "rgba(255,255,255," + (0.7 * alpha) + ")"
                    ctx.lineWidth = lw
                    ctx.lineCap = "round"
                    ctx.stroke()
                }
            }
        }

        Canvas {
            id: rightDashes
            anchors.fill: parent

            property real watchOffset: dashContainer.offset
            onWatchOffsetChanged: requestPaint()
            Component.onCompleted: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                var W = width, H = height
                var vpx = root.vpX
                var vpy = root.vpY
                var hr = W * 0.6
                var ds = root.dashSide
                var N = 16
                var off = dashContainer.offset

                ctx.clearRect(0, 0, W, H)

                for (var i = 0; i < N; i++) {
                    var t0 = ((i + off) / N) % 1.0
                    var t1 = ((i + off + 0.38) / N) % 1.0
                    if (t0 >= t1 || t0 < 0.01) continue

                    var x0 = vpx + ds * hr * t0
                    var y0 = vpy + (H - vpy) * t0
                    var x1 = vpx + ds * hr * t1
                    var y1 = vpy + (H - vpy) * t1

                    var alpha = t0 < 0.06 ? t0 / 0.06 : 1.0
                    var lw = 1.0 + t0 * 3.0

                    // glow pass
                    ctx.beginPath()
                    ctx.moveTo(x0, y0)
                    ctx.lineTo(x1, y1)
                    ctx.strokeStyle = "rgba(255,255,255," + (0.15 * alpha) + ")"
                    ctx.lineWidth = lw + 4
                    ctx.lineCap = "round"
                    ctx.stroke()

                    // main dash
                    ctx.beginPath()
                    ctx.moveTo(x0, y0)
                    ctx.lineTo(x1, y1)
                    ctx.strokeStyle = "rgba(255,255,255," + (0.7 * alpha) + ")"
                    ctx.lineWidth = lw
                    ctx.lineCap = "round"
                    ctx.stroke()
                }
            }
        }
    }


    // ── 6. Subtle scrolling speed lines (motion blur feel) ─
    Canvas {
        id: speedLines
        anchors.fill: parent

        property real offset: 0.0

        NumberAnimation on offset {
            from: 0.0; to: 1.0
            duration: 600
            loops: Animation.Infinite
            running: true
        }
        onOffsetChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            var W = width, H = height
            var vpx = root.vpX
            var vpy = root.vpY
            var N = 6
            var off = offset

            ctx.clearRect(0, 0, W, H)

            // faint motion streaks down the centre
            for (var i = 0; i < N; i++) {
                var t = ((i + off) / N) % 1.0
                if (t < 0.15) continue

                var y0 = vpy + (H - vpy) * t
                var y1 = vpy + (H - vpy) * (t + 0.04)
                if (y1 > H) y1 = H

                var xOffset = (i % 2 === 0 ? -20 : 20) * t

                ctx.beginPath()
                ctx.moveTo(vpx + xOffset, y0)
                ctx.lineTo(vpx + xOffset * 1.1, y1)
                ctx.strokeStyle = "rgba(180, 200, 255, " + (0.12 * t) + ")"
                ctx.lineWidth = 1.5
                ctx.lineCap = "round"
                ctx.stroke()
            }
        }
    }
}
