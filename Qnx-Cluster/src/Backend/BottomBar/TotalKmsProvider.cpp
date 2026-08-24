#include "TotalKmsProvider.h"
#include <fstream>

TotalKmsProvider::TotalKmsProvider(std::string path, QObject *parent)
    : QObject{parent}, filePath_{path}
{
}

qreal TotalKmsProvider::kmsValue() const
{
    return kmsValue_;
}

bool TotalKmsProvider::getValueFromFile()
{
    std::ifstream inputFile(filePath_);
    if (!inputFile.is_open()) return false;

    qreal newValue;
    if (inputFile >> newValue) {
        if (newValue != kmsValue_) {
            kmsValue_ = newValue;
            emit kmsValueChanged();
        }
        return true;
    }
    return false;
}
