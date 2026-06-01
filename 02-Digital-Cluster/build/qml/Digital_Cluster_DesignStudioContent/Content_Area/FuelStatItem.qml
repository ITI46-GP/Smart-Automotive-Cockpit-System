import QtQuick

Column {
    id: stat
    spacing: 4

    property string label: ""
    property string value: ""

    Text {
        text: stat.label
        color: "#8888aa"
        font.pixelSize: 11
        anchors.horizontalCenter: parent.horizontalCenter
    }
    Text {
        text: stat.value
        color: "#ffffff"
        font.pixelSize: 18
        font.bold: true
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
