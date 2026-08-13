// Copyright (C) 2026 Hyper-Nova Cockpit
// SPDX-License-Identifier: GPL-3.0-only
//
// Theme, as a real C++ QML_SINGLETON, not a QML-authored "pragma Singleton"
// file. Two attempts at the QML-side singleton mechanism (module auto-
// registration from pragma text, then a C++-loaded context property)
// both silently failed — every Theme.* reference in consuming QML kept
// resolving to `undefined` at runtime with zero build errors, on both
// the desktop kit and the QNX target, across full clean reconfigures.
// This is the same pattern the OLD Digital_Cluster_DesignStudioApp used
// successfully for its Backend singletons (VehicleData, SpeedProvider,
// etc. via qmlRegisterSingletonInstance/qmlRegisterUncreatableType from
// main.cpp) — a proven-working registration path in this exact codebase,
// instead of a third guess at the QML-only mechanism.
//
// Values ported verbatim from
// 02-Digital-Cluster/Digital_Cluster_DesignStudio/Theme.qml.

#pragma once

#include <QObject>
#include <QColor>
#include <QFont>
#include <qqml.h>

class Theme : public QObject
{
    Q_OBJECT
    QML_NAMED_ELEMENT(Theme)
    QML_SINGLETON

    // ── BACKGROUNDS ─────────────────────────────────────
    Q_PROPERTY(QColor colorBackgroundDeepest  READ colorBackgroundDeepest  CONSTANT)
    Q_PROPERTY(QColor colorBackgroundBase     READ colorBackgroundBase     CONSTANT)
    Q_PROPERTY(QColor colorBackgroundElevated READ colorBackgroundElevated CONSTANT)
    Q_PROPERTY(QColor colorBackgroundActive   READ colorBackgroundActive   CONSTANT)

    // ── ACCENT (Primary — RED) ──────────────────────────
    Q_PROPERTY(QColor colorAccentPrimary READ colorAccentPrimary CONSTANT)
    Q_PROPERTY(QColor colorAccentBright  READ colorAccentBright  CONSTANT)
    Q_PROPERTY(QColor colorAccentDeep    READ colorAccentDeep    CONSTANT)

    // ── TEXT ────────────────────────────────────────────
    Q_PROPERTY(QColor colorTextPrimary   READ colorTextPrimary   CONSTANT)
    Q_PROPERTY(QColor colorTextSecondary READ colorTextSecondary CONSTANT)
    Q_PROPERTY(QColor colorTextMuted     READ colorTextMuted     CONSTANT)

    // ── STATUS COLORS ────────────────────────────────────
    Q_PROPERTY(QColor colorSuccess READ colorSuccess CONSTANT)
    Q_PROPERTY(QColor colorWarning READ colorWarning CONSTANT)
    Q_PROPERTY(QColor colorDanger  READ colorDanger  CONSTANT)

    // ── SPECIAL ─────────────────────────────────────────
    Q_PROPERTY(QColor colorIVIPurple READ colorIVIPurple CONSTANT)

    // ── TYPOGRAPHY ────────────────────────────────────────
    Q_PROPERTY(QString fontPrimary   READ fontPrimary   CONSTANT)
    Q_PROPERTY(QString fontSecondary READ fontSecondary CONSTANT)
    Q_PROPERTY(QString fontMono      READ fontMono      CONSTANT)

    Q_PROPERTY(int fontSizeHero   READ fontSizeHero   CONSTANT)
    Q_PROPERTY(int fontSizeXLarge READ fontSizeXLarge CONSTANT)
    Q_PROPERTY(int fontSizeLarge  READ fontSizeLarge  CONSTANT)
    Q_PROPERTY(int fontSizeMedium READ fontSizeMedium CONSTANT)
    Q_PROPERTY(int fontSizeSmall  READ fontSizeSmall  CONSTANT)
    Q_PROPERTY(int fontSizeTiny   READ fontSizeTiny   CONSTANT)

    Q_PROPERTY(int fontWeightThin    READ fontWeightThin    CONSTANT)
    Q_PROPERTY(int fontWeightLight   READ fontWeightLight   CONSTANT)
    Q_PROPERTY(int fontWeightRegular READ fontWeightRegular CONSTANT)
    Q_PROPERTY(int fontWeightMedium  READ fontWeightMedium  CONSTANT)
    Q_PROPERTY(int fontWeightBold    READ fontWeightBold    CONSTANT)

