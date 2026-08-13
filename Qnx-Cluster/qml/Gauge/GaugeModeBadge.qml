// Ported from 02-Digital-Cluster/Gauge/GaugeModeBadge.qml. Pill badge for
// ECO/NORMAL/SPORT. Pure Rectangle+Text, no Canvas/DesignEffect/assets.
import QtQuick
import QnxCluster

Item {
    id: badgeRoot

    property string mode: "NORMAL"

    property real badgeHeight: 28
    property real badgeRadius: 6
    property real paddingH:    14
    property real paddingV:    4

    property string fontFamily: Theme.fontPrimary
    property int    fontSize:   14
    property int    fontWeight: Theme.fontWeightBold
    property real   letterSpacing: 2

    property color colorEco:    Theme.colorSuccess
    property color colorNormal: Theme.colorTextPrimary
    property color colorSport:  Theme.colorAccentPrimary
    property color colorTextEco:    Theme.colorBackgroundDeepest
    property color colorTextNormal: Theme.colorBackgroundDeepest
    property color colorTextSport:  Theme.colorTextPrimary

    readonly property string normalizedMode: mode.toUpperCase()

    readonly property color bgColor: {
        if (normalizedMode === "ECO")   return colorEco
        if (normalizedMode === "SPORT") return colorSport
        return colorNormal
    }
    readonly property color textColor: {
        if (normalizedMode === "ECO")   return colorTextEco
        if (normalizedMode === "SPORT") return colorTextSport
        return colorTextNormal
    }

    implicitWidth:  modeText.implicitWidth + paddingH * 2
    implicitHeight: badgeHeight

    Rectangle {
        id: bgPill
        anchors.fill: parent
        radius: badgeRoot.badgeRadius
        color: badgeRoot.bgColor
        Behavior on color {
            ColorAnimation { duration: Theme.durationNormal }
        }
        border.color: Qt.darker(badgeRoot.bgColor, 1.4)
        border.width: 1
    }

    Text {
        id: modeText
        anchors.centerIn: parent
        text: badgeRoot.normalizedMode
        color: badgeRoot.textColor
        Behavior on color {
            ColorAnimation { duration: Theme.durationNormal }
        }
        font.family:        badgeRoot.fontFamily
        font.pixelSize:     badgeRoot.fontSize
        font.weight:        badgeRoot.fontWeight
        font.letterSpacing: badgeRoot.letterSpacing
    }
}
