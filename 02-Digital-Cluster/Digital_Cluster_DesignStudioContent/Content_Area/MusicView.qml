import QtQuick
import QtQuick.Controls

Item {
    id: root
    width: 800
    height: 600

    // ── music data model ──────────────────────────────
    property var tracks: [
        {
            title: "Starboy",
            artist: "The Weeknd",
            cover: "../assets/starboy.jpeg",
            duration: "3:20"
        },
        {
            title: "Be Alright",
            artist: "Dean Lewis",
            cover: "../assets/be_alright.jpeg",
            duration: "3:50"
        },
        {
            title: "Shots",
            artist: "Image Dragons",
            cover: "../assets/Imagine_Dragons_-_Shots.png",
            duration: "3:35"
        }
    ]

    property int currentIndex: 1   // middle one is "now playing"

    // current playing time (simulated)
    property real currentTime: 76   // seconds (1:16)
    property real totalTime: 230    // seconds (3:50)

    // ── helper to format seconds → m:ss ───────────────
    function formatTime(sec) {
        var m = Math.floor(sec / 60)
        var s = Math.floor(sec % 60)
        return m + ":" + (s < 10 ? "0" + s : s)
    }

    // simulate playback time progressing
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (root.currentTime < root.totalTime) {
                root.currentTime += 1
            } else {
                root.currentTime = 0
            }
        }
    }

    // ── safe access helpers ───────────────────────────
    property int prevIndex: (currentIndex - 1 + tracks.length) % tracks.length
    property int nextIndex: (currentIndex + 1) % tracks.length

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
                source: root.tracks[root.prevIndex].cover
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
                source: root.tracks[root.nextIndex].cover
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
                source: root.tracks[root.currentIndex].cover
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
            text: root.formatTime(root.currentTime)
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
                width: parent.width * (root.currentTime / root.totalTime)
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
                x: parent.width * (root.currentTime / root.totalTime) - 3

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
            text: root.formatTime(root.totalTime)
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
            text: root.tracks[root.currentIndex].title
            color: "#ffffff"
            font.pixelSize: 16
            font.bold: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.tracks[root.currentIndex].artist
            color: "#888899"
            font.pixelSize: 11
        }
    }
}
