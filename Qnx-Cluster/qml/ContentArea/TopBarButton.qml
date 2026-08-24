// Ported from 02-Digital-Cluster/Digital_Cluster_DesignStudioContent/
// Content_Area/TopBarButton.qml — a pill Rectangle with a centred icon.
// No Canvas, no DesignEffect. Changes from the original:
//
//   * `sourceSize` on the Image. Standing project rule; the source PNGs were
//     512x512 for a 22x22 icon, which decoded ~1 MB of texture each. The files
//     themselves are now 96x96 (tools/gen_icons.py) and this caps the decode.
//   * qrc alias paths instead of relative "../assets/..." — a relative path
//     from inside a compiled QML module resolved to the wrong directory in S1.
//
// PERFORMANCE NOTE / PREDICTION FOR THIS STAGE: distinct textures cannot be
// merged into one batch, and on this board a batch costs ~0.5 ms. Six buttons
// with six different icons plus two arrows means ~8 textures, which the S7
// model predicts will cost ~8 batches / ~4 ms. If S7.5 regresses by about that
// much, the model is right and the fix is a sprite atlas (one texture, each
// icon selected with `sourceClipRect`) rather than anything about the buttons
// themselves. Stated up front so the measurement tests a prediction instead of
// generating another retrospective explanation.

import QtQuick

Rectangle {
    id: btn
    width: 60
    height: 38
    radius: 19
    color: selected ? "#ffffff" : "transparent"

    property url iconSourceunSelected: ""
    property url iconSourceSelected: ""
    property int iconSize: 20
    property bool selected: false

    // See the note on the Image below.
    property bool useMipmap: false

    signal clicked()

    Image {
        id: iconImage
        anchors.centerIn: parent
        width: btn.iconSize
        height: btn.iconSize
        source: btn.selected ? btn.iconSourceSelected : btn.iconSourceunSelected
        sourceSize: Qt.size(btn.iconSize, btn.iconSize)
        fillMode: Image.PreserveAspectFit
        smooth: true

        // ── WHY mipmap IS OFF (S7.5 finding) ──
        // Qt Quick packs small images into a SHARED texture atlas, and images
        // that land in that atlas can be merged into a single batch.
        // `mipmap: true` opts an image OUT of the atlas onto its own dedicated
        // texture, because mipmapping needs a texture of its own. Every icon
        // inherited mipmap from the original, so eight icons meant eight
        // textures and eight batches — measured: adding this top bar took the
        // batch count 21 -> 30 and render 12 -> 16 ms, matching the prediction
        // written down beforehand (~+8 batches / ~+4 ms at ~0.5 ms each).
        //
        // Mipmapping is not needed here anyway: `sourceSize` already decodes
        // at display size, so there is no minification left for mip levels to
        // improve. `--icon-mipmap` restores it for comparison.
        mipmap: btn.useMipmap
    }

    MouseArea {
        anchors.fill: parent
        onClicked: btn.clicked()
    }

    Behavior on color {
        ColorAnimation { duration: 200 }
    }
}
