import QtQuick

Rectangle {
    id: btn
    width: 60
    height: 38
    radius: 19
    color: selected ? "#ffffff" : "transparent"

    property url iconSourceunSelected: ""
    property url iconSourceSelected: ""
    property int iconSize: 20
    property bool selected: false

    signal clicked()

    Image {
        id: iconImage
        anchors.centerIn: parent
        width: btn.iconSize
        height: btn.iconSize
        source: btn.selected ? btn.iconSourceSelected : btn.iconSourceunSelected
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: btn.clicked()
    }

    Behavior on color {
        ColorAnimation { duration: 200 }
    }
}
