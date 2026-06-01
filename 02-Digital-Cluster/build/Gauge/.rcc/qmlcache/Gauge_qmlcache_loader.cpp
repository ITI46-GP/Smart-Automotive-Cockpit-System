#include <QtQml/qqmlprivate.h>
#include <QtCore/qdir.h>
#include <QtCore/qurl.h>
#include <QtCore/qhash.h>
#include <QtCore/qstring.h>

namespace QmlCacheGeneratedCode {
namespace _qt_qml_Gauge_GaugeActiveArc_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Gauge_GaugeGearBadge_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Gauge_GaugeInnerDisc_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Gauge_GaugeLabels_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Gauge_GaugeModeBadge_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Gauge_GaugeNeedle_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Gauge_GaugeRedlineZone_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Gauge_GaugeSpeedLimitBadge_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Gauge_GaugeSpeedNumber_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Gauge_GaugeTickMarks_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}

}
namespace {
struct Registry {
    Registry();
    ~Registry();
    QHash<QString, const QQmlPrivate::CachedQmlUnit*> resourcePathToCachedUnit;
    static const QQmlPrivate::CachedQmlUnit *lookupCachedUnit(const QUrl &url);
};

Q_GLOBAL_STATIC(Registry, unitRegistry)


Registry::Registry() {
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Gauge/GaugeActiveArc.qml"), &QmlCacheGeneratedCode::_qt_qml_Gauge_GaugeActiveArc_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Gauge/GaugeGearBadge.qml"), &QmlCacheGeneratedCode::_qt_qml_Gauge_GaugeGearBadge_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Gauge/GaugeInnerDisc.qml"), &QmlCacheGeneratedCode::_qt_qml_Gauge_GaugeInnerDisc_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Gauge/GaugeLabels.qml"), &QmlCacheGeneratedCode::_qt_qml_Gauge_GaugeLabels_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Gauge/GaugeModeBadge.qml"), &QmlCacheGeneratedCode::_qt_qml_Gauge_GaugeModeBadge_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Gauge/GaugeNeedle.qml"), &QmlCacheGeneratedCode::_qt_qml_Gauge_GaugeNeedle_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Gauge/GaugeRedlineZone.qml"), &QmlCacheGeneratedCode::_qt_qml_Gauge_GaugeRedlineZone_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Gauge/GaugeSpeedLimitBadge.qml"), &QmlCacheGeneratedCode::_qt_qml_Gauge_GaugeSpeedLimitBadge_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Gauge/GaugeSpeedNumber.qml"), &QmlCacheGeneratedCode::_qt_qml_Gauge_GaugeSpeedNumber_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Gauge/GaugeTickMarks.qml"), &QmlCacheGeneratedCode::_qt_qml_Gauge_GaugeTickMarks_qml::unit);
    QQmlPrivate::RegisterQmlUnitCacheHook registration;
    registration.structVersion = 0;
    registration.lookupCachedQmlUnit = &lookupCachedUnit;
    QQmlPrivate::qmlregister(QQmlPrivate::QmlUnitCacheHookRegistration, &registration);
}

Registry::~Registry() {
    QQmlPrivate::qmlunregister(QQmlPrivate::QmlUnitCacheHookRegistration, quintptr(&lookupCachedUnit));
}

const QQmlPrivate::CachedQmlUnit *Registry::lookupCachedUnit(const QUrl &url) {
    if (url.scheme() != QLatin1String("qrc"))
        return nullptr;
    QString resourcePath = QDir::cleanPath(url.path());
    if (resourcePath.isEmpty())
        return nullptr;
    if (!resourcePath.startsWith(QLatin1Char('/')))
        resourcePath.prepend(QLatin1Char('/'));
    return unitRegistry()->resourcePathToCachedUnit.value(resourcePath, nullptr);
}
}
int QT_MANGLE_NAMESPACE(qInitResources_qmlcache_Gauge)() {
    ::unitRegistry();
    return 1;
}
Q_CONSTRUCTOR_FUNCTION(QT_MANGLE_NAMESPACE(qInitResources_qmlcache_Gauge))
int QT_MANGLE_NAMESPACE(qCleanupResources_qmlcache_Gauge)() {
    return 1;
}
