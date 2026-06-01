pragma Singleton
import QtQuick

/*
 * GLOBAL THEME
 * ============
 * Centralized colors, fonts, and sizing for the entire cluster.
 *
 * USAGE in any QML file:
 *   import Digital_Cluster_DesignStudioContent.Content_Area
 *
 *   color: Theme.colorAccentPrimary
 *   font.family: Theme.fontPrimary
 *
 * To change the entire app's look, just modify the values here.
 */
QtObject {
    id: theme

    // ════════════════════════════════════════════════════
    //  COLOR PALETTE — based on IVI palette
    // ════════════════════════════════════════════════════

    // ── BACKGROUNDS ─────────────────────────────────────
    readonly property color colorBackgroundDeepest:  "#07000E"   // outermost background
    readonly property color colorBackgroundBase:     "#0A0A1B"   // gauge inner fill, main surface
    readonly property color colorBackgroundElevated: "#1C162B"   // cards, bezels
    readonly property color colorBackgroundActive:   "#201926"   // selected/active surface

    // ── ACCENT (Primary — RED) ──────────────────────────
    readonly property color colorAccentPrimary:      "#A6080D"   // main red
    readonly property color colorAccentBright:       "#E60914"   // brighter red (highlights, glow)
    readonly property color colorAccentDeep:         "#6B0509"   // darker red (shadows, depth)

    // ── TEXT ────────────────────────────────────────────
    readonly property color colorTextPrimary:        "#CBC4CD"   // off-white (main text)
    readonly property color colorTextSecondary:      "#8A8392"   // medium-bright (labels)
    readonly property color colorTextMuted:          "#5A535B"   // dim (tick marks, hints)

    // ── STATUS COLORS (universal) ───────────────────────
    readonly property color colorSuccess:            "#22D67E"   // green — "READY", check states
    readonly property color colorWarning:            "#FBBF24"   // amber — caution, near limit
    readonly property color colorDanger:             "#EF4444"   // bright red — critical

    // ── SPECIAL ─────────────────────────────────────────
    readonly property color colorIVIPurple:          "#8B5CF6"   // ONLY for IVI/AI feature links


    // ════════════════════════════════════════════════════
    //  TYPOGRAPHY
    // ════════════════════════════════════════════════════
    //  Change fontPrimary here to switch fonts everywhere.
    //  Make sure the font is loaded via FontLoader in App.qml.

    readonly property string fontPrimary:    "Kdam Thmor Pro"
    readonly property string fontSecondary:  "Inter"
    readonly property string fontMono:       "JetBrains Mono"

    // Font sizes
    readonly property int fontSizeHero:      96    // huge numbers (speed, RPM)
    readonly property int fontSizeXLarge:    48    // big numbers (gear, time)
    readonly property int fontSizeLarge:     24    // section headers
    readonly property int fontSizeMedium:    16    // body text
    readonly property int fontSizeSmall:     12    // labels
    readonly property int fontSizeTiny:      10    // mini labels (uppercase)

    // Font weights
    readonly property int fontWeightThin:       Font.Thin       // 100
    readonly property int fontWeightLight:      Font.Light      // 300
    readonly property int fontWeightRegular:    Font.Normal     // 400
    readonly property int fontWeightMedium:     Font.Medium     // 500
    readonly property int fontWeightBold:       Font.Bold       // 700


    // ════════════════════════════════════════════════════
    //  SHAPING & SPACING
    // ════════════════════════════════════════════════════

    readonly property int radiusSmall:   6
    readonly property int radiusMedium:  12
    readonly property int radiusLarge:   24
    readonly property int radiusPill:    9999

    readonly property int spacingTiny:    4
    readonly property int spacingSmall:   8
    readonly property int spacingMedium:  16
    readonly property int spacingLarge:   24
    readonly property int spacingXLarge:  40


    // ════════════════════════════════════════════════════
    //  ANIMATION TIMINGS
    // ════════════════════════════════════════════════════

    readonly property int durationFast:    150   // hover, quick reactions
    readonly property int durationNormal:  300   // most transitions
    readonly property int durationSlow:    600   // major view changes
}