    // ── SHAPING & SPACING ─────────────────────────────────
    Q_PROPERTY(int radiusSmall  READ radiusSmall  CONSTANT)
    Q_PROPERTY(int radiusMedium READ radiusMedium CONSTANT)
    Q_PROPERTY(int radiusLarge  READ radiusLarge  CONSTANT)
    Q_PROPERTY(int radiusPill   READ radiusPill   CONSTANT)

    Q_PROPERTY(int spacingTiny   READ spacingTiny   CONSTANT)
    Q_PROPERTY(int spacingSmall  READ spacingSmall  CONSTANT)
    Q_PROPERTY(int spacingMedium READ spacingMedium CONSTANT)
    Q_PROPERTY(int spacingLarge  READ spacingLarge  CONSTANT)
    Q_PROPERTY(int spacingXLarge READ spacingXLarge CONSTANT)

    // ── ANIMATION TIMINGS ─────────────────────────────────
    Q_PROPERTY(int durationFast   READ durationFast   CONSTANT)
    Q_PROPERTY(int durationNormal READ durationNormal CONSTANT)
    Q_PROPERTY(int durationSlow   READ durationSlow   CONSTANT)

public:
    explicit Theme(QObject *parent = nullptr) : QObject(parent) {}

    QColor colorBackgroundDeepest()  const { return QColor(QStringLiteral("#07000E")); }
    QColor colorBackgroundBase()     const { return QColor(QStringLiteral("#0A0A1B")); }
    QColor colorBackgroundElevated() const { return QColor(QStringLiteral("#1C162B")); }
    QColor colorBackgroundActive()   const { return QColor(QStringLiteral("#201926")); }

    QColor colorAccentPrimary() const { return QColor(QStringLiteral("#A6080D")); }
    QColor colorAccentBright()  const { return QColor(QStringLiteral("#E60914")); }
    QColor colorAccentDeep()    const { return QColor(QStringLiteral("#6B0509")); }

    QColor colorTextPrimary()   const { return QColor(QStringLiteral("#CBC4CD")); }
    QColor colorTextSecondary() const { return QColor(QStringLiteral("#8A8392")); }
    QColor colorTextMuted()     const { return QColor(QStringLiteral("#5A535B")); }

    QColor colorSuccess() const { return QColor(QStringLiteral("#22D67E")); }
    QColor colorWarning() const { return QColor(QStringLiteral("#FBBF24")); }
    QColor colorDanger()  const { return QColor(QStringLiteral("#EF4444")); }

    QColor colorIVIPurple() const { return QColor(QStringLiteral("#8B5CF6")); }

    QString fontPrimary()   const { return QStringLiteral("Kdam Thmor Pro"); }
    QString fontSecondary() const { return QStringLiteral("Inter"); }
    QString fontMono()      const { return QStringLiteral("JetBrains Mono"); }

    int fontSizeHero()   const { return 96; }
    int fontSizeXLarge() const { return 48; }
    int fontSizeLarge()  const { return 24; }
    int fontSizeMedium() const { return 16; }
    int fontSizeSmall()  const { return 12; }
    int fontSizeTiny()   const { return 10; }

    int fontWeightThin()    const { return QFont::Thin; }
    int fontWeightLight()   const { return QFont::Light; }
    int fontWeightRegular() const { return QFont::Normal; }
    int fontWeightMedium()  const { return QFont::Medium; }
    int fontWeightBold()    const { return QFont::Bold; }

    int radiusSmall()  const { return 6; }
    int radiusMedium() const { return 12; }
    int radiusLarge()  const { return 24; }
    int radiusPill()   const { return 9999; }

    int spacingTiny()   const { return 4; }
    int spacingSmall()  const { return 8; }
    int spacingMedium() const { return 16; }
    int spacingLarge()  const { return 24; }
    int spacingXLarge() const { return 40; }

    int durationFast()   const { return 150; }
    int durationNormal() const { return 300; }
    int durationSlow()   const { return 600; }
};
