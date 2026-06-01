import QtQuick

Rectangle {
    id: contactItem
    width: 320
    height: 60
    radius: 12
    color: "#15151f"
    border.color: "#2a2a3a"

    property string contactName: ""
    property string contactNumber: ""

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
