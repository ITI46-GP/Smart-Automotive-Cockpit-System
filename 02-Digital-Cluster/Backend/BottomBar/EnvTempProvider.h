#ifndef ENVTEMPPROVIDER_H
#define ENVTEMPPROVIDER_H

#include <QObject>
#include <string>

class EnvTempProvider : public QObject
{
    Q_OBJECT
    Q_PROPERTY(qreal tempValue READ tempValue NOTIFY tempValueChanged FINAL)

public:
    explicit EnvTempProvider(std::string path, QObject *parent = nullptr);
    qreal tempValue() const;
    bool getValueFromFile();

private:
    qreal tempValue_ = 14.0;
    std::string filePath_;

signals:
    void tempValueChanged();
};

#endif // ENVTEMPPROVIDER_H
