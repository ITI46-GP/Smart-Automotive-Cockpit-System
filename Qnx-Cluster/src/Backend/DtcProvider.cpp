#include "DtcProvider.h"
#include <fstream>
#include <QDebug>

DtcProvider::DtcProvider(std::string path, QObject *parent)
    : QObject{parent}, filePath_{std::move(path)}
{
}

int DtcProvider::activeMask() const
{
    return activeMask_;
}

bool DtcProvider::hasData() const
{
    return hasData_;
}

bool DtcProvider::getValueFromFile()
{
    std::ifstream inputFile(filePath_);
    // Absent file is the normal state before the gateway has heard from
    // TC397. Deliberately does NOT reset activeMask_/hasData_: if the file
    // disappears (gateway restart), the last known faults keep showing
    // rather than silently clearing a warning the driver still needs.
    if (!inputFile.is_open()) return false;

    // The gateway writes with "%.1f\n", so this arrives as e.g. "5.0".
    // Read as double and truncate rather than `>> int`, which would stop at
    // the '.' and happen to work today but break the moment the format is
    // tightened to "%d".
    double newValue;
    if (inputFile >> newValue) {
        const int mask = static_cast<int>(newValue);
        if (mask != activeMask_ || !hasData_) {
            // Worth a log line in its own right: a fault appearing or
            // clearing is exactly the event someone reads the log to find,
            // and it makes the whole gateway->file->cluster chain verifiable
            // on the board without being able to see the screen.
            qInfo("[DTC] active mask %d -> %d", activeMask_, mask);
            activeMask_ = mask;
            hasData_ = true;
            emit activeMaskChanged();
        }
        return true;
    }
    return false;
}
