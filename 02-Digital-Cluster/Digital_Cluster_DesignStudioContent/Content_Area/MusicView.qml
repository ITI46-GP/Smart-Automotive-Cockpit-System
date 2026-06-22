import QtQuick
import QtQuick.Controls
import Backend 1.0

/*
 * MUSIC VIEW
 * 
 * This UI component renders the current media playback state.
 * It is completely stateless; it binds entirely to the C++ `VehicleData.musicController`.
 * 
 * In a production environment:
 * 1. The IVI sends SOME/IP messages with the current track metadata and playtime.
 * 2. The C++ `MusicController` updates its `Q_PROPERTY` variables.
 * 3. This QML file automatically reacts and updates the album art, text, and progress bar.
 */
Item {
    id: root
    width: 800
    height: 600

    // ── helper to format seconds → m:ss ───────────────
    function formatTime(sec) {
        var m = Math.floor(sec / 60)
        var s = Math.floor(sec % 60)
        return m + ":" + (s < 10 ? "0" + s : s)
    }

    // ══════════════════════════════════════════════════
    // ALBUM COVERS ROW
    // ══════════════════════════════════════════════════
    Item {
        id: coversRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenterOffset: 0
        scale: 1.5
        anchors.verticalCenterOffset: 0
        width: 380
        height: 150

        // ── PREVIOUS COVER (left, smaller, faded) ─────
        Rectangle {
            id: prevCover
            width: 100
            height: 100
            radius: 8
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            scale: 0.8
            color: "#1a1a22"
            clip: true
            opacity: 0.45
            z: 1

            Image {
                anchors.fill: parent
                source: VehicleData.musicController.prevCoverArtUrl
                fillMode: Image.PreserveAspectCrop
                smooth: true
            }

            // dark overlay
            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: 0.35
            }
        }

        // ── NEXT COVER (right, smaller, faded) ────────
        Rectangle {
            id: nextCover
            width: 100
            height: 100
            radius: 8
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            scale: 0.8
            color: "#1a1a22"
            clip: true
            opacity: 0.45
            z: 1

            Image {
                anchors.fill: parent
                source: VehicleData.musicController.nextCoverArtUrl
                fillMode: Image.PreserveAspectCrop
                smooth: true
            }

            // dark overlay
            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: 0.35
            }
        }

        // ── CURRENT COVER (center, larger, highlighted) ──
        Rectangle {
            id: currentCover
            width: 140
            height: 140
            radius: 10
            anchors.centerIn: parent
            color: "#1a1a22"
            clip: true
            z: 2

            Image {
                anchors.fill: parent
                source: VehicleData.musicController.coverArtUrl
                fillMode: Image.PreserveAspectCrop
                smooth: true
            }

            // subtle border highlight
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                radius: parent.radius
                border.color: "#ffffff"
                border.width: 1
                opacity: 0.25
            }
        }
    }

    // ══════════════════════════════════════════════════
    // PROGRESS BAR + TIME
    // ══════════════════════════════════════════════════
    Item {
        id: progressRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: coversRow.bottom
        anchors.topMargin: 35
        anchors.horizontalCenterOffset: 0
        scale: 0.8
        width: 240
        height: 16
        opacity: 1

        // current time
        Text {
            id: currentTimeLabel
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.formatTime(VehicleData.musicController.currentTimeSec)
            color: "#aaaaaa"
            font.pixelSize: 14
        }

        // progress bar
        Rectangle {
            id: progressBar
            anchors.left: currentTimeLabel.right
            anchors.right: totalTimeLabel.left
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            height: 2
            radius: 1
            color: "#333344"

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * (VehicleData.musicController.totalTimeSec > 0 ? (VehicleData.musicController.currentTimeSec / VehicleData.musicController.totalTimeSec) : 0)
                radius: 1
                color: "#ffffff"

                Behavior on width {
                    NumberAnimation { duration: 500 }
                }
            }

            // small dot at the progress position
            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: "#ffffff"
                anchors.verticalCenter: parent.verticalCenter
                x: parent.width * (VehicleData.musicController.totalTimeSec > 0 ? (VehicleData.musicController.currentTimeSec / VehicleData.musicController.totalTimeSec) : 0) - 3

                Behavior on x {
                    NumberAnimation { duration: 500 }
                }
            }
        }

        // total time
        Text {
            id: totalTimeLabel
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.formatTime(VehicleData.musicController.totalTimeSec)
            color: "#aaaaaa"
            font.pixelSize: 14
        }
    }

    // ══════════════════════════════════════════════════
    // TRACK TITLE + ARTIST
    // ══════════════════════════════════════════════════
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: progressRow.bottom
        anchors.topMargin: 12
        spacing: 4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: VehicleData.musicController.trackTitle
            color: "#ffffff"
            font.pixelSize: 16
            font.bold: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: VehicleData.musicController.trackArtist
            color: "#888899"
            font.pixelSize: 11
        }
    }
}
