import QtQuick
import Digital_Cluster_DesignStudio

Window {
    width: mainScreen.width
    height: mainScreen.height
    // flags: Qt.FramelessWindowHint
    x:0
    y:0
    visible: true
    title: "Digital_Cluster_DesignStudio"

    Screen01 {
        id: mainScreen
        x: 0
        y: 0
        anchors.centerIn: parent
    }

}

