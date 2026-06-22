#ifndef TOTALKMSPROVIDER_H
#define TOTALKMSPROVIDER_H

#include <QObject>
#include <string>

class TotalKmsProvider : public QObject
{
    Q_OBJECT
    Q_PROPERTY(qreal kmsValue READ kmsValue NOTIFY kmsValueChanged FINAL)

public:
    explicit TotalKmsProvider(std::string path, QObject *parent = nullptr);
    qreal kmsValue() const;
    bool getValueFromFile();

private:
    qreal kmsValue_ = 1200;
    std::string filePath_;

signals:
    void kmsValueChanged();
};

#endif // TOTALKMSPROVIDER_H
