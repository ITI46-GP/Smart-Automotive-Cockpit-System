#include "EngineTempProvider.h"
#include <fstream>

EngineTempProvider::EngineTempProvider(std::string path, QObject *parent)
    : QObject{parent}, filePath_{path}
{
}

qreal EngineTempProvider::tempValue() const
{
    return tempValue_;
}

bool EngineTempProvider::getValueFromFile()
{
    std::ifstream inputFile(filePath_);
    if (!inputFile.is_open()) return false;

    qreal newValue;
    if (inputFile >> newValue) {
        if (newValue != tempValue_) {
            tempValue_ = newValue;
            emit tempValueChanged();
        }
        return true;
    }
    return false;
}
