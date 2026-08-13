// S7.5 — ported from 02-Digital-Cluster/Digital_Cluster_DesignStudioContent/
// Content_Area/TopBar.qml: two turn indicators either side of a pill bar
// holding six view-selector buttons.
//
// ── WHAT CHANGED FROM THE ORIGINAL ──
//   * qrc alias paths rather than relative "../assets/..." (the S1 trap).
//   * `sourceSize` on the arrow Images (standing rule).
//   * Icon PNGs downscaled 512x512 -> 96x96 offline (tools/gen_icons.py).
//   * `viewSelected` is still emitted, but nothing consumes it yet — the view
//     switching arrives with the ContentArea stages. The buttons are live so
//     the selected-state colour Behavior is exercised and measured.
//
// The blinking turn-indicator animation is kept: it is a continuous animation
// and therefore part of the honest worst case for this stage.
//
// ── S10 — the three shadows, added now ──
// The original has three `DesignEffect` drop shadows: one on each turn
// indicator (a green glow when lit) and one under the main bar. S7.5 left
// them out deliberately (see PLAN.md) because `layer.enabled`-style effects
// force an offscreen pass, and this board is already proven to punish extra
// blended coverage (S6: 130 overlapping ticks cost 37 ms vs 11 ms
// non-overlapping). This is the NAIVE, faithful port — `QtQuick.Effects`'
// `MultiEffect` in place of the Studio-only `DesignEffect`/`DesignDropShadow`
// (this rebuild doesn't depend on QtQuick.Studio.DesignEffects), same
// shadow on the same three items, no baking or other optimisation yet.
// "Guilty until proven innocent," per PLAN.md's own S10 note — measure
// first, then decide whether/how to fix. Each shadow gets its own flag so a
// bisect doesn't need a guess: `--no-shadow-pill` / `--no-shadow-leftglow` /
// `--no-shadow-rightglow`.

import QtQuick
import QtQuick.Effects

