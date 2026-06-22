import QtQuick

Rectangle {
    id: contactItem
    width: 320
    height: 60
    radius: 12
    color: contactItem.isSelected ? "#2a2a3a" : "#15151f"
    border.color: contactItem.isSelected ? "#ffffff" : "#2a2a3a"
    border.width: contactItem.isSelected ? 2 : 1

    property string contactName: ""
    property string contactNumber: ""
    property bool isSelected: false

    Behavior on border.color { ColorAnimation { duration: 200 } }
    Behavior on color { ColorAnimation { duration: 200 } }

    Row {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 14

        Rectangle {
            width: 36
            height: 36
            radius: 18
            color: "#3a3a5a"
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: contactItem.contactName.charAt(0)
                color: "#ffffff"
                font.pixelSize: 16
                font.bold: true
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: contactItem.contactName
                color: "#ffffff"
                font.pixelSize: 15
                font.bold: true
            }
            Text {
                text: contactItem.contactNumber
                color: "#8888aa"
                font.pixelSize: 12
            }
        }
    }
}
