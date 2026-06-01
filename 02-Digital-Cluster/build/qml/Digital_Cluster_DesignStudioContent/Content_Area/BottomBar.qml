import QtQuick

Rectangle {
    id: bottomBar
    width: 480
    height: 40
    radius: 20
    color: "#15151f"
    border.color: "#2a2a3a"
    border.width: 1

    property string tempText: "22°C"
    property string totalText: "20853 km"
    property string timeText: "10:32"

    Row {
        anchors.centerIn: parent
        spacing: 40

        BottomBarItem {
            label: "TEMP"
            value: bottomBar.tempText
        }

        BottomBarItem {
            label: "TOTAL"
            value: bottomBar.totalText
        }

        BottomBarItem {
            label: "TIME"
            value: bottomBar.timeText
        }
    }
}
