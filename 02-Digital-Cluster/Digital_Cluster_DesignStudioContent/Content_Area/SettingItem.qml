import QtQuick

Rectangle {
    id: setting
    width: 320
    height: 50
    radius: 12
    color: "#15151f"
    border.color: "#2a2a3a"

    property string settingLabel: ""
    property string settingValue: ""

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: setting.settingLabel
        color: "#ffffff"
        font.pixelSize: 14
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: setting.settingValue
        color: "#4a9eff"
        font.pixelSize: 14
        font.bold: true
    }
}
