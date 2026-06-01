import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Popup {
    id: root
    width: Math.min(parent.width * 0.9, 420)
    height: Math.min(parent.height * 0.85, 520)
    anchors.centerIn: parent
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        color: "#1a1b2e"
        radius: 20
        border.color: "#3f3f6e"
        border.width: 1
    }

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.max(10, parent.width * 0.025)
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 36

            Text {
                text: "Bluetooth Devices"
                color: "white"
                font.pixelSize: 15
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 36; height: 36; radius: 10
                color: closeTap.pressed ? "#2b2d52" : "#202238"
                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: "white"
                    font.pixelSize: 14
                }
                TapHandler {
                    id: closeTap
                    onTapped: root.close()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#161625"
            radius: 15
            clip: true

            ListView {
                id: deviceList
                anchors.fill: parent
                anchors.margins: Math.max(8, parent.width * 0.02)
                spacing: 6
                model: audioManager ? audioManager.availableDevices : []

                delegate: Rectangle {
                    width: deviceList.width
                    height: Math.max(52, deviceList.height * 0.11)
                    radius: 12
                    color: devTap.pressed ? "#2b2d52" : "#202238"
                    border.width: 1
                    border.color: modelData.connected ? "#00ff88" : "#34375c"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Rectangle {
                            width: 34; height: 34; radius: 8
                            color: modelData.connected ? "#143f2e" : "#2a2d48"
                            Text {
                                anchors.centerIn: parent
                                text: "🟦"
                                font.pixelSize: 14
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: modelData.name ? modelData.name : "Unknown Device"
                                color: "white"
                                font.bold: true
                                font.pixelSize: 11
                            }

                            Text {
                                text: modelData.address ? modelData.address : ""
                                color: "#8f93c2"
                                font.pixelSize: 9
                            }

                            Text {
                                text: modelData.connected ? "Connected" : "Tap To Connect"
                                color: modelData.connected ? "#00ff88" : "#7d81ae"
                                font.pixelSize: 9
                            }
                        }
                    }

                    TapHandler {
                        id: devTap
                        onTapped: {
                            if (!audioManager) return
                            audioManager.connectToDevice(modelData.path)
                            root.close()
                        }
                    }
                }

                BusyIndicator {
                    anchors.centerIn: parent
                    running: audioManager ? audioManager.btSearching : false
                    visible: running
                }

                Text {
                    anchors.centerIn: parent
                    visible: deviceList.count === 0 && !(audioManager && audioManager.btSearching)
                    text: "No Devices Found"
                    color: "#666"
                    font.pixelSize: 13
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            radius: 12
            color: "#202238"
            border.color: "#393d68"

            Text {
                anchors.centerIn: parent
                text: audioManager ? audioManager.btStatus : "Bluetooth"
                color: text === "Connected" ? "#00ff88" : "#a2a5f9"
                font.bold: true
                font.pixelSize: 10
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            radius: 12
            color: scanTap.pressed ? "#1b4fd0" : "#2563eb"

            Text {
                anchors.centerIn: parent
                text: audioManager && audioManager.btSearching ? "Searching..." : "Scan Devices"
                color: "white"
                font.bold: true
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            TapHandler {
                id: scanTap
                onTapped: {
                    if (audioManager) audioManager.startDiscovery()
                }
            }
        }
    }
}