Item {
    id: topBarRoot
    width: topBar.width + 160
    height: 60

    property int currentView: 0

    // turning indicators
    property bool leftIndicatorOn: true
    property bool rightIndicatorOn: false

    signal viewSelected(int index)

    // See TopBarButton.qml: mipmap forces an image out of Qt's shared texture
    // atlas and therefore out of shared batches.
    property bool useMipmap: false

    // S10 isolation flags — see the file header. All default on (faithful
    // port); each maps to one of the original's three DesignEffects.
    property bool showPillShadow: true
    property bool showLeftGlow: true
    property bool showRightGlow: true

    // ── LEFT TURN INDICATOR ───────────────────────────
    Rectangle {
        id: leftIndicator
        width: 50
        height: 50
        radius: 25

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 0

        color: topBarRoot.leftIndicatorOn ? "#20ff55" : "#15151f"
        border.color: topBarRoot.leftIndicatorOn ? "#60ff88" : "#2a2a3a"
        border.width: 1

        // Original: DesignDropShadow { color:"#20ff55" blur:20 spread:2 },
        // visible only when leftIndicatorOn. MultiEffect's shadowBlur is
        // normalised 0-1, not the same scale as DesignDropShadow's pixel
        // blur -- picked a value that looks like a soft glow, not tuned
        // further since this stage is about measuring the offscreen pass,
        // not matching the original's exact softness.
        layer.enabled: topBarRoot.showLeftGlow && topBarRoot.leftIndicatorOn
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#20ff55"
            shadowBlur: 0.6
            shadowScale: 1.08
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
        }

        Image {
            id: leftArrow
            anchors.centerIn: parent
            width: 50
            height: 35
            source: "qrc:/icons/left-arrow.png"
            sourceSize: Qt.size(50, 35)
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: topBarRoot.useMipmap
            opacity: topBarRoot.leftIndicatorOn ? 1.0 : 0.3
        }

        // blinking animation (circle and arrow blink together)
        SequentialAnimation on opacity {
            running: topBarRoot.leftIndicatorOn
            loops: Animation.Infinite

            NumberAnimation { from: 1.0; to: 0.35; duration: 450 }
            NumberAnimation { from: 0.35; to: 1.0; duration: 450 }
        }
    }

    // ── MAIN TOP BAR ──────────────────────────────────
    Rectangle {
        id: topBar
        width: 420
        height: 50
        radius: 25
        color: "#15151f"
        border.color: "#2a2a3a"
        border.width: 1

        anchors.centerIn: parent

        // Original: DesignDropShadow { color:"#000000" blur:18 offsetY:4 },
        // always on (no visibility condition) -- an ordinary "elevated
        // card" shadow under a shape that itself never changes at runtime.
        // That stationariness is exactly what "bake it" (S1, S8, S9) would
        // apply to, once this is proven to actually cost anything.
        layer.enabled: topBarRoot.showPillShadow
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#000000"
            shadowBlur: 0.5
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 4
        }

        Row {
            anchors.centerIn: parent
            spacing: 8

            TopBarButton {
                id: carIcon
                iconSourceunSelected: "qrc:/icons/car_icon_unselected.png"
                iconSourceSelected:   "qrc:/icons/car_icon.png"
                iconSize: 22
                useMipmap: topBarRoot.useMipmap
                selected: topBarRoot.currentView === 0
                onClicked: topBarRoot.viewSelected(0)
            }

            TopBarButton {
                id: navigationIcon
                iconSourceunSelected: "qrc:/icons/navigation_icon_unselected.png"
                iconSourceSelected:   "qrc:/icons/navigation_icon_selected.png"
                iconSize: 22
                useMipmap: topBarRoot.useMipmap
                selected: topBarRoot.currentView === 1
                onClicked: topBarRoot.viewSelected(1)
            }

            TopBarButton {
                id: contactIcon
                iconSourceunSelected: "qrc:/icons/contacts_icon_unselected.png"
                iconSourceSelected:   "qrc:/icons/contacts_icon_selected.png"
                iconSize: 22
                useMipmap: topBarRoot.useMipmap
                selected: topBarRoot.currentView === 2
                onClicked: topBarRoot.viewSelected(2)
            }

            TopBarButton {
                id: musicIcon
                iconSourceunSelected: "qrc:/icons/music_icon_unselected.png"
                iconSourceSelected:   "qrc:/icons/music_icon_selected.png"
                iconSize: 22
                useMipmap: topBarRoot.useMipmap
                selected: topBarRoot.currentView === 3
                onClicked: topBarRoot.viewSelected(3)
            }

            TopBarButton {
                id: fuelIcon
                iconSourceunSelected: "qrc:/icons/fuel_icon_unselected.png"
                iconSourceSelected:   "qrc:/icons/fuel_icon_selected.png"
                iconSize: 22
                useMipmap: topBarRoot.useMipmap
                selected: topBarRoot.currentView === 4
                onClicked: topBarRoot.viewSelected(4)
            }

            TopBarButton {
                id: settingsIcon
                iconSourceunSelected: "qrc:/icons/settings_icon_unselected.png"
                iconSourceSelected:   "qrc:/icons/settings_icon_selected.png"
                iconSize: 22
                useMipmap: topBarRoot.useMipmap
                selected: topBarRoot.currentView === 5
                onClicked: topBarRoot.viewSelected(5)
            }
        }
    }

    // ── RIGHT TURN INDICATOR ──────────────────────────
    Rectangle {
        id: rightIndicator
        width: 50
        height: 50
        radius: 25

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 0

        color: topBarRoot.rightIndicatorOn ? "#20ff55" : "#15151f"
        border.color: topBarRoot.rightIndicatorOn ? "#60ff88" : "#2a2a3a"
        border.width: 1

        // Same as leftIndicator's glow, mirrored. rightIndicatorOn defaults
        // false, so this is OFF in the default idle state -- only the pill
        // shadow and the left glow are "on" by default, matching the
        // original's defaults (leftIndicatorOn:true, rightIndicatorOn:false).
        layer.enabled: topBarRoot.showRightGlow && topBarRoot.rightIndicatorOn
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#20ff55"
            shadowBlur: 0.6
            shadowScale: 1.08
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
        }

        Image {
            id: rightArrow
            anchors.centerIn: parent
            width: 50
            height: 35
            source: "qrc:/icons/right-arrow.png"
            sourceSize: Qt.size(50, 35)
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: topBarRoot.useMipmap
            opacity: topBarRoot.rightIndicatorOn ? 1.0 : 0.3
        }

        SequentialAnimation on opacity {
            running: topBarRoot.rightIndicatorOn
            loops: Animation.Infinite

            NumberAnimation { from: 1.0; to: 0.35; duration: 450 }
            NumberAnimation { from: 0.35; to: 1.0; duration: 450 }
        }
    }
}
