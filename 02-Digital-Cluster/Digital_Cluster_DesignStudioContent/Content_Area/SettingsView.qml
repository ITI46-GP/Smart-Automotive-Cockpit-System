import QtQuick

Item {
    id: settingsView

    property var settings: [
        { label: "Display Brightness", value: "75%" },
        { label: "Sound Volume",       value: "60%" },
        { label: "Driving Mode",       value: "Comfort" },
        { label: "Theme",              value: "Dark" }
    ]

    Column {
        anchors.centerIn: parent
        spacing: 16

        Text {
            text: "⚙ Settings"
            color: "#ffffff"
            font.pixelSize: 22
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Repeater {
            model: settingsView.settings

            SettingItem {
                settingLabel: modelData.label
                settingValue: modelData.value
            }
        }
    }
}
