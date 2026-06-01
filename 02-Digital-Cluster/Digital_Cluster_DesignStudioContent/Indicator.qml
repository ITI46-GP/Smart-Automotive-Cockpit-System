import QtQuick

Rectangle {
    enum Property_1 { Property_1_fuelIndicator_0, Property_1_fuelIndicator_100, Property_1_fuelIndicator_25, Property_1_fuelIndicator_50, Property_1_fuelIndicator_75}

    id: indicator

    property alias fuelIndicator_100Visible: fuelIndicator_100.visible

    property int property_2: Indicator.Property_1.Property_1_fuelIndicator_100

    height: 20.07
    width: 162.36

    color: "transparent"

    states: [
        State {
            name: "Property 1=fuelIndicator_100"
            when: indicator.property_2 === Indicator.Property_1.Property_1_fuelIndicator_100

            PropertyChanges {
                width: 162.36

                target: indicator
            }
            PropertyChanges {
                height: 20.07

                target: indicator
            }
            PropertyChanges {
                target: fuelIndicator_100
                visible: true
            }
            PropertyChanges {
                target: fuelIndicator_0
                visible: false
            }
            PropertyChanges {
                target: fuelIndicator_25
                visible: false
            }
            PropertyChanges {
                target: fuelIndicator_50
                visible: false
            }
            PropertyChanges {
                target: fuelIndicator_75
                visible: false
            }
        },
        State {
            name: "Property 1=fuelIndicator_0"
            when: indicator.property_2 === Indicator.Property_1.Property_1_fuelIndicator_0

            PropertyChanges {
                width: 7.70

                target: indicator
            }
            PropertyChanges {
                height: 6.37

                target: indicator
            }
            PropertyChanges {
                target: fuelIndicator_100
                visible: false
            }
            PropertyChanges {
                target: fuelIndicator_0
                visible: true
            }
            PropertyChanges {
                target: fuelIndicator_25
                visible: false
            }
            PropertyChanges {
                target: fuelIndicator_50
                visible: false
            }
            PropertyChanges {
                target: fuelIndicator_75
                visible: false
            }
        },
        State {
            name: "Property 1=fuelIndicator_25"
            when: indicator.property_2 === Indicator.Property_1.Property_1_fuelIndicator_25

            PropertyChanges {
                width: 40.62

                target: indicator
            }
            PropertyChanges {
                height: 15.99

                target: indicator
            }
            PropertyChanges {
                target: fuelIndicator_100
                visible: false
            }
            PropertyChanges {
                target: fuelIndicator_0
                visible: false
            }
            PropertyChanges {
                target: fuelIndicator_25
                visible: true
            }
            PropertyChanges {
                target: fuelIndicator_50
                visible: false
            }
            PropertyChanges {
                target: fuelIndicator_75
                visible: false
            }
        },
        State {
            name: "Property 1=fuelIndicator_50"
            when: indicator.property_2 === Indicator.Property_1.Property_1_fuelIndicator_50

            PropertyChanges {
                width: 81.18

                target: indicator
            }
            PropertyChanges {
                height: 20.07

                target: indicator
            }
            PropertyChanges {
                target: fuelIndicator_100
                visible: false
            }
            PropertyChanges {
                target: fuelIndicator_0
                visible: false
            }
            PropertyChanges {
                target: fuelIndicator_25
                visible: false
            }
            PropertyChanges {
                target: fuelIndicator_50
                visible: true
            }
            PropertyChanges {
                target: fuelIndicator_75
                visible: false
            }
        },
        State {
            name: "Property 1=fuelIndicator_75"
            when: indicator.property_2 === Indicator.Property_1.Property_1_fuelIndicator_75

            PropertyChanges {
                width: 122.56

                target: indicator
            }
            PropertyChanges {
                height: 20.07

                target: indicator
            }
            PropertyChanges {
                target: fuelIndicator_100
                visible: false
            }
            PropertyChanges {
                target: fuelIndicator_0
                visible: false
            }
            PropertyChanges {
                target: fuelIndicator_25
                visible: false
            }
            PropertyChanges {
                target: fuelIndicator_50
                visible: false
            }
            PropertyChanges {
                target: fuelIndicator_75
                visible: true
            }
        }
    ]

    Image {
        id: fuelIndicator_100

        y: -0.01

        source: Qt.resolvedUrl("assets/fuelIndicator_100.png")
        visible: true

        transform: Scale {
            origin.x: fuelIndicator_100.width / 2
            origin.y: fuelIndicator_100.height / 2
            xScale: -1
        }
    }
    Image {
        id: fuelIndicator_0

        y: 0.01

        source: Qt.resolvedUrl("assets/fuelIndicator_0.png")

        transform: Scale {
            origin.x: fuelIndicator_0.width / 2
            origin.y: fuelIndicator_0.height / 2
            xScale: -1
        }
    }
    Image {
        id: fuelIndicator_25

        y: 0.01

        source: Qt.resolvedUrl("assets/fuelIndicator_25.png")

        transform: Scale {
            origin.x: fuelIndicator_25.width / 2
            origin.y: fuelIndicator_25.height / 2
            xScale: -1
        }
    }
    Image {
        id: fuelIndicator_50

        y: -0.01

        source: Qt.resolvedUrl("assets/fuelIndicator_50.png")

        transform: Scale {
            origin.x: fuelIndicator_50.width / 2
            origin.y: fuelIndicator_50.height / 2
            xScale: -1
        }
    }
    Image {
        id: fuelIndicator_75

        y: -0.01

        source: Qt.resolvedUrl("assets/fuelIndicator_75.png")

        transform: Scale {
            origin.x: fuelIndicator_75.width / 2
            origin.y: fuelIndicator_75.height / 2
            xScale: -1
        }
    }
}
