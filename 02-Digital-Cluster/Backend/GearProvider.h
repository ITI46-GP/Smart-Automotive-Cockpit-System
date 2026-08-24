#ifndef GEARPROVIDER_H
#define GEARPROVIDER_H

#include <QObject>
#include <QString>

class GearProvider : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString gearValue READ gearValue NOTIFY gearValueChanged FINAL)

public:
    explicit GearProvider(QObject *parent = nullptr);
    
    QString gearValue() const;
    void setGearValue(const QString &gear);

signals:
    void gearValueChanged();

private:
    QString gearValue_ = "P";
};

#endif // GEARPROVIDER_H
