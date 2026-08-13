// Ported verbatim from 02-Digital-Cluster/Backend/BottomBar/TimeProvider.h.
#pragma once

#include <QObject>
#include <QString>

class TimeProvider : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString timeValue READ timeValue NOTIFY timeValueChanged FINAL)

public:
    explicit TimeProvider(QObject *parent = nullptr);
    QString timeValue() const;
    void updateTime();

private:
    QString timeValue_;

signals:
    void timeValueChanged();
};
