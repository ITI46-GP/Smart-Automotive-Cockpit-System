import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: 1024
    height: 600

    signal backClicked()

    readonly property color bgColor: "#07000E"
    readonly property color panelColor: "#090613"
    readonly property color panelColorLight: "#1C162B"
    readonly property color borderColor: "#342544"
    readonly property color textColor: "#CBC4CD"
    readonly property color textColorDim: "#8A8294"
    readonly property color accentViolet: "#8B5CF6"
    readonly property color accentCyan: "#06B6D4"

    Rectangle {
        anchors.fill: parent
        color: root.bgColor
    }

    Rectangle {
        id: backBtn
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 20
        anchors.leftMargin: 20
        width: 44
        height: 44
        radius: 12
        color: backTap.pressed ? Qt.lighter(root.panelColorLight, 1.3) : root.panelColorLight
        border.color: root.borderColor
        border.width: 1

        TapHandler {
            id: backTap
            onTapped: root.backClicked()
        }

        Text {
            anchors.centerIn: parent
            text: "‹"
            font.pixelSize: 24
            font.bold: true
            color: root.accentCyan
        }
    }

    Text {
        anchors.top: parent.top
        anchors.topMargin: 28
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Weather"
        color: root.textColor
        font.pixelSize: 20
        font.bold: true
    }

    Component.onCompleted: {
        if (weatherApi && weatherApi.cityName === "") {
            weatherApi.fetchWeather("Giza")
        }
    }

    Connections {
        target: weatherApi
        function onForecastReady() {
            forecastList.model = weatherApi.forecast
        }
    }

    Flickable {
        id: mainFlickable
        anchors.top: backBtn.bottom
        anchors.topMargin: 16
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: keyboardContainer.visible ? keyboardContainer.top : parent.bottom
        anchors.margins: 16
        contentHeight: mainColumn.height
        clip: true

        ColumnLayout {
            id: mainColumn
            width: parent.width
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 22
                color: root.panelColorLight
                border.color: searchField.activeFocus ? root.accentCyan : root.borderColor
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 8
                    spacing: 8

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: "Enter city name..."
                        placeholderTextColor: root.textColorDim
                        color: root.textColor
                        font.pixelSize: 14
                        background: Rectangle { color: "transparent" }

                        Keys.onReturnPressed: {
                            if (text !== "" && weatherApi) {
                                weatherApi.fetchWeather(text)
                                searchField.focus = false
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 18
                        color: searchTap.pressed ? Qt.darker(root.accentViolet) : root.accentViolet

                        Text {
                            anchors.centerIn: parent
                            text: "🔍"
                            font.pixelSize: 16
                        }

                        TapHandler {
                            id: searchTap
                            onTapped: {
                                if (searchField.text !== "" && weatherApi) {
                                    weatherApi.fetchWeather(searchField.text)
                                    searchField.focus = false
                                }
                            }
                        }
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: weatherApi ? (weatherApi.cityName || "Loading...") : "Loading..."
                font.pixelSize: 22
                font.bold: true
                color: root.textColor
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: weatherApi && weatherApi.temperature ? Math.round(weatherApi.temperature) + "°C" : "--°C"
                font.pixelSize: 48
                font.weight: Font.Light
                color: root.accentCyan
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: weatherApi ? (weatherApi.weather || "") : ""
                font.pixelSize: 16
                color: root.textColorDim
                font.capitalization: Font.Capitalize
                visible: weatherApi && weatherApi.weather ? true : false
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                radius: 16
                color: root.panelColor
                border.color: root.borderColor
                border.width: 1
                visible: weatherApi && weatherApi.cityName ? true : false

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "💧"
                            font.pixelSize: 22
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: weatherApi ? (weatherApi.humidity + "%") : "--%"
                            font.pixelSize: 16
                            font.bold: true
                            color: root.textColor
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Humidity"
                            font.pixelSize: 11
                            color: root.textColorDim
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 40
                        color: root.borderColor
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "💨"
                            font.pixelSize: 22
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: weatherApi && weatherApi.windSpeed ? weatherApi.windSpeed.toFixed(1) + " m/s" : "-- m/s"
                            font.pixelSize: 16
                            font.bold: true
                            color: root.textColor
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Wind"
                            font.pixelSize: 11
                            color: root.textColorDim
                        }
                    }
                }
            }

            Text {
                text: "5-Day Forecast"
                font.pixelSize: 16
                font.bold: true
                color: root.textColor
                visible: forecastList.count > 0
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                radius: 16
                color: root.panelColor
                border.color: root.borderColor
                border.width: 1
                visible: forecastList.count > 0
                clip: true

                ListView {
                    id: forecastList
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6
                    clip: true
                    interactive: true
                    model: []

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        contentItem: Rectangle {
                            implicitWidth: 6
                            radius: 3
                            color: root.accentViolet
                        }
                        background: Rectangle {
                            implicitWidth: 6
                            color: "transparent"
                        }
                    }

                    delegate: Rectangle {
                        width: forecastList.width
                        height: 52
                        radius: 12
                        color: root.panelColorLight
                        border.color: root.borderColor
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12

                            Text {
                                Layout.preferredWidth: 36
                                text: modelData.dayName || ""
                                font.pixelSize: 13
                                font.bold: true
                                color: root.textColor
                            }

                            Image {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                source: modelData.icon ? "https://openweathermap.org/img/wn/" + modelData.icon + "@2x.png" : ""
                                fillMode: Image.PreserveAspectFit
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.weather || ""
                                font.pixelSize: 12
                                color: root.textColorDim
                                font.capitalization: Font.Capitalize
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.temp ? Math.round(modelData.temp) + "°" : ""
                                font.pixelSize: 16
                                font.bold: true
                                color: root.accentViolet
                            }
                        }
                    }
                }
            }

            Item { height: 20 }
        }
    }

    Rectangle {
        id: keyboardContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 280
        color: "#0b0813"
        border.color: root.borderColor
        border.width: 1
        visible: searchField.activeFocus

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: "#130f22"
                radius: 8
                border.color: root.borderColor

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 15
                    anchors.rightMargin: 10

                    Text {
                        Layout.fillWidth: true
                        text: searchField.text === "" ? "Enter city name..." : searchField.text
                        color: searchField.text === "" ? root.textColorDim : "#FFFFFF"
                        font.pixelSize: 14
                    }

                    Rectangle {
                        Layout.preferredWidth: 80
                        Layout.preferredHeight: 30
                        radius: 15
                        color: root.accentCyan
                        border.color: Qt.lighter(root.accentCyan, 1.2)

                        Text {
                            anchors.centerIn: parent
                            text: "DONE"
                            color: "#000000"
                            font.bold: true
                            font.pixelSize: 12
                        }

                        TapHandler {
                            onTapped: {
                                if (searchField.text !== "" && weatherApi) {
                                    weatherApi.fetchWeather(searchField.text)
                                }
                                searchField.focus = false
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        radius: 10
                        color: row1Tap.pressed ? "#251d3a" : "#171226"
                        border.color: root.borderColor

                        Text { anchors.centerIn: parent; text: modelData; color: "#FFFFFF"; font.pixelSize: 16; font.bold: true }
                        TapHandler { id: row1Tap; onTapped: searchField.text += modelData }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Item { Layout.preferredWidth: 15 }
                Repeater {
                    model: ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        radius: 10
                        color: row2Tap.pressed ? "#251d3a" : "#171226"
                        border.color: root.borderColor

                        Text { anchors.centerIn: parent; text: modelData; color: "#FFFFFF"; font.pixelSize: 16; font.bold: true }
                        TapHandler { id: row2Tap; onTapped: searchField.text += modelData }
                    }
                }
                Item { Layout.preferredWidth: 15 }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Item { Layout.preferredWidth: 40 }
                Repeater {
                    model: ["Z", "X", "C", "V", "B", "N", "M"]
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        radius: 10
                        color: row3Tap.pressed ? "#251d3a" : "#171226"
                        border.color: root.borderColor

                        Text { anchors.centerIn: parent; text: modelData; color: "#FFFFFF"; font.pixelSize: 16; font.bold: true }
                        TapHandler { id: row3Tap; onTapped: searchField.text += modelData }
                    }
                }
                Item { Layout.preferredWidth: 40 }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 42
                    radius: 10
                    color: clearTap.pressed ? "#3a1d28" : "#2a1520"
                    border.color: "#542538"

                    Text { anchors.centerIn: parent; text: "CLEAR"; color: "#FF79C6"; font.pixelSize: 12; font.bold: true }
                    TapHandler { id: clearTap; onTapped: searchField.text = "" }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: 10
                    color: spaceTap.pressed ? "#251d3a" : "#171226"
                    border.color: root.borderColor

                    Text { anchors.centerIn: parent; text: "SPACE"; color: root.textColorDim; font.pixelSize: 13; font.bold: true }
                    TapHandler { id: spaceTap; onTapped: searchField.text += " " }
                }

                Rectangle {
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 42
                    radius: 10
                    color: backspaceTap.pressed ? "#251d3a" : "#171226"
                    border.color: root.borderColor

                    Text { anchors.centerIn: parent; text: "BACK"; color: "#FFFFFF"; font.pixelSize: 12; font.bold: true }
                    TapHandler { id: backspaceTap; onTapped: searchField.text = searchField.text.slice(0, -1) }
                }

                Rectangle {
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 42
                    radius: 10
                    color: bottomDoneTap.pressed ? Qt.darker(root.accentCyan, 1.5) : root.panelColorLight
                    border.color: root.accentCyan

                    Text { anchors.centerIn: parent; text: "DONE"; color: root.accentCyan; font.pixelSize: 12; font.bold: true }
                    TapHandler {
                        id: bottomDoneTap
                        onTapped: {
                            if (searchField.text !== "" && weatherApi) {
                                weatherApi.fetchWeather(searchField.text)
                            }
                            searchField.focus = false
                        }
                    }
                }
            }
        }
    }
}