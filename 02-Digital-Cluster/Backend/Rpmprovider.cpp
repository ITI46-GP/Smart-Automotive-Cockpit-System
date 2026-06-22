#include "Rpmprovider.h"
#include <fstream>

RpmProvider::RpmProvider(std::string path , QObject *parent)
    : QObject{parent} , filePath_{path}
{

}

qreal RpmProvider::rpmValue() const
{
    return rpmValue_;
}

bool RpmProvider::getValueFromFile()
{
    std::ifstream inputFile(filePath_);

    if(!inputFile)
    {
        return false;
    }

    qreal newValue;
    if (inputFile >> newValue)
    {
        if (newValue < MIN_RPM || newValue > MAX_RPM)
        {
            return false;
        }

        if(newValue != rpmValue_)
        {
            rpmValue_ = newValue;

            emit rpmValueChanged();
        }
        return true;
    }
    else
    {
        return false;
    }
}
