// Android MapLibre frames arrive through isolated HNMF / TCP 6201. HNCL/6200
// remains responsible only for navigation state and view selection.
import QtQuick
import QnxCluster

Item {
    id: mapView

    Component.onCompleted: console.log("HNMF MapView region", width, "x", height, "aspect", width / height)

    Rectangle {
        anchors.fill: parent
        color: "#15151f"
        clip: true

        // Valid HNMF frames are authoritative: no mock backdrop, route artwork, or text is layered below.
        Image {
            anchors.fill: parent
            visible: mapFrames.hasFrame
            source: visible ? mapFrames.imageUrl : ""
            cache: false
            sourceSize.width: Math.ceil(width)
            sourceSize.height: Math.ceil(height)
            fillMode: Image.PreserveAspectCrop
            smooth: true
            mipmap: false
        }

        Text {
            anchors.centerIn: parent
            visible: mapFrames.hasFrame === false
            text: "Waiting for Android navigation map"
            color: Theme.colorTextSecondary
            font.family: Theme.fontPrimary
            font.pixelSize: 16
        }
    }
}
