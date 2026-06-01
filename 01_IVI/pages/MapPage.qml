pragma ComponentBehavior: Bound

import QtQuick
import QtLocation
import QtPositioning

Item {
    id: root
    width: 1024
    height: 600

    signal backClicked()
    signal keyboardRequested(var textInput)

    property color bg: "#07000E"
    property color panel: "#090613"
    property color line: "#342544"
    property color text: "#CBC4CD"
    property color brightText: "#F4EEF7"
    property color muted: "#8F7AA8"
    property color violet: "#8B5CF6"
    property color cyan: "#21D4FD"
    property color green: "#38E8A5"
    property color amber: "#FFB454"
    property color red: "#A6080D"

    property string fromDraft: "Cairo"
    property string destinationDraft: navigationManager.destination.length > 0 ? navigationManager.destination : "Nasr City"
    property bool trafficOn: true
    property bool manualSourceActive: true

    readonly property bool routeLoading: navigationManager.routeLoading
    readonly property bool routeActive: navigationManager.routeActive
    readonly property string routeError: navigationManager.routeError
    readonly property real distanceKm: navigationManager.distanceKm
    readonly property int etaMinutes: navigationManager.etaMinutes
    readonly property string displayDestination: navigationManager.destination.length > 0 ? navigationManager.destination : destinationDraft

    readonly property real fallbackLat: 30.0444
    readonly property real fallbackLon: 31.2357

    readonly property real currentLat: validCoordinate(navigationManager.currentLatitude, navigationManager.currentLongitude)
                                       ? navigationManager.currentLatitude
                                       : fallbackLat
    readonly property real currentLon: validCoordinate(navigationManager.currentLatitude, navigationManager.currentLongitude)
                                       ? navigationManager.currentLongitude
                                       : fallbackLon

    readonly property bool hasDestinationCoord: validCoordinate(navigationManager.destinationLatitude,
                                                                 navigationManager.destinationLongitude)

    readonly property var currentCoordinate: QtPositioning.coordinate(currentLat, currentLon)
    readonly property var destinationCoordinate: hasDestinationCoord
                                                 ? QtPositioning.coordinate(navigationManager.destinationLatitude,
                                                                           navigationManager.destinationLongitude)
                                                 : currentCoordinate

    property var mapRoutePath: buildRoutePath(navigationManager.routePath)

    readonly property string gpsStatus: manualSourceActive
                                        ? "MANUAL"
                                        : (navigationManager.currentLocationValid ? "REAL" : "FALLBACK")

    readonly property color gpsColor: manualSourceActive
                                      ? root.cyan
                                      : (navigationManager.currentLocationValid ? root.green : root.amber)

    function validCoordinate(lat, lon) {
        return isFinite(lat) && isFinite(lon)
                && Math.abs(lat) <= 90
                && Math.abs(lon) <= 180
                && !(Math.abs(lat) < 0.000001 && Math.abs(lon) < 0.000001)
    }

    function normalizedName(value) {
        return value.toString().trim().toLowerCase()
    }

    function coordinateForPlace(placeName) {
        var name = normalizedName(placeName)

        if (name === "cairo" || name === "cairo, egypt")
            return { found: true, lat: 30.0444, lon: 31.2357 }

        if (name === "maadi")
            return { found: true, lat: 29.9602, lon: 31.2569 }

        if (name === "helwan")
            return { found: true, lat: 29.8414, lon: 31.3008 }

        if (name === "nasr city")
            return { found: true, lat: 30.0566, lon: 31.3301 }

        if (name === "new cairo")
            return { found: true, lat: 30.0074, lon: 31.4913 }

        if (name === "iti" || name === "iti campus")
            return { found: true, lat: 30.0725, lon: 31.0211 }

        if (name === "smart village")
            return { found: true, lat: 30.0721, lon: 31.0189 }

        if (name === "charging station")
            return { found: true, lat: 30.0622, lon: 31.0401 }

        if (name === "cairo festival city")
            return { found: true, lat: 30.0286, lon: 31.4078 }

        if (name === "home")
            return { found: true, lat: 30.0626, lon: 31.2497 }

        return { found: false, lat: fallbackLat, lon: fallbackLon }
    }

    function applySourceLocation() {
        var src = coordinateForPlace(fromDraft)

        if (src.found) {
            manualSourceActive = true
            navigationManager.setCurrentLocation(src.lat, src.lon)
            return true
        }

        manualSourceActive = false
        return false
    }

    function buildRoutePath(source) {
        var out = []

        if (!source)
            return out

        for (var i = 0; i < source.length; ++i) {
            var p = source[i]

            if (!p)
                continue

            if (p.latitude !== undefined && p.longitude !== undefined) {
                out.push(QtPositioning.coordinate(p.latitude, p.longitude))
            } else if (p.lat !== undefined && p.lon !== undefined) {
                out.push(QtPositioning.coordinate(p.lat, p.lon))
            } else if (p.lat !== undefined && p.lng !== undefined) {
                out.push(QtPositioning.coordinate(p.lat, p.lng))
            } else if (p.length !== undefined && p.length >= 2) {
                out.push(QtPositioning.coordinate(p[1], p[0]))
            }
        }

        return out
    }

    function mapCenterCoordinate() {
        if (routeActive && hasDestinationCoord) {
            return QtPositioning.coordinate(
                        (currentLat + navigationManager.destinationLatitude) / 2.0,
                        (currentLon + navigationManager.destinationLongitude) / 2.0
                    )
        }

        return currentCoordinate
    }

    function requestRoute(name) {
        var cleanName = name.trim()

        if (cleanName.length === 0) {
            clearRoute()
            return
        }

        destinationDraft = cleanName
        applySourceLocation()
        navigationManager.setRouteDestination(cleanName)
    }

    function quickRoute(name) {
        destinationDraft = name
        destinationInput.text = name
        applySourceLocation()
        navigationManager.setQuickDestination(name)
    }

    function clearRoute() {
        destinationDraft = ""
        navigationManager.clearRoute()
    }

    Rectangle {
        anchors.fill: parent
        color: root.bg
    }

    Rectangle {
        anchors.fill: parent
        opacity: 0.58
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#171022" }
            GradientStop { position: 0.48; color: "#090613" }
            GradientStop { position: 1.0; color: "#050009" }
        }
    }

    PositionSource {
        id: positionSource
        active: !root.manualSourceActive
        updateInterval: 5000

        onPositionChanged: {
            if (position.coordinate.isValid && !root.manualSourceActive) {
                navigationManager.setCurrentLocation(position.coordinate.latitude,
                                                     position.coordinate.longitude)
            }
        }
    }

    Plugin {
        id: osmPlugin
        name: "osm"

        PluginParameter {
            name: "osm.useragent"
            value: "GP_IVI_Navigation"
        }
    }

    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        anchors.topMargin: 18
        height: 54

        TouchIconButton {
            id: backButton
            width: 52
            height: 52
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            iconText: "<"
            onClicked: root.backClicked()
        }

        Column {
            anchors.left: backButton.right
            anchors.leftMargin: 16
            anchors.right: headerStatus.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                text: "LIVE NAVIGATION"
                color: root.muted
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 2.0
            }

            Text {
                width: parent.width
                text: root.routeActive ? ("Route to " + root.displayDestination) : "OSM Route Planner"
                color: root.brightText
                font.pixelSize: 24
                font.bold: true
                elide: Text.ElideRight
            }
        }

        Row {
            id: headerStatus
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            HeaderPill {
                width: 132
                title: "MAP"
                value: "OSM"
                active: true
                accent: root.cyan
            }

            HeaderPill {
                width: 132
                title: "GPS"
                value: root.gpsStatus
                active: true
                accent: root.gpsColor
            }
        }
    }

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        anchors.topMargin: 16
        anchors.bottomMargin: 24
        spacing: 20

        Rectangle {
            id: controlPanel
            width: 292
            height: parent.height
            radius: 26
            color: root.panel
            border.color: root.line
            border.width: 1
            clip: true

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                opacity: 0.45
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#241238" }
                    GradientStop { position: 0.54; color: "#111023" }
                    GradientStop { position: 1.0; color: "#080512" }
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 10

                LabelText { text: "FROM" }

                InputShell {
                    width: parent.width
                    height: 46
                    active: fromInput.activeFocus

                    TextInput {
                        id: fromInput
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        text: root.fromDraft
                        color: root.brightText
                        selectionColor: root.violet
                        selectedTextColor: "#FFFFFF"
                        font.pixelSize: 14
                        clip: true

                        onActiveFocusChanged: if (activeFocus) root.keyboardRequested(fromInput)
                        onTextChanged: root.fromDraft = text
                        onAccepted: root.requestRoute(destinationInput.text)
                    }
                }

                LabelText { text: "TO" }

                InputShell {
                    width: parent.width
                    height: 46
                    active: destinationInput.activeFocus

                    TextInput {
                        id: destinationInput
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        text: root.destinationDraft
                        color: root.brightText
                        selectionColor: root.violet
                        selectedTextColor: "#FFFFFF"
                        font.pixelSize: 14
                        clip: true

                        onActiveFocusChanged: if (activeFocus) root.keyboardRequested(destinationInput)
                        onTextChanged: root.destinationDraft = text
                        onAccepted: root.requestRoute(destinationInput.text)
                    }
                }

                Row {
                    width: parent.width
                    height: 40
                    spacing: 10

                    TouchPillButton {
                        width: (parent.width - 10) / 2
                        height: 40
                        text: root.routeLoading ? "LOADING" : "UPDATE"
                        active: true
                        onClicked: root.requestRoute(destinationInput.text)
                    }

                    TouchPillButton {
                        width: (parent.width - 10) / 2
                        height: 40
                        text: "CLEAR"
                        onClicked: root.clearRoute()
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 92
                    radius: 20
                    color: "#080512"
                    border.color: root.routeError.length > 0 ? root.red
                                  : (root.routeActive || root.routeLoading ? root.cyan : root.line)
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        Text {
                            width: parent.width
                            text: root.routeLoading ? "CALCULATING"
                                  : (root.routeError.length > 0 ? "CHECK"
                                     : (root.routeActive ? "ACTIVE ROUTE" : "READY"))
                            color: root.routeError.length > 0 ? root.red
                                  : (root.routeActive || root.routeLoading ? root.cyan : root.muted)
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1.8
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: root.displayDestination.length > 0 ? root.displayDestination : "No destination selected"
                            color: root.brightText
                            font.pixelSize: 15
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Row {
                            width: parent.width
                            height: 30
                            spacing: 8

                            RouteMiniMetric {
                                width: (parent.width - 16) / 3
                                title: "ETA"
                                value: root.routeLoading ? "..." : (root.routeActive ? root.etaMinutes + "m" : "--")
                            }

                            RouteMiniMetric {
                                width: (parent.width - 16) / 3
                                title: "DIST"
                                value: root.routeLoading ? "..." : (root.routeActive ? root.distanceKm.toFixed(1) + "km" : "--")
                            }

                            RouteMiniMetric {
                                width: (parent.width - 16) / 3
                                title: "MAP"
                                value: "OSM"
                                accent: root.cyan
                            }
                        }
                    }
                }

                LabelText { text: "QUICK DESTINATIONS" }

                Flickable {
                    id: quickList
                    width: parent.width
                    height: 154
                    contentWidth: width
                    contentHeight: quickColumn.height
                    clip: true

                    Column {
                        id: quickColumn
                        width: quickList.width
                        spacing: 8

                        Repeater {
                            model: [
                                { "title": "Maadi", "subtitle": "South Cairo" },
                                { "title": "Helwan", "subtitle": "South Cairo" },
                                { "title": "Cairo", "subtitle": "City center" },
                                { "title": "Home", "subtitle": "Saved place" },
                                { "title": "ITI Campus", "subtitle": "Training destination" },
                                { "title": "Smart Village", "subtitle": "West Cairo tech park" },
                                { "title": "Charging Station", "subtitle": "Nearby charger" },
                                { "title": "Cairo Festival City", "subtitle": "East Cairo" },
                                { "title": "New Cairo", "subtitle": "District route" },
                                { "title": "Nasr City", "subtitle": "Urban route" }
                            ]

                            DestinationButton {
                                required property var modelData
                                width: quickColumn.width
                                height: 36
                                title: modelData.title
                                subtitle: modelData.subtitle
                                active: root.displayDestination === modelData.title

                                onClicked: root.quickRoute(modelData.title)
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 40
                    radius: 17
                    color: "#080512"
                    border.color: root.gpsColor
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        StatusDot {
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.gpsColor
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 24
                            text: root.manualSourceActive
                                  ? ("SOURCE: " + root.fromDraft)
                                  : (navigationManager.currentLocationValid ? "GPS REAL LOCATION" : "GPS FALLBACK: CAIRO")
                            color: root.brightText
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1.1
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        Rectangle {
            id: mapFrame
            width: parent.width - controlPanel.width - parent.spacing
            height: parent.height
            radius: 26
            color: root.panel
            border.color: root.line
            border.width: 1
            clip: true

            Map {
                id: realMap
                anchors.fill: parent
                plugin: osmPlugin
                center: root.mapCenterCoordinate()
                zoomLevel: 12
                copyrightsVisible: false

                property point lastDragTranslation: Qt.point(0, 0)
                property var pinchStartCoordinate: QtPositioning.coordinate(root.currentLat, root.currentLon)

                DragHandler {
                    id: dragHandler
                    target: null

                    onActiveChanged: {
                        realMap.lastDragTranslation = Qt.point(0, 0)
                    }

                    onTranslationChanged: {
                        var dx = translation.x - realMap.lastDragTranslation.x
                        var dy = translation.y - realMap.lastDragTranslation.y

                        realMap.pan(-dx, -dy)

                        realMap.lastDragTranslation = Qt.point(translation.x, translation.y)
                    }
                }

                PinchHandler {
                    id: pinchHandler
                    target: null

                    onActiveChanged: {
                        if (active) {
                            realMap.pinchStartCoordinate = realMap.toCoordinate(pinchHandler.centroid.position, false)
                        }
                    }

                    onScaleChanged: function(delta) {
                        realMap.zoomLevel = Math.max(
                            realMap.minimumZoomLevel,
                            Math.min(realMap.maximumZoomLevel, realMap.zoomLevel + Math.log2(delta))
                        )

                        realMap.alignCoordinateToPoint(realMap.pinchStartCoordinate, pinchHandler.centroid.position)
                    }
                }

                WheelHandler {
                    id: wheelHandler
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    orientation: Qt.Vertical

                    onWheel: function(event) {
                        realMap.zoomLevel = Math.max(
                            realMap.minimumZoomLevel,
                            Math.min(realMap.maximumZoomLevel, realMap.zoomLevel + event.angleDelta.y / 120)
                        )
                    }
                }

                Timer {
                    id: fitRouteTimer
                    interval: 120
                    repeat: false

                    onTriggered: {
                        if (root.routeActive && root.hasDestinationCoord) {
                            realMap.visibleRegion = QtPositioning.rectangle(
                                root.currentCoordinate,
                                root.destinationCoordinate
                            )
                        }
                    }
                }

                Connections {
                    target: navigationManager

                    function onRoutePathChanged() {
                        fitRouteTimer.restart()
                    }

                    function onDestinationLatitudeChanged() {
                        fitRouteTimer.restart()
                    }

                    function onDestinationLongitudeChanged() {
                        fitRouteTimer.restart()
                    }
                }
                MapPolyline {
                    id: routeGlow
                    visible: root.routeActive && root.mapRoutePath.length > 1
                    line.width: 8
                    line.color: root.cyan
                    opacity: 0.72
                    path: root.mapRoutePath
                }

                MapPolyline {
                    id: routeLine
                    visible: root.routeActive && root.mapRoutePath.length > 1
                    line.width: 3
                    line.color: root.violet
                    path: root.mapRoutePath
                }

                MapQuickItem {
                    coordinate: root.currentCoordinate
                    anchorPoint.x: 12
                    anchorPoint.y: 12

                    sourceItem: Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: "#5521D4FD"
                        border.color: root.cyan
                        border.width: 2

                        Rectangle {
                            anchors.centerIn: parent
                            width: 10
                            height: 10
                            radius: 5
                            color: root.cyan
                            border.color: "#FFFFFF"
                            border.width: 2
                        }
                    }
                }

                MapQuickItem {
                    visible: root.routeActive && root.hasDestinationCoord
                    coordinate: root.destinationCoordinate
                    anchorPoint.x: 12
                    anchorPoint.y: 12

                    sourceItem: Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: "#558B5CF6"
                        border.color: root.violet
                        border.width: 2

                        Rectangle {
                            anchors.centerIn: parent
                            width: 11
                            height: 11
                            radius: 6
                            color: root.violet
                            border.color: "#FFFFFF"
                            border.width: 2
                        }
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.leftMargin: 22
                anchors.topMargin: 20
                width: 286
                height: 70
                radius: 22
                color: "#0A0712"
                border.color: root.line
                border.width: 1
                opacity: 0.94

                Column {
                    anchors.fill: parent
                    anchors.margins: 13
                    spacing: 3

                    Text {
                        width: parent.width
                        text: "OSM PLUGIN MAP"
                        color: root.cyan
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1.6
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.displayDestination.length > 0 ? root.displayDestination : "Cairo navigation"
                        color: root.brightText
                        font.pixelSize: 16
                        font.bold: true
                        elide: Text.ElideRight
                    }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 22
                anchors.topMargin: 20
                spacing: 10

                MapChip {
                    width: 116
                    text: "TRAFFIC"
                    subText: root.trafficOn ? "MOCK ON" : "MOCK OFF"
                    active: root.trafficOn
                    onClicked: root.trafficOn = !root.trafficOn
                }
            }

            Column {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 22
                spacing: 10

                MapRoundButton {
                    text: "+"
                    onClicked: realMap.zoomLevel = Math.min(realMap.maximumZoomLevel, realMap.zoomLevel + 1)
                }

                MapRoundButton {
                    text: "-"
                    onClicked: realMap.zoomLevel = Math.max(realMap.minimumZoomLevel, realMap.zoomLevel - 1)
                }

                MapRoundButton {
                    text: "C"
                    subText: "SRC"
                    onClicked: realMap.center = root.currentCoordinate
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 22
                anchors.rightMargin: 104
                anchors.bottomMargin: 22
                height: 62
                radius: 21
                color: "#0A0712"
                border.color: root.routeError.length > 0 ? root.red
                              : (root.routeActive || root.routeLoading ? root.cyan : root.line)
                border.width: 1
                opacity: 0.96

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 14

                    RouteFooterMetric {
                        width: 84
                        anchors.verticalCenter: parent.verticalCenter
                        title: "ETA"
                        value: root.routeLoading ? "..." : (root.routeActive ? root.etaMinutes + " min" : "--")
                    }

                    RouteFooterMetric {
                        width: 104
                        anchors.verticalCenter: parent.verticalCenter
                        title: "DIST"
                        value: root.routeLoading ? "..." : (root.routeActive ? root.distanceKm.toFixed(1) + " km" : "--")
                    }

                    Rectangle {
                        width: 1
                        height: 34
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.line
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 230
                        text: root.routeError.length > 0
                              ? root.routeError
                              : (root.mapRoutePath.length > 1
                                 ? "Route geometry loaded from backend."
                                 : "OSM map active. Select destination to load route.")
                        color: root.routeError.length > 0 ? root.red : root.muted
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.leftMargin: 24
                anchors.bottomMargin: 92
                width: 210
                height: 24
                radius: 12
                color: "#0A0712"
                opacity: 0.82

                Text {
                    anchors.centerIn: parent
                    text: "© OpenStreetMap contributors"
                    color: root.muted
                    font.pixelSize: 9
                }
            }
        }
    }

    component LabelText: Text {
        color: root.muted
        font.pixelSize: 11
        font.bold: true
        font.letterSpacing: 2.0
        elide: Text.ElideRight
    }

    component StatusDot: Rectangle {
        width: 8
        height: 8
        radius: 4
    }

    component InputShell: Rectangle {
        id: inputShell
        property bool active: false
        radius: 16
        color: "#07040D"
        border.color: inputShell.active ? root.cyan : root.line
        border.width: 1
    }

    component HeaderPill: Rectangle {
        id: pill
        property string title: ""
        property string value: ""
        property bool active: false
        property color accent: root.cyan

        height: 38
        radius: 19
        color: "#0A0712"
        border.color: pill.accent
        border.width: 1
        opacity: pill.active ? 1.0 : 0.84

        Row {
            anchors.centerIn: parent
            spacing: 8

            StatusDot {
                anchors.verticalCenter: parent.verticalCenter
                color: pill.accent
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    text: pill.title
                    color: root.muted
                    font.pixelSize: 7
                    font.bold: true
                    font.letterSpacing: 1.2
                }

                Text {
                    text: pill.value
                    color: pill.accent
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1.2
                }
            }
        }
    }

    component TouchIconButton: Item {
        id: iconBtn
        property string iconText: ""
        signal clicked()

        Rectangle {
            anchors.fill: parent
            radius: 17
            color: tap.pressed ? "#171025" : "#0A0712"
            border.color: tap.pressed ? root.violet : root.line
            border.width: 1
            scale: tap.pressed ? 0.94 : 1.0

            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

            Text {
                anchors.centerIn: parent
                text: iconBtn.iconText
                color: tap.pressed ? "#FFFFFF" : root.text
                font.pixelSize: 28
                font.bold: true
            }
        }

        TapHandler {
            id: tap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: iconBtn.clicked()
        }
    }

    component TouchPillButton: Item {
        id: pill
        property string text: ""
        property bool active: false
        signal clicked()

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: tap.pressed ? root.violet : (pill.active ? "#152030" : "#171025")
            border.color: tap.pressed ? "#B99CFF" : (pill.active ? root.cyan : "#352347")
            border.width: 1
            scale: tap.pressed ? 0.96 : 1.0

            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

            Text {
                anchors.centerIn: parent
                text: pill.text
                color: tap.pressed ? "#FFFFFF" : root.text
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1.4
            }
        }

        TapHandler {
            id: tap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: pill.clicked()
        }
    }

    component DestinationButton: Item {
        id: dest
        property string title: ""
        property string subtitle: ""
        property bool active: false
        signal clicked()

        Rectangle {
            anchors.fill: parent
            radius: 15
            color: tap.pressed ? "#171025" : (dest.active ? "#101A24" : "#080512")
            border.color: dest.active ? root.cyan : (tap.pressed ? root.violet : root.line)
            border.width: 1
            scale: tap.pressed ? 0.98 : 1.0

            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 13
                anchors.rightMargin: 12
                spacing: 10

                StatusDot {
                    anchors.verticalCenter: parent.verticalCenter
                    color: dest.active ? root.cyan : root.violet
                    opacity: dest.active ? 1.0 : 0.62
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 44
                    spacing: 1

                    Text {
                        width: parent.width
                        text: dest.title
                        color: root.brightText
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: dest.subtitle
                        color: root.muted
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ">"
                    color: tap.pressed ? root.cyan : root.muted
                    font.pixelSize: 16
                    font.bold: true
                }
            }
        }

        TapHandler {
            id: tap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: dest.clicked()
        }
    }

    component RouteMiniMetric: Rectangle {
        id: metric
        property string title: ""
        property string value: ""
        property color accent: root.brightText

        height: 30
        radius: 11
        color: "#06030B"
        border.color: root.line
        border.width: 1

        Column {
            anchors.centerIn: parent
            width: parent.width - 8
            spacing: 1

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: metric.title
                color: root.muted
                font.pixelSize: 7
                font.bold: true
                font.letterSpacing: 1.0
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                text: metric.value
                color: metric.accent
                font.pixelSize: 10
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }
    }

    component RouteFooterMetric: Item {
        id: metric
        property string title: ""
        property string value: ""

        height: 42

        Column {
            anchors.centerIn: parent
            width: parent.width
            spacing: 3

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: metric.title
                color: root.muted
                font.pixelSize: 8
                font.bold: true
                font.letterSpacing: 1.2
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                text: metric.value
                color: root.brightText
                font.pixelSize: 12
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }
    }

    component MapChip: Item {
        id: chip
        property string text: ""
        property string subText: ""
        property bool active: false
        signal clicked()

        height: 42

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: tap.pressed ? "#171025" : "#0A0712"
            border.color: chip.active ? root.cyan : root.line
            border.width: 1

            Column {
                anchors.centerIn: parent
                width: parent.width - 10
                spacing: 1

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    text: chip.text
                    color: chip.active ? root.cyan : root.brightText
                    font.pixelSize: 10
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    text: chip.subText
                    color: root.muted
                    font.pixelSize: 7
                    font.bold: true
                    font.letterSpacing: 0.8
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }
        }

        TapHandler {
            id: tap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: chip.clicked()
        }
    }

    component MapRoundButton: Item {
        id: roundBtn
        property string text: ""
        property string subText: ""
        signal clicked()

        width: 44
        height: 44

        Rectangle {
            anchors.fill: parent
            radius: 22
            color: tap.pressed ? root.violet : "#0A0712"
            border.color: tap.pressed ? "#B99CFF" : root.line
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: -1

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: roundBtn.text
                    color: root.brightText
                    font.pixelSize: roundBtn.subText.length > 0 ? 13 : 20
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: roundBtn.subText.length > 0
                    text: roundBtn.subText
                    color: root.muted
                    font.pixelSize: 7
                    font.bold: true
                }
            }
        }

        TapHandler {
            id: tap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: roundBtn.clicked()
        }
    }

    Component.onCompleted: {
        applySourceLocation()
    }
}
