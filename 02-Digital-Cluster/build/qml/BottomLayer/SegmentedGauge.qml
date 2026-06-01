import QtQuick
import Digital_Cluster_DesignStudio

/*
 * ╔═══════════════════════════════════════════════════════════════╗
 * ║  SEGMENTED GAUGE — Reusable horizontal segmented bar          ║
 * ║                                                               ║
 * ║  Renders a row of vertical tick marks. The fraction below     ║
 * ║  the current value is "active" (bright), the rest "passive"   ║
 * ║  (dim).                                                       ║
 * ║                                                               ║
 * ║  Used for: fuel gauge, motor temperature, any 0-100% display. ║
 * ║                                                               ║
 * ║  Optional: enables a danger color in the last X% of segments  ║
 * ║  (used by motor temp when overheating).                       ║
 * ║                                                               ║
 * ║  Pure Repeater + Rectangles — GPU rendered, no Canvas.        ║
 * ╚═══════════════════════════════════════════════════════════════╝
 */
Item {
    id: gaugeRoot

    // ════════════════════════════════════════════════════
    //  PUBLIC API
    // ════════════════════════════════════════════════════

    // The driving value (0–maxValue)
    property real value:    0
    property real maxValue: 100

    // Number of segment ticks
    property int  segmentCount: 30

    // Segment dimensions
    property real segmentWidth:    2
    property real segmentHeight:   14
    property real segmentSpacing:  4

    // Colors
    property color colorActive:  Theme.colorTextPrimary
    property color colorPassive: Theme.colorTextMuted
    property color colorDanger:  Theme.colorDanger

    // Danger zone (last X% of segments turn red when active)
    // Set to 0 to disable
    property real  dangerThresholdPercent: 0      // e.g., 0.8 = last 20% are danger

    // Auto-size to fit all segments
    implicitWidth:  segmentCount * segmentWidth + (segmentCount - 1) * segmentSpacing
    implicitHeight: segmentHeight


    // ════════════════════════════════════════════════════
    //  INTERNAL — compute how many segments are active
    // ════════════════════════════════════════════════════
    //
    // pct = value / maxValue (0–1)
    // activeCount = number of segments to highlight
    readonly property real percent:
        Math.max(0, Math.min(value / maxValue, 1.0))

    readonly property int activeCount:
        Math.round(percent * segmentCount)


    // ════════════════════════════════════════════════════
    //  SEGMENT ROW
    // ════════════════════════════════════════════════════
    Row {
        anchors.fill: parent
        spacing: gaugeRoot.segmentSpacing

        Repeater {
            model: gaugeRoot.segmentCount

            delegate: Rectangle {
                width:  gaugeRoot.segmentWidth
                height: gaugeRoot.segmentHeight
                radius: gaugeRoot.segmentWidth / 2

                // Is this segment "active" (below or equal to current value)?
                property bool isActive: index < gaugeRoot.activeCount

                // Is this segment in the danger zone?
                // (only matters if dangerThresholdPercent > 0)
                property bool isDangerZone:
                    gaugeRoot.dangerThresholdPercent > 0
                    && (index / gaugeRoot.segmentCount) >= gaugeRoot.dangerThresholdPercent

                // Color resolution:
                //  - Active + danger zone → red
                //  - Active otherwise     → primary white
                //  - Passive              → muted gray
                color: {
                    if (isActive && isDangerZone) return gaugeRoot.colorDanger
                    if (isActive) return gaugeRoot.colorActive
                    return gaugeRoot.colorPassive
                }

                // Passive segments are dimmer
                opacity: isActive ? 1.0 : 0.4

                // Smooth color transitions
                Behavior on color {
                    ColorAnimation { duration: Theme.durationFast }
                }
            }
        }
    }
}
