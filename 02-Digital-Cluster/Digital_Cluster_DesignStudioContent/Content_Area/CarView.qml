import QtQuick

Item {
    id: carView
    width: 800
    height: 700
    scale: 1

    Road {
        width: 800
        height: 700
        opacity: 0.55
        scale: 1
        anchors.centerIn: parent
    }

    Car {
        id: mainCar
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 235
        anchors.horizontalCenterOffset: 0
        scale: 1
    }
}
