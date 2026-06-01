import QtQuick

Column {
    id: item
    spacing: 1

    property string label: ""
    property string value: ""

    Text {
        text: item.label
        color: "#8888aa"
        font.pixelSize: 9
        anchors.horizontalCenter: parent.horizontalCenter
    }
    Text {
        text: item.value
        color: "#ffffff"
        font.pixelSize: 13
        font.bold: true
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
