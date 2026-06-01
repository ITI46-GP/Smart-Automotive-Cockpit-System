import QtQuick
import Digital_Cluster_DesignStudio

/*
 * ╔═══════════════════════════════════════════════════════════════╗
 * ║  GAUGE INNER DISC                                             ║
 * ║                                                               ║
 * ║  The dark inner circle in the center of the gauge that        ║
 * ║  holds the speed number and unit label.                       ║
 * ║                                                               ║
 * ║  Provides visual depth and separates the number from the      ║
 * ║  busy tick marks around it.                                   ║
 * ║                                                               ║
 * ║  LAYERS (back → front):                                       ║
 * ║    1. Outer glow ring   - subtle red halo around the disc     ║
 * ║    2. Main disc         - dark filled circle                  ║
 * ║    3. Inner border ring - 1px subtle ring for definition      ║
 * ║                                                               ║
 * ╚═══════════════════════════════════════════════════════════════╝
 */
Item {
    id: discRoot

    // ════════════════════════════════════════════════════
    //  PUBLIC API
    // ════════════════════════════════════════════════════

    // Size of the inner disc (the dark circle)
    property real discRadius: 135

    // Colors
    property color discColor:        Theme.colorBackgroundBase       // main disc fill
    property color borderColor:      Theme.colorBackgroundElevated   // subtle inner ring
    property color glowColor:        Theme.colorAccentPrimary        // outer halo color

    // Optional outer glow
    property bool  showGlow:         true
    property real  glowOpacity:      0.15
    property real  glowSpread:       10      // how far the glow extends past the disc

    // Border ring
    property real  borderWidth:      1
    property real  borderOpacity:    0.6


    // ════════════════════════════════════════════════════
    //  LAYER 1 — OUTER GLOW RING
    // ════════════════════════════════════════════════════
    //
    // A wider, soft red circle behind the main disc.
    // Creates a subtle halo effect — like the disc is
    // glowing slightly from within.
    //
    // We achieve "glow" via:
    //   - A larger circle behind
    //   - Low opacity
    //   - The Rectangle's antialiasing softens the edge
    //
    // (We could use DropShadow but Rectangle is faster.)
    Rectangle {
        id: glowRing
        anchors.centerIn: parent
        visible: discRoot.showGlow

        // wider than the main disc
        width:  discRoot.discRadius * 2 + discRoot.glowSpread * 2
        height: width
        radius: width / 2

        color: discRoot.glowColor
        opacity: discRoot.glowOpacity
    }


    // ════════════════════════════════════════════════════
    //  LAYER 2 — MAIN DISC (dark filled circle)
    // ════════════════════════════════════════════════════
    //
    // The primary dark circle.
    // Uses Theme.colorBackgroundBase by default (#0A0A1B).
    Rectangle {
        id: mainDisc
        anchors.centerIn: parent

        width:  discRoot.discRadius * 2
        height: width
        radius: width / 2

        color: discRoot.discColor
    }


    // ════════════════════════════════════════════════════
    //  LAYER 3 — INNER BORDER RING
    // ════════════════════════════════════════════════════
    //
    // A subtle 1px ring just inside the disc edge.
    // Adds definition between the disc and the gauge area.
    //
    // Implementation: transparent Rectangle with a border.
    Rectangle {
        id: borderRing
        anchors.centerIn: parent

        // slightly smaller than the disc so the border sits inside
        width:  discRoot.discRadius * 2 - 2
        height: width
        radius: width / 2

        color: "transparent"

        border.color: discRoot.borderColor
        border.width: discRoot.borderWidth
        opacity:      discRoot.borderOpacity
    }
}
