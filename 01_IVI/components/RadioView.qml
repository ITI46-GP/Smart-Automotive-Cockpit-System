import QtQuick
import QtQuick.Layouts

Item {
    id: radioView
    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10
        Text {
            text: "Radio Tuner Mode"
            color: "#21D4FD"
            font { pixelSize: 18; bold: true }
            Layout.alignment: Qt.AlignHCenter
        }
    }
}