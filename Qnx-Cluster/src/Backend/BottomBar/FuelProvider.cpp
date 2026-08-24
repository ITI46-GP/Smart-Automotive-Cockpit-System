#include "FuelProvider.h"
#include <fstream>

FuelProvider::FuelProvider(std::string path, QObject *parent)
    : QObject{parent}, filePath_{path}
{
}

qreal FuelProvider::fuelValue() const
{
    return fuelValue_;
}

bool FuelProvider::getValueFromFile()
{
    std::ifstream inputFile(filePath_);
    if (!inputFile.is_open()) return false;

    qreal newValue;
    if (inputFile >> newValue) {
        if (newValue != fuelValue_) {
            fuelValue_ = newValue;
            emit fuelValueChanged();
        }
        return true;
    }
    return false;
}
