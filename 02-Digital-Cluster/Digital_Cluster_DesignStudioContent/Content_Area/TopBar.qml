import QtQuick
import QtQuick.Studio.DesignEffects

Item {
    id: topBarRoot
    width: topBar.width + 160
    height: 60

    property int currentView: 0

    // turning indicators
    property bool leftIndicatorOn: true
    property bool rightIndicatorOn: false

    signal viewSelected(int index)

    // ── LEFT TURN INDICATOR ───────────────────────────
    Rectangle {
        id: leftIndicator
        width: 50
        height: 50
        radius: 25

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 0

        color: topBarRoot.leftIndicatorOn ? "#20ff55" : "#15151f"
        border.color: topBarRoot.leftIndicatorOn ? "#60ff88" : "#2a2a3a"
        border.width: 1

        // arrow icon inside
        Image {
            id: leftArrow
            anchors.centerIn: parent
            width: 50
            height: 35
            source: "../assets/left-arrow.png"
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            opacity: topBarRoot.leftIndicatorOn ? 1.0 : 0.3
        }

        DesignEffect {
            visible: topBarRoot.leftIndicatorOn
            effects: [
                DesignDropShadow {
                    color: "#20ff55"
                    blur: 20
                    spread: 2
                }
            ]
        }

        // blinking animation (both circle and arrow blink together)
        SequentialAnimation on opacity {
            running: topBarRoot.leftIndicatorOn
            loops: Animation.Infinite

            NumberAnimation { from: 1.0; to: 0.35; duration: 450 }
            NumberAnimation { from: 0.35; to: 1.0; duration: 450 }
        }
    }

    // ── MAIN TOP BAR ──────────────────────────────────
    Rectangle {
        id: topBar
        width: 420
        height: 50
        radius: 25
        color: "#15151f"
        border.color: "#2a2a3a"
        border.width: 1

        anchors.centerIn: parent

        Row {
            anchors.centerIn: parent
            spacing: 8

            TopBarButton {
                id: carIcon
                iconSourceunSelected: "../assets/car_icon_unselected.png"
                iconSourceSelected: "../assets/car_icon.png"
                iconSize: 22
                selected: topBarRoot.currentView === 0
                onClicked: topBarRoot.viewSelected(0)
            }

            TopBarButton {
                id: navigationIcon
                iconSourceunSelected: "../assets/navigation_icon_unselected.png"
                iconSourceSelected: "../assets/navigation_icon_selected.png"
                iconSize: 22
                selected: topBarRoot.currentView === 1
                onClicked: topBarRoot.viewSelected(1)
            }

            TopBarButton {
                id: contactIcon
                iconSourceunSelected: "../assets/contacts_icon_unselected.png"
                iconSourceSelected: "../assets/contacts_icon_selected.png"
                iconSize: 22
                selected: topBarRoot.currentView === 2
                onClicked: topBarRoot.viewSelected(2)
            }

            TopBarButton {
                id: musicIcon
                iconSourceunSelected: "../assets/music_icon_unselected.png"
                iconSourceSelected: "../assets/music_icon_selected.png"
                iconSize: 22
                selected: topBarRoot.currentView === 3
                onClicked: topBarRoot.viewSelected(3)
            }

            TopBarButton {
                id: fuelIcon
                iconSourceunSelected: "../assets/fuel_icon_unselected.png"
                iconSourceSelected: "../assets/fuel_icon_selected.png"
                iconSize: 22
                selected: topBarRoot.currentView === 4
                onClicked: topBarRoot.viewSelected(4)
            }

            TopBarButton {
                id: settingsIcon
                iconSourceunSelected: "../assets/settings_icon_unselected.png"
                iconSourceSelected: "../assets/settings_icon_selected.png"
                iconSize: 22
                selected: topBarRoot.currentView === 5
                onClicked: topBarRoot.viewSelected(5)
            }
        }

        DesignEffect {
            effects: [
                DesignDropShadow {
                    color: "#000000"
                    blur: 18
                    offsetY: 4
                }
            ]
        }
    }

    // ── RIGHT TURN INDICATOR ──────────────────────────
    Rectangle {
        id: rightIndicator
        width: 50
        height: 50
        radius: 25

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 0

        color: topBarRoot.rightIndicatorOn ? "#20ff55" : "#15151f"
        border.color: topBarRoot.rightIndicatorOn ? "#60ff88" : "#2a2a3a"
        border.width: 1

        // arrow icon inside
        Image {
            id: rightArrow
            anchors.centerIn: parent
            width: 50
            height: 35
            source: "../assets/right-arrow.png"
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            opacity: topBarRoot.rightIndicatorOn ? 1.0 : 0.3
        }

        DesignEffect {
            visible: topBarRoot.rightIndicatorOn
            effects: [
                DesignDropShadow {
                    color: "#20ff55"
                    blur: 20
                    spread: 2
                }
            ]
        }

        // blinking animation
        SequentialAnimation on opacity {
            running: topBarRoot.rightIndicatorOn
            loops: Animation.Infinite

            NumberAnimation { from: 1.0; to: 0.35; duration: 450 }
            NumberAnimation { from: 0.35; to: 1.0; duration: 450 }
        }
    }
}
