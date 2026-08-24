// S1 (revised) — Canvas eliminated. The frame art never changes at
// runtime (frameRadius/bezelWidth/etc. were design-time constants even in
// the original), so it's baked once to a PNG by
// tools/gen_bazel_frame.py (pycairo, mirrors the old Canvas paint code
// path-for-path) instead of drawn by a Canvas on the GUI thread.
//
// WHY THIS REPLACED THE CANVAS VERSION: the Canvas version painted only
// ONCE (Component.onCompleted), which the standing "no per-frame Canvas"
// rule treats as safe — but it still caused a one-time ~19s stall on the
// QNX guest AND a smaller ~4-5s stall on desktop, confirmed live via
// pidin: the render thread was blocked in REPLY from the QNX screen
// compositor while it (not our code) did first-time GPU work for this
// new texture/shader combination. Reproducing the same delay-shape on
// desktop (different GPU, no QNX screen/clusterStreaming at all) proves
// it's specifically triggered by this Canvas-backed texture, not QNX
// system contention. See PLAN.md "S1 finding" for the full trace.
//
// Lesson for the skill: "Canvas painted once = fine" is not the whole
// rule. If the content is genuinely static, prefer baking to an Image
// over Canvas entirely — it sidesteps this class of first-use GPU stall
// completely, because Image just samples an already-decoded texture
// through the same shader every other Image on screen already uses.

import QtQuick

Image {
    id: bezelFrame
    // Baked at 1280x720 (confirmed live via Main.qml's runtime
    // console.log — the QNX guest's real composited display, not the
    // 1024x600 we briefly and wrongly assumed) by tools/gen_bazel_frame.py.
    // This is just a fallback default for standalone use — call sites
    // should always bind width/height explicitly to their real container
    // size (see Main.qml: width/height bound to root.width/root.height,
    // which is itself bound to Screen.width/Screen.height, never a
    // literal). If a different board/panel turns out to have a different
    // real resolution, regenerate the PNG at that size
    // (tools/gen_bazel_frame.py, change BASE_W/BASE_H) rather than
    // stretching this one non-uniformly.
    width: 1280
    height: 720

    // Absolute qrc path via resources.qrc (CMAKE_AUTORCC), not a relative
    // "../../assets/..." path — a relative reference from a compiled QML
    // module's resource location resolved to the wrong directory at
    // runtime (missing a path segment vs. what the file was actually
    // embedded at), which is exactly the kind of qrc-path guessing game
    // an explicit qrc alias avoids.
    source: "qrc:/assets/BazelFrame.png"
    sourceSize: Qt.size(width, height)
    smooth: true
    mipmap: true

    // Properties kept for API compatibility with call sites that still
    // read them (none currently do at runtime since the art is baked,
    // but this avoids breaking bindings elsewhere in the tree).
    // NOTE: innerColor is now unused for actual rendering — the inside of
    // the bezel is baked fully transparent (tools/gen_bazel_frame.py punches
    // it out with OPERATOR_CLEAR after the ring is drawn), so whatever QML
    // content sits behind/inside BazelFrame shows through directly instead
    // of a baked dark panel.
    property real frameRadius: 200
    property real bezelWidth: 20
    property color innerColor: "#000000"
    property color bezelEdgeColor: "#15161a"
    property color bezelMidColor:  "#3a3b3f"
    property real bottomCurveWidth: 600
    property real bottomCurveDepth: 80
}
