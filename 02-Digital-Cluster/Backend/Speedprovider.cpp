#include "Speedprovider.h"
#include <fstream>
#include <iostream>

SpeedProvider::SpeedProvider(std::string path , QObject *parent)
    : QObject{parent} , filePath_{path}
{
}

uint32_t SpeedProvider::speedValue() const
{
    return speedValue_;
}


bool SpeedProvider::getValueFromFile()
{
    std::ifstream inputFile(filePath_);

    if (!inputFile) {
        return false;
    }
    uint32_t newValue;

    if (inputFile >> newValue) {

        // Check First The value in the range
        if (newValue < MIN_SPEED || newValue > MAX_SPEED)
        {
            return false;
        }

        // ONLY emit the signal if the speed actually changed!
        if (newValue != speedValue_) {
            speedValue_ = newValue;
            emit speedValueChanged();
        }
        return true;

    } else {
        // The file was empty or contained invalid text (like "hello")
        return false;
    }
}
