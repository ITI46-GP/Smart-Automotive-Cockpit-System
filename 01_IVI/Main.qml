pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import QtQuick.Controls
import "pages"
import "components"

Window {
    id: root

    width: 1024
    height: 600
    minimumWidth: 820
    minimumHeight: 480

    visible: true
    title: qsTr("GP IVI")
    color: "#07000E"

    // Final board compatibility:
    // enable this flag on the embedded target for a borderless 7-inch display.
    // flags: Qt.FramelessWindowHint

    property bool splashFinished: false

    // This is our design resolution.
    // All screens/components are drawn inside this surface,
    // then scaled to fit any real window/screen size.
    readonly property int designWidth: 1024
    readonly property int designHeight: 600

    Rectangle {
        anchors.fill: parent
        color: "#07000E"
    }


Connections {
    target: profileManager
    function onActiveVolumeChanged() {
        if (audioManager) {
            audioManager.setVolume(profileManager.activeVolume / 100.0)
        }
    }
}

    Item {
        id: appSurface

        width: root.designWidth
        height: root.designHeight

        anchors.centerIn: parent

        scale: Math.min(root.width / root.designWidth,
                        root.height / root.designHeight)

        transformOrigin: Item.Center

        StackView {
            id: stackView
            anchors.fill: parent

            opacity: root.splashFinished ? 1 : 0
            visible: opacity > 0

            initialItem: dashboardComponent

            Behavior on opacity {
                NumberAnimation {
                    duration: 800
                    easing.type: Easing.InOutQuad
                }
            }
        }

        Component {
            id: dashboardComponent

            DashboardPage {
                onProfileRequested: {
                    keyboardOverlay.closeKeyboard()
                    stackView.push(profileComponent)
                }
                onLightsRequested: {
                    keyboardOverlay.closeKeyboard()
                    stackView.push(lightsComponent)
                }
                onSettingsRequested: {
                    keyboardOverlay.closeKeyboard()
                    stackView.push(settingsComponent)
                }
                onMapRequested: {
                    keyboardOverlay.closeKeyboard()
                    stackView.push(mapComponent)
                }
                onAssistantRequested: {
                    keyboardOverlay.closeKeyboard()
                    stackView.push(assistantComponent)
                }
                onMediaRequested: {
                    keyboardOverlay.closeKeyboard()
                    stackView.push(mediaComponent)
                }
                onWeatherRequested: {
                    keyboardOverlay.closeKeyboard()
                    stackView.push(weatherComponent)
                }
                onClimateRequested: {
                    keyboardOverlay.closeKeyboard()
                    stackView.push(climateComponent)
                }
            }

        }

        Component {
            id: profileComponent

            ProfilePage {
                onBackClicked: {
                    keyboardOverlay.closeKeyboard()
                    if (stackView.depth > 1) {
                        stackView.pop()
                    }
                }
            }
        }
        Component {
            id: lightsComponent

            LightsPage {
                onBackClicked: {
                    keyboardOverlay.closeKeyboard()
                    if (stackView.depth > 1) {
                        stackView.pop()
                    }
                }
            }
        }
        Component {
            id: settingsComponent

            SettingsPage {
                onBackClicked: {
                    keyboardOverlay.closeKeyboard()
                    if (stackView.depth > 1) {
                        stackView.pop()
                    }
                }
            }
        }
        Component {
            id: mapComponent

            MapPage {
                onKeyboardRequested: function(textInput) {
                    keyboardOverlay.openFor(textInput)
                }
                onBackClicked: {
                    keyboardOverlay.closeKeyboard()
                    if (stackView.depth > 1) {
                        stackView.pop()
                    }
                }
            }
        }
        Component {
            id: assistantComponent

            AssistantPage {
                onKeyboardRequested: function(textInput) {
                    keyboardOverlay.openFor(textInput)
                }
                onBackClicked: {
                    keyboardOverlay.closeKeyboard()
                    if (stackView.depth > 1) {
                        stackView.pop()
                    }
                }
            }
        }
        Component {
            id: mediaComponent

            MediaPage {
                onBackClicked: {
                    keyboardOverlay.closeKeyboard()
                    if (stackView.depth > 1) {
                        stackView.pop()
                    }
                }
            }
        }
        Component {
            id: weatherComponent

            WeatherPage {
                onBackClicked: {
                    keyboardOverlay.closeKeyboard()
                    if (stackView.depth > 1) {
                        stackView.pop()
                    }
                }
            }
        }
        Component {
            id: climateComponent

            ClimatePage {
                onBackClicked: {
                    keyboardOverlay.closeKeyboard()
                    if (stackView.depth > 1) {
                        stackView.pop()
                    }
                }
            }
        }

        SplashScreen {
            anchors.fill: parent
            opacity: root.splashFinished ? 0 : 1
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 700
                    easing.type: Easing.InOutQuad
                }
            }

            onFinished: {
                root.splashFinished = true
            }
        }

        OnScreenKeyboard {
            id: keyboardOverlay
            z: 999
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
        }
    }

    // Test fullscreen quickly
    Shortcut {
        sequence: "F11"

        onActivated: {
            if (root.visibility === Window.FullScreen) {
                root.visibility = Window.Windowed
            } else {
                root.visibility = Window.FullScreen
            }
        }
    }

    // Exit / leave fullscreen
    Shortcut {
        sequence: "Esc"

        onActivated: {
            if (root.visibility === Window.FullScreen) {
                root.visibility = Window.Windowed
            } else {
                Qt.quit()
            }
        }
    }
}

