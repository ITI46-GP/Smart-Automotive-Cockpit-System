import QtQuick
import QtQuick.Controls
import QnxCluster

Item {
    id: root

    width: 800
    height: 600

    readonly property real progressRatio:
        clusterMedia.hasMedia
        && clusterMedia.durationMs > 0
            ? Math.min(
                  1.0,
                  clusterMedia.positionMs
                  / clusterMedia.durationMs)
            : 0.0

    function formatTimeMs(ms) {
        if (ms <= 0)
            return "0:00"

        var totalSeconds =
                Math.floor(ms / 1000)

        var minutes =
                Math.floor(totalSeconds / 60)

        var seconds =
                totalSeconds % 60

        return minutes
                + ":"
                + (seconds < 10
                   ? "0" + seconds
                   : seconds)
    }

    /*
     * Artwork transport comes next.
     *
     * Do NOT show the old mock Starboy / Dean Lewis /
     * Imagine Dragons artwork while HNMC is active.
     */
    Item {
        id: coversRow

        anchors.horizontalCenter:
                parent.horizontalCenter

        anchors.verticalCenter:
                parent.verticalCenter

        scale: 1.5

        width: 380
        height: 150

        /*
         * Previous artwork placeholder.
         * Hidden until HNMC artwork/queue support is added.
         */
        Rectangle {
            id: prevCover

            width: 100
            height: 100

            radius: 8

            anchors.verticalCenter:
                    parent.verticalCenter

            anchors.left:
                    parent.left

            scale: 0.8

            color: "#1a1a22"

            opacity: 0.20

            visible: clusterMedia.hasMedia

            Text {
                anchors.centerIn: parent

                text: "♪"

                color: "#555566"

                font.pixelSize: 34
            }
        }

        /*
         * Next artwork placeholder.
         */
        Rectangle {
            id: nextCover

            width: 100
            height: 100

            radius: 8

            anchors.verticalCenter:
                    parent.verticalCenter

            anchors.right:
                    parent.right

            scale: 0.8

            color: "#1a1a22"

            opacity: 0.20

            visible: clusterMedia.hasMedia

            Text {
                anchors.centerIn: parent

                text: "♪"

                color: "#555566"

                font.pixelSize: 34
            }
        }

        /*
         * Current artwork placeholder.
         *
         * Real Android album art will replace this after
         * HNMC ARTWORK support is added.
         */
        Rectangle {
            id: currentCover

            width: 140
            height: 140

            radius: 10

            anchors.centerIn: parent

            color: "#1a1a22"

            border.color:
                    clusterMedia.connected
                    ? "#555566"
                    : "#333344"

            border.width: 1

            Text {
                anchors.centerIn: parent

                text:
                    clusterMedia.hasMedia
                    ? "♪"
                    : "—"

                color:
                    clusterMedia.hasMedia
                    ? "#ffffff"
                    : "#555566"

                font.pixelSize:
                    clusterMedia.hasMedia
                    ? 52
                    : 34
            }
        }
    }

    /*
     * Playback progress.
     */
    Item {
        id: progressRow

        anchors.horizontalCenter:
                parent.horizontalCenter

        anchors.top:
                coversRow.bottom

        anchors.topMargin: 35

        scale: 0.8

        width: 240
        height: 16

        Text {
            id: currentTimeLabel

            anchors.left:
                    parent.left

            anchors.verticalCenter:
                    parent.verticalCenter

            text:
                root.formatTimeMs(
                    clusterMedia.positionMs)

            color: "#aaaaaa"

            font.pixelSize: 14
        }

        Rectangle {
            id: progressBar

            anchors.left:
                    currentTimeLabel.right

            anchors.right:
                    totalTimeLabel.left

            anchors.leftMargin: 8
            anchors.rightMargin: 8

            anchors.verticalCenter:
                    parent.verticalCenter

            height: 2
            radius: 1

            color: "#333344"

            Rectangle {
                anchors.left:
                        parent.left

                anchors.top:
                        parent.top

                anchors.bottom:
                        parent.bottom

                width:
                    parent.width
                    * root.progressRatio

                radius: 1

                color: "#ffffff"

                Behavior on width {
                    NumberAnimation {
                        duration: 250
                    }
                }
            }

            Rectangle {
                width: 6
                height: 6

                radius: 3

                color: "#ffffff"

                anchors.verticalCenter:
                        parent.verticalCenter

                x:
                    Math.max(
                        -3,
                        Math.min(
                            parent.width - 3,
                            parent.width
                            * root.progressRatio
                            - 3))

                Behavior on x {
                    NumberAnimation {
                        duration: 250
                    }
                }
            }
        }

        Text {
            id: totalTimeLabel

            anchors.right:
                    parent.right

            anchors.verticalCenter:
                    parent.verticalCenter

            text:
                root.formatTimeMs(
                    clusterMedia.durationMs)

            color: "#aaaaaa"

            font.pixelSize: 14
        }
    }

    /*
     * Live Android metadata.
     */
    Column {
        anchors.horizontalCenter:
                parent.horizontalCenter

        anchors.top:
                progressRow.bottom

        anchors.topMargin: 12

        spacing: 4

        Text {
            anchors.horizontalCenter:
                    parent.horizontalCenter

            text:
                clusterMedia.hasMedia
                ? (
                    clusterMedia.title.length > 0
                    ? clusterMedia.title
                    : "Unknown Track"
                  )
                : (
                    clusterMedia.connected
                    ? "No Media"
                    : "Waiting for Android Media"
                  )

            color: "#ffffff"

            font.pixelSize: 16
            font.bold: true
        }

        Text {
            anchors.horizontalCenter:
                    parent.horizontalCenter

            text:
                clusterMedia.hasMedia
                ? (
                    clusterMedia.artist.length > 0
                    ? clusterMedia.artist
                    : "Unknown Artist"
                  )
                : (
                    clusterMedia.connected
                    ? "HNMC Connected"
                    : "HNMC :6300"
                  )

            color: "#888899"

            font.pixelSize: 11
        }

        Text {
            anchors.horizontalCenter:
                    parent.horizontalCenter

            visible:
                clusterMedia.hasMedia
                && clusterMedia.album.length > 0

            text:
                clusterMedia.album

            color: "#666677"

            font.pixelSize: 9
        }
    }
}
