// Ported verbatim from 02-Digital-Cluster/Backend/BottomBar/EngineTempProvider.h.
#pragma once

#include <QObject>
#include <string>

class EngineTempProvider : public QObject
{
    Q_OBJECT
    Q_PROPERTY(qreal tempValue READ tempValue NOTIFY tempValueChanged FINAL)

public:
    explicit EngineTempProvider(std::string path, QObject *parent = nullptr);
    qreal tempValue() const;
    bool getValueFromFile();

private:
    qreal tempValue_ = 90.0;
    std::string filePath_;

signals:
    void tempValueChanged();
};
