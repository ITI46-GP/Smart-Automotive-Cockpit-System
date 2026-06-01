#include <QtQml/qqmlprivate.h>
#include <QtCore/qdir.h>
#include <QtCore/qurl.h>
#include <QtCore/qhash.h>
#include <QtCore/qstring.h>

namespace QmlCacheGeneratedCode {
namespace _qt_qml_Digital_Cluster_DesignStudioContent_App_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Digital_Cluster_DesignStudioContent_BazelFrame_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Digital_Cluster_DesignStudioContent_Indicator_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Digital_Cluster_DesignStudioContent_RPMGauge_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Digital_Cluster_DesignStudioContent_Screen01_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Digital_Cluster_DesignStudioContent_SpeedGauge_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Digital_Cluster_DesignStudioContent_SplashScreen_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Digital_Cluster_DesignStudioContent_TempSlider_qml { 
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
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Digital_Cluster_DesignStudioContent/App.qml"), &QmlCacheGeneratedCode::_qt_qml_Digital_Cluster_DesignStudioContent_App_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Digital_Cluster_DesignStudioContent/BazelFrame.qml"), &QmlCacheGeneratedCode::_qt_qml_Digital_Cluster_DesignStudioContent_BazelFrame_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Digital_Cluster_DesignStudioContent/Indicator.qml"), &QmlCacheGeneratedCode::_qt_qml_Digital_Cluster_DesignStudioContent_Indicator_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Digital_Cluster_DesignStudioContent/RPMGauge.qml"), &QmlCacheGeneratedCode::_qt_qml_Digital_Cluster_DesignStudioContent_RPMGauge_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Digital_Cluster_DesignStudioContent/Screen01.qml"), &QmlCacheGeneratedCode::_qt_qml_Digital_Cluster_DesignStudioContent_Screen01_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Digital_Cluster_DesignStudioContent/SpeedGauge.qml"), &QmlCacheGeneratedCode::_qt_qml_Digital_Cluster_DesignStudioContent_SpeedGauge_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Digital_Cluster_DesignStudioContent/SplashScreen.qml"), &QmlCacheGeneratedCode::_qt_qml_Digital_Cluster_DesignStudioContent_SplashScreen_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Digital_Cluster_DesignStudioContent/TempSlider.qml"), &QmlCacheGeneratedCode::_qt_qml_Digital_Cluster_DesignStudioContent_TempSlider_qml::unit);
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
int QT_MANGLE_NAMESPACE(qInitResources_qmlcache_Digital_Cluster_DesignStudioContent)() {
    ::unitRegistry();
    return 1;
}
Q_CONSTRUCTOR_FUNCTION(QT_MANGLE_NAMESPACE(qInitResources_qmlcache_Digital_Cluster_DesignStudioContent))
int QT_MANGLE_NAMESPACE(qCleanupResources_qmlcache_Digital_Cluster_DesignStudioContent)() {
    return 1;
}
