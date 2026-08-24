// Diagnostic-trouble-code popup.
//
// Driven by VehicleData.dtc.activeMask, a bitmask the vehicle gateway
// publishes to /tmp/dtc.txt (see src/Backend/DtcProvider.h for the bit
// order, and the gateway's publish_cluster_files()). The code->text table
// lives here rather than in C++ so a wording change does not need a
// cross-compile.
//
// Behaviour:
//   - a fault becoming active raises a popup; the driver dismisses it
//   - a fault that clears while its popup is up dismisses it automatically,
//     because a warning the driver can no longer act on should not sit there
//   - several faults at once queue, most severe first, one at a time
//   - a dismissed fault does not come back while it stays active, but does
//     if it clears and recurs
import QtQuick
import QnxCluster

Item {
    id: faultPopup
    anchors.fill: parent
    visible: opacity > 0
    opacity: currentFault ? 1 : 0
    // Same z as ErrorDialog; declared after it in Main.qml so it paints
    // on top of it. Deliberately below SplashScreen (z 999) so a fault
    // arriving during the one-time boot play does not punch through it.
    z: 998

    // ── fault catalogue ───────────────────────────────
    // severity: 2 critical, 1 warning, 0 advisory. Effects are the real
    // system consequences, not invented text.
    readonly property var faults: [
        { bit: 1 << 0, code: "P0217", name: "Engine coolant over temperature",
          effect: "Air conditioning blocked, fans forced off", severity: 2 },
        { bit: 1 << 1, code: "P0118", name: "Coolant temp sensor 1 circuit high",
          effect: "Air conditioning open-loop, AI caller blocked", severity: 1 },
        { bit: 1 << 2, code: "P0300", name: "Random / multiple cylinder misfire",
          effect: "Fan derated to level 2", severity: 1 },
        { bit: 1 << 3, code: "P0442", name: "EVAP system small leak",
          effect: "Advisory only, no function affected", severity: 0 },
        { bit: 1 << 4, code: "P0562", name: "System voltage low",
          effect: "SAFE mode, all functions blocked", severity: 2 }
    ]

    property int activeMask: VehicleData.dtc ? VehicleData.dtc.activeMask : 0

    // Bits the driver has already dismissed. Cleared for any fault that goes
    // away, so a recurrence pops again instead of being silently swallowed.
    property int acknowledgedMask: 0

    readonly property int pendingMask: activeMask & ~acknowledgedMask

    // Highest-severity pending fault, or null. Ties break on catalogue order.
    readonly property var currentFault: {
        var best = null
        for (var i = 0; i < faults.length; ++i) {
            var f = faults[i]
            if ((pendingMask & f.bit) === 0)
                continue
            if (best === null || f.severity > best.severity)
                best = f
        }
        return best
    }

    // Severity presentation is derived through functions rather than read
    // from sibling bindings. A change handler that reads another binding of
    // the same source can see the previous value -- onCurrentFaultChanged
    // logged "P0217 (ADVISORY)" (P0442's label, one update behind) until
    // this was split out. Calling the function always evaluates now.
    function severityNameOf(f) {
        if (!f) return ""
        return f.severity === 2 ? "CRITICAL"
             : f.severity === 1 ? "WARNING"
             : "ADVISORY"
    }
    function severityColourOf(f) {
        if (!f) return Theme.colorTextMuted
        return f.severity === 2 ? Theme.colorDanger
             : f.severity === 1 ? Theme.colorWarning
             : Theme.colorAccentPrimary
    }
    // Reads activeMask/acknowledgedMask, so bindings that call it still track
    // them and re-evaluate correctly.
    function pendingCount() {
        var m = activeMask & ~acknowledgedMask
        var n = 0
        for (var i = 0; i < faults.length; ++i)
            if ((m & faults[i].bit) !== 0)
                ++n
        return n
    }

    readonly property color severityColour: severityColourOf(currentFault)
    readonly property string severityLabel: severityNameOf(currentFault)

    // Count of faults still waiting behind this one.
    readonly property int queuedBehind: Math.max(0, pendingCount() - 1)

    onActiveMaskChanged: {
        // Forget acknowledgements for faults that are no longer active.
        acknowledgedMask = acknowledgedMask & activeMask
    }

    // Same reasoning as Main.qml's logIndicators(): this cluster has no
    // attached panel, so without a log line there is no way to confirm from
    // the board that a fault actually reached the screen.
    onCurrentFaultChanged: {
        if (currentFault)
            console.log("[FaultPopup] showing " + currentFault.code
                        + " (" + severityNameOf(currentFault) + ") queued="
                        + Math.max(0, pendingCount() - 1))
        else
            console.log("[FaultPopup] cleared")
    }

    function dismissCurrent() {
        if (currentFault)
            acknowledgedMask |= currentFault.bit
    }

    Behavior on opacity { NumberAnimation { duration: Theme.durationNormal } }

    // dim background, eats clicks so they don't reach the UI underneath
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.55
        MouseArea { anchors.fill: parent }
    }

    Rectangle {
        width: 460
        height: 236
        radius: Theme.radiusLarge
        color: Theme.colorBackgroundElevated
        border.color: faultPopup.severityColour
        border.width: 2
        anchors.centerIn: parent

        Column {
            anchors.centerIn: parent
            spacing: Theme.spacingSmall
            width: parent.width - 56

            // severity chip + DTC code
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacingSmall

                Rectangle {
                    width: severityText.implicitWidth + 20
                    height: 24
                    radius: Theme.radiusPill
                    color: faultPopup.severityColour
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        id: severityText
                        anchors.centerIn: parent
                        text: faultPopup.severityLabel
                        color: Theme.colorBackgroundElevated
                        font.family: Theme.fontSecondary
                        font.pixelSize: Theme.fontSizeTiny
                        font.bold: true
                    }
                }

                Text {
                    text: faultPopup.currentFault ? faultPopup.currentFault.code : ""
                    color: Theme.colorTextPrimary
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeLarge
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Text {
                width: parent.width
                text: faultPopup.currentFault ? faultPopup.currentFault.name : ""
                color: Theme.colorTextPrimary
                font.family: Theme.fontPrimary
                font.pixelSize: Theme.fontSizeMedium
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: parent.width
                text: faultPopup.currentFault ? faultPopup.currentFault.effect : ""
                color: Theme.colorTextSecondary
                font.family: Theme.fontSecondary
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: parent.width
                visible: faultPopup.queuedBehind > 0
                text: faultPopup.queuedBehind === 1
                      ? "1 more fault" : faultPopup.queuedBehind + " more faults"
                color: Theme.colorTextMuted
                font.family: Theme.fontSecondary
                font.pixelSize: Theme.fontSizeTiny
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 120; height: 36; radius: Theme.radiusPill
                color: Theme.colorBackgroundActive
                border.color: Theme.colorTextMuted
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    // The cluster has no touchscreen on the bench, so say
                    // which wheel button clears it.
                    text: "OK"
                    color: Theme.colorTextPrimary
                    font.family: Theme.fontSecondary
                    font.pixelSize: Theme.fontSizeSmall
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: faultPopup.dismissCurrent()
                }
            }
        }
    }
}
