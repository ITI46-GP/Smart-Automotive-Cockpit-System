import QtQuick

Item {
    id: contactsView

    property var contacts: [
        { name: "John Doe",     number: "+1 555 0101" },
        { name: "Jane Smith",   number: "+1 555 0202" },
        { name: "Mike Johnson", number: "+1 555 0303" }
    ]

    Column {
        anchors.centerIn: parent
        spacing: 20

        Text {
            text: "📞 Contacts"
            color: "#ffffff"
            font.pixelSize: 24
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Repeater {
            model: contactsView.contacts

            ContactItem {
                contactName: modelData.name
                contactNumber: modelData.number
            }
        }
    }
}
