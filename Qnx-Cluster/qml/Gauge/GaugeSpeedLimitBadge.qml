// Ported from 02-Digital-Cluster/Gauge/GaugeSpeedLimitBadge.qml. Road-sign
// style speed limit disc: white centre, red ring, black number, with a
// pulsing red glow while over the limit. Pure Rectangle+Text — the
// original's own comment already says "GPU rendered, no Canvas", so this
// ports directly with no rework needed.
import QtQuick
import QnxCluster

Item {
    id: badgeRoot

    property int  speedLimit: 0
    property real currentSpeed: 0
    property real speedingTolerance: 5

    property real badgeSize:   60
    property real borderWidth: 5

    property color backgroundColor:    Theme.colorTextPrimary
    property color borderColor:        Theme.colorAccentPrimary
    property color numberColor:        Theme.colorBackgroundDeepest
    property color violationGlowColor: Theme.colorDanger

    property string fontFamily: Theme.fontPrimary
    property int    fontWeight: Theme.fontWeightBold
    property int    fontSize:   badgeSize * 0.42

    property bool autoHide:           true
    property bool pulseWhenViolating: true

    readonly property bool isViolating:
        speedLimit > 0 && currentSpeed > (speedLimit + speedingTolerance)

    visible: !autoHide || speedLimit > 0
    width:  badgeSize
    height: badgeSize

    // Layer 1 — violation glow, only while speeding
    Rectangle {
        id: violationGlow
        anchors.centerIn: parent
        width:  badgeRoot.badgeSize + 30
        height: width
        radius: width / 2
        color: badgeRoot.violationGlowColor
        opacity: badgeRoot.isViolating ? 0.5 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: Theme.durationNormal }
        }
        SequentialAnimation on scale {
            running: badgeRoot.isViolating && badgeRoot.pulseWhenViolating
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 1.15; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.15; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
        }
    }

    // Layer 2 — red ring
    Rectangle {
        anchors.centerIn: parent
        width:  badgeRoot.badgeSize
        height: width
        radius: width / 2
        color: badgeRoot.borderColor
    }

    // Layer 3 — white disc
    Rectangle {
        anchors.centerIn: parent
        width:  badgeRoot.badgeSize - badgeRoot.borderWidth * 2
        height: width
        radius: width / 2
        color: badgeRoot.backgroundColor
    }

    // Layer 4 — number
    Text {
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
