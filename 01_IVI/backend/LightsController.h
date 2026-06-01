#ifndef LIGHTSCONTROLLER_H
#define LIGHTSCONTROLLER_H

#include <QObject>

class LightsController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool headlightsOn READ headlightsOn WRITE setHeadlightsOn NOTIFY headlightsOnChanged)
    Q_PROPERTY(bool fogLightsOn READ fogLightsOn WRITE setFogLightsOn NOTIFY fogLightsOnChanged)
    Q_PROPERTY(bool cabinAmbientOn READ cabinAmbientOn WRITE setCabinAmbientOn NOTIFY cabinAmbientOnChanged)
    Q_PROPERTY(bool autoLightsOn READ autoLightsOn WRITE setAutoLightsOn NOTIFY autoLightsOnChanged)
    Q_PROPERTY(int ambientLevel READ ambientLevel WRITE setAmbientLevel NOTIFY ambientLevelChanged)

public:
    explicit LightsController(QObject *parent = nullptr);

    bool headlightsOn() const;
    bool fogLightsOn() const;
    bool cabinAmbientOn() const;
    bool autoLightsOn() const;
    int ambientLevel() const;

    Q_INVOKABLE void toggleHeadlights();
    Q_INVOKABLE void toggleFogLights();
    Q_INVOKABLE void toggleCabinAmbient();
    Q_INVOKABLE void toggleAutoLights();
    Q_INVOKABLE void increaseAmbientLevel();
    Q_INVOKABLE void decreaseAmbientLevel();

public slots:
    void setHeadlightsOn(bool on);
    void setFogLightsOn(bool on);
    void setCabinAmbientOn(bool on);
    void setAutoLightsOn(bool on);
    void setAmbientLevel(int level);

signals:
    void headlightsOnChanged();
    void fogLightsOnChanged();
    void cabinAmbientOnChanged();
    void autoLightsOnChanged();
    void ambientLevelChanged();

private:
    void load();
    void save() const;

    bool m_headlightsOn = true;
    bool m_fogLightsOn = false;
    bool m_cabinAmbientOn = true;
    bool m_autoLightsOn = true;
    int m_ambientLevel = 64;
};

#endif // LIGHTSCONTROLLER_H
