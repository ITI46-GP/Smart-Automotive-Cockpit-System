// Ported verbatim from 02-Digital-Cluster's Content_Area/MusicView.qml.
// `import Backend 1.0` -> `import QnxCluster`. Binds to
// VehicleData.musicController (src/Backend/ContentArea/MusicController) —
// cover art URLs there are qrc:/art/... now, not the reference's relative
// file:// paths (see MusicController.cpp).
import QtQuick
import QtQuick.Controls
import QnxCluster

Item {
    id: root
    width: 800
    height: 600

    function formatTime(sec) {
        var m = Math.floor(sec / 60)
        var s = Math.floor(sec % 60)
        return m + ":" + (s < 10 ? "0" + s : s)
    }

    // ── album covers row ──────────────────────────────
    Item {
        id: coversRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        scale: 1.5
        width: 380
        height: 150

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
                mipmap: false
                smooth: true
            }
            Rectangle { anchors.fill: parent; color: "#000000"; opacity: 0.35 }
        }

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
                mipmap: false
                smooth: true
            }
            Rectangle { anchors.fill: parent; color: "#000000"; opacity: 0.35 }
        }

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
                mipmap: false
                smooth: true
            }
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

    // ── progress bar + time ───────────────────────────
    Item {
        id: progressRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: coversRow.bottom
        anchors.topMargin: 35
        scale: 0.8
        width: 240
        height: 16

        Text {
            id: currentTimeLabel
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.formatTime(VehicleData.musicController.currentTimeSec)
            color: "#aaaaaa"
            font.pixelSize: 14
        }

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
                width: parent.width * (VehicleData.musicController.totalTimeSec > 0
                                        ? (VehicleData.musicController.currentTimeSec / VehicleData.musicController.totalTimeSec)
                                        : 0)
                radius: 1
                color: "#ffffff"
                Behavior on width { NumberAnimation { duration: 500 } }
            }

            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: "#ffffff"
                anchors.verticalCenter: parent.verticalCenter
                x: parent.width * (VehicleData.musicController.totalTimeSec > 0
                                    ? (VehicleData.musicController.currentTimeSec / VehicleData.musicController.totalTimeSec)
                                    : 0) - 3
                Behavior on x { NumberAnimation { duration: 500 } }
            }
        }

        Text {
            id: totalTimeLabel
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.formatTime(VehicleData.musicController.totalTimeSec)
            color: "#aaaaaa"
            font.pixelSize: 14
        }
    }

    // ── track title + artist ──────────────────────────
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
