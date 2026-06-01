import QtQuick
import Digital_Cluster_DesignStudio

/*
 * ╔═══════════════════════════════════════════════════════════════╗
 * ║  GAUGE SPEED LIMIT BADGE                                      ║
 * ║                                                               ║
 * ║  A classic round speed limit sign:                            ║
 * ║    - White circular background                                ║
 * ║    - Thick red border ring (universal road sign style)        ║
 * ║    - Black number inside (current speed limit)                ║
 * ║                                                               ║
 * ║  Optional features:                                           ║
 * ║    - Auto-hide when no speed limit is set                     ║
 * ║    - Pulse animation when speeding over the limit             ║
 * ║    - Red glow when violating the limit                        ║
 * ║                                                               ║
 * ║  Pure Rectangle + Text → GPU rendered, no Canvas.             ║
 * ╚═══════════════════════════════════════════════════════════════╝
 */
Item {
    id: badgeRoot

    // ════════════════════════════════════════════════════
    //  PUBLIC API
    // ════════════════════════════════════════════════════

    // The speed limit to display (0 or negative = hide badge)
    property int speedLimit: 0

    // Current speed (for violation detection)
    property real currentSpeed: 0

    // Speeding tolerance (e.g., 5 means 5 km/h over is OK)
    property real speedingTolerance: 5

    // Badge size (diameter)
    property real badgeSize: 60

    // Border thickness (red ring)
    property real borderWidth: 5

    // Colors
    property color backgroundColor:   Theme.colorTextPrimary    // white-ish disc
    property color borderColor:       Theme.colorAccentPrimary  // red ring
    property color numberColor:       Theme.colorBackgroundDeepest  // black number
    property color violationGlowColor: Theme.colorDanger        // red glow when speeding

    // Typography
    property string fontFamily: Theme.fontPrimary
    property int    fontWeight: Theme.fontWeightBold

    // Auto-compute font size from badge size (look proportional)
    property int fontSize: badgeSize * 0.42

    // Behavior toggles
    property bool autoHide:           true   // hide when speedLimit <= 0
    property bool pulseWhenViolating: true   // pulse animation when speeding


    // ════════════════════════════════════════════════════
    //  INTERNAL — violation detection
    // ════════════════════════════════════════════════════

    // Is the driver speeding right now?
    readonly property bool isViolating:
        speedLimit > 0 && currentSpeed > (speedLimit + speedingTolerance)


    // ════════════════════════════════════════════════════
    //  VISIBILITY
    // ════════════════════════════════════════════════════

    visible: !autoHide || speedLimit > 0

    // Match the badge dimensions
    width:  badgeSize
    height: badgeSize


    // ════════════════════════════════════════════════════
    //  LAYER 1 — VIOLATION GLOW (only when speeding)
    // ════════════════════════════════════════════════════
    //
    // A wider red circle behind the badge that pulses when
    // the driver exceeds the speed limit.
    Rectangle {
        id: violationGlow
        anchors.centerIn: parent

        width:  badgeRoot.badgeSize + 30
        height: width
        radius: width / 2

        color: badgeRoot.violationGlowColor
        opacity: badgeRoot.isViolating ? 0.5 : 0.0

        // Smooth fade in/out when violation state changes
        Behavior on opacity {
            NumberAnimation { duration: Theme.durationNormal }
        }

        // Pulse animation: only runs while violating
        SequentialAnimation on scale {
            running: badgeRoot.isViolating && badgeRoot.pulseWhenViolating
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 1.15; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.15; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
        }
    }


    // ════════════════════════════════════════════════════
    //  LAYER 2 — RED BORDER RING (outer red circle)
    // ════════════════════════════════════════════════════
    //
    // The thick red outer ring.
    // We achieve this with a filled red Rectangle that's
    // then covered by the white inner Rectangle.
    Rectangle {
        id: outerRing
        anchors.centerIn: parent

        width:  badgeRoot.badgeSize
        height: width
        radius: width / 2

        color: badgeRoot.borderColor
    }


    // ════════════════════════════════════════════════════
    //  LAYER 3 — WHITE INNER CIRCLE
    // ════════════════════════════════════════════════════
    //
    // Smaller white circle sitting on top of the red one,
    // leaving the red border visible around its edge.
    Rectangle {
        id: innerCircle
        anchors.centerIn: parent

        width:  badgeRoot.badgeSize - badgeRoot.borderWidth * 2
        height: width
        radius: width / 2

        color: badgeRoot.backgroundColor
    }


    // ════════════════════════════════════════════════════
    //  LAYER 4 — SPEED LIMIT NUMBER (black text)
    // ════════════════════════════════════════════════════
    Text {
        id: limitNumber
        anchors.centerIn: parent

        text: badgeRoot.speedLimit

        color: badgeRoot.numberColor

        font.family:    badgeRoot.fontFamily
        font.pixelSize: badgeRoot.fontSize
        font.weight:    badgeRoot.fontWeight

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment:   Text.AlignVCenter
    }
}
