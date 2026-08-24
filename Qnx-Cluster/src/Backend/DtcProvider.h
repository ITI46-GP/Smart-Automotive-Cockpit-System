// Active diagnostic-trouble-code bitmask, published by the vehicle gateway
// service (HyperNova_VehicleGateway_Task_10/qnx-service) as one bare number
// in a file, exactly like fuel.txt / env_temp.txt. Same contract, same
// `ifstream >> value` read, same 20 Hz poll from VehicleDataProvider.
//
// Bit order is fixed by the gateway's dtc_bit():
//
//   bit 0  P0217  engine coolant over temperature
//   bit 1  P0118  coolant temp sensor 1 circuit high
//   bit 2  P0300  random/multiple cylinder misfire
//   bit 3  P0442  EVAP system small leak
//   bit 4  P0562  system voltage low
//
// The code->text table lives in QML (FaultPopup.qml), not here: it is
// presentation, it changes more often than this code, and keeping it in QML
// avoids a rebuild for a wording fix.
#pragma once

#include <QObject>
#include <string>

class DtcProvider : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int activeMask READ activeMask NOTIFY activeMaskChanged FINAL)
    Q_PROPERTY(bool hasData READ hasData NOTIFY activeMaskChanged FINAL)

public:
    explicit DtcProvider(std::string path, QObject *parent = nullptr);

    int activeMask() const;

    // False until the file has been read at least once. Distinguishes "the
    // gateway has told us nothing yet" from "mask 0, all clear" -- both look
    // like zero otherwise, and only one of them should clear a fault popup.
    bool hasData() const;

    bool getValueFromFile();

signals:
    void activeMaskChanged();

private:
    int activeMask_ = 0;
    bool hasData_ = false;
    std::string filePath_;
};
