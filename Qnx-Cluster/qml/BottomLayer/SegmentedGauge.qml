import QtQuick
import QnxCluster

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

    // The driving value (minValue–maxValue)
    property real value:    0
    property real minValue: 0
    property real maxValue: 100

    // Number of segment ticks
    property int  segmentCount: 30

    // Segment dimensions
    property real segmentWidth:    2
    property real segmentHeight:   14
    property real defaultSpacing:  4

    // S7: per-item opacity is a material difference, so 30 segments at three
    // different opacities cannot merge into one batch. At ~0.42 ms per batch
    // on this board that is the whole cost of the bar. `flatOpacity` collapses
    // the three levels to two so the segments can batch.
    property bool flatOpacity: false

    // Colors
    property color colorActive:  Theme.colorTextPrimary
    property color colorPassive: Theme.colorTextMuted
    property color colorEnd:     Theme.colorDanger
    property color colorStart:   "#00BFFF" // Light blue default

    // End zone (last X% of segments turn colorEnd)
    property real  endThresholdPercent: 0      

    // Start zone (first X% of segments turn colorStart)
    property real  startThresholdPercent: 0

    // Auto-size to fit all segments by default
    implicitWidth:  segmentCount * segmentWidth + (segmentCount - 1) * defaultSpacing
    implicitHeight: segmentHeight


    // ════════════════════════════════════════════════════
    //  INTERNAL — compute how many segments are active
    // ════════════════════════════════════════════════════
    //
    // pct = (value - minValue) / (maxValue - minValue)
    // activeCount = number of segments to highlight
    readonly property real percent:
        Math.max(0, Math.min((value - gaugeRoot.minValue) / (gaugeRoot.maxValue - gaugeRoot.minValue), 1.0))

    readonly property int activeCount:
        Math.round(percent * segmentCount)


    //  SEGMENT ROW
    // ════════════════════════════════════════════════════
    // Calculate dynamic spacing so the segments stretch to fill the exact width provided
    readonly property real dynamicSpacing: (width - (segmentCount * segmentWidth)) / Math.max(1, segmentCount - 1)

    Row {
        anchors.fill: parent
        spacing: gaugeRoot.dynamicSpacing

        Repeater {
            model: gaugeRoot.segmentCount

            delegate: Rectangle {
                // Qt 6 wants delegate model roles declared. `index` was an
                // implicit context property in the original; making it required
                // keeps qmllint quiet and the binding explicit.
                required property int index

                width:  gaugeRoot.segmentWidth
                height: gaugeRoot.segmentHeight
                radius: gaugeRoot.segmentWidth / 2

                // Is this segment "active" (below or equal to current value)?
                property bool isActive: index < gaugeRoot.activeCount

                // NOTE: the original declared an `isDangerZone` property here
                // referencing `gaugeRoot.dangerThresholdPercent`, which is not
                // declared anywhere in this component — so it evaluated against
                // an undefined property, and nothing ever read the result (the
                // colour logic below uses isStartSegment/isEndSegment). Dropped
                // rather than ported: it is dead code that emits a runtime
                // warning on every one of the 60 delegates.

                // Is this segment in the start zone?
                property bool isStartSegment:
                    gaugeRoot.startThresholdPercent > 0
                    && (index / gaugeRoot.segmentCount) <= gaugeRoot.startThresholdPercent

                // Is this segment in the end zone?
                property bool isEndSegment:
                    gaugeRoot.endThresholdPercent > 0
                    && (index / gaugeRoot.segmentCount) >= gaugeRoot.endThresholdPercent
                    
                property bool isNormalSegment: !isStartSegment && !isEndSegment

                // Static colors based purely on position!
                color: {
                    if (isEndSegment) return gaugeRoot.colorEnd
                    if (isStartSegment) return gaugeRoot.colorStart
                    return gaugeRoot.colorActive
                }

                // Which zone is the current value residing in?
                property bool inStartZone: gaugeRoot.startThresholdPercent > 0 && gaugeRoot.percent <= gaugeRoot.startThresholdPercent
                property bool inEndZone: gaugeRoot.endThresholdPercent > 0 && gaugeRoot.percent >= gaugeRoot.endThresholdPercent
                property bool inNormalZone: !inStartZone && !inEndZone

                // Does this segment belong to the current active zone?
                property bool isMyZone: 
                    (isStartSegment && inStartZone) || 
                    (isEndSegment && inEndZone) || 
                    (isNormalSegment && inNormalZone)

                // Opacity resolution:
                // - Reached (isActive): High Opacity (keeps the bar filled)
                // - Unreached but in Current Zone: Medium Opacity
                // - Unreached and outside Current Zone: Low Opacity
                opacity: {
                    if (gaugeRoot.flatOpacity)
                        return isActive ? 1.0 : 0.25
                    if (isActive) {
                        return 1.0
                    } else if (isMyZone) {
                        return 0.3
                    } else {
                        return 0.1
                    }
                }

                // Smooth color transitions. Same batching caveat as the
                // gauge labels: while this runs, segments hold distinct
                // interpolated colours and cannot merge.
                Behavior on color {
                    enabled: !gaugeRoot.flatOpacity
                    ColorAnimation { duration: Theme.durationFast }
                }
            }
        }
    }
}
