import QtQuick
import QtQuick.Layouts

Item {
    id: usbView
    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10
        Text {
            text: "USB Storage Connected"
            color: "#60a5fa"
            font { pixelSize: 18; bold: true }
            Layout.alignment: Qt.AlignHCenter
        }
    }
}