// Ported verbatim from 02-Digital-Cluster's Content_Area/ContactsView.qml.
// `import Backend 1.0` -> `import QnxCluster` (this project's module name);
// otherwise unchanged. Binds to VehicleData.contactsModel (QAbstractListModel,
// src/Backend/ContentArea/ContactsModel) and VehicleData.steeringWheel
// (UDP input, src/Backend/SteeringWheelController) for up/down navigation.
import QtQuick
import QnxCluster

Item {
    id: contactsView

    Connections {
        target: VehicleData.steeringWheel
        function onUpPressed() {
            if (contactsView.visible && contactList.currentIndex > 0) {
                contactList.currentIndex -= 1
            }
        }
        function onDownPressed() {
            if (contactsView.visible && contactList.currentIndex < contactList.count - 1) {
                contactList.currentIndex += 1
            }
        }
    }

    Text {
        id: title
        text: "📞 Contacts"
        color: "#ffffff"
        font.pixelSize: 24
        font.bold: true
        anchors.top: parent.top
        anchors.topMargin: 40
        anchors.horizontalCenter: parent.horizontalCenter
    }

    ListView {
        id: contactList
        anchors.top: title.bottom
        anchors.topMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        width: 320
        height: 4 * 60 + 3 * 10

        spacing: 10
        model: VehicleData.contactsModel
        clip: true

        delegate: ContactItem {
            contactName: contactNameRole
            contactNumber: contactNumberRole
            isSelected: ListView.isCurrentItem
        }

        highlightMoveDuration: 200
        preferredHighlightBegin: height / 2 - 30
        preferredHighlightEnd: height / 2 + 30
        highlightRangeMode: ListView.ApplyRange
    }

    Rectangle {
        id: scrollTrack
        anchors.left: contactList.right
        anchors.leftMargin: 10
        anchors.top: contactList.top
        anchors.bottom: contactList.bottom
        width: 4
        radius: 2
        color: "#2a2a3a"
        visible: contactList.contentHeight > contactList.height

        Rectangle {
            id: scrollThumb
            width: parent.width
            radius: 2
            color: "#ffffff"
            height: Math.max(20, (contactList.height / contactList.contentHeight) * scrollTrack.height)
            y: (contactList.contentY / Math.max(1, contactList.contentHeight - contactList.height)) * (scrollTrack.height - height)
        }
    }
}
