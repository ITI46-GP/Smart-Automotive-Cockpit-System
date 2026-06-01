import QtQuick

Item {
    id: root
    width: 276
    height: 444

    signal mediaClicked()
    signal mapClicked()

    property color bg: "#07000E"
    property color panel: "#090613"
    property color line: "#342544"
    property color text: "#CBC4CD"
    property color muted: "#8F7AA8"
    property color violet: "#8B5CF6"
    property color cyan: "#21D4FD"
    property color red: "#A6080D"
    readonly property bool compact: width < 320 || height < 470
    readonly property real panelSpacing: compact ? 12 : 16
    readonly property real mediaHeight: compact ? 126 : 132

    // Live media mock state
    property bool isPlaying: audioManager.playing
    property real mediaProgress: audioManager.duration > 0 ? (audioManager.position / audioManager.duration) : 0.0
    property string songTitle: audioManager.currentSongTitle !== "" ? audioManager.currentSongTitle : "No Media Playing"
    property string songArtist: audioManager.currentSource
    property string songAlbum: "IVI System"

    // Live navigation mock state
    property bool routeActive: false
    property bool routeLoading: false
    property string routeError: ""
    property bool currentLocationValid: false
    property string currentLocation: "Current location"
    property string destination: ""
    property string etaText: "--"
    property string distanceText: "--"
    property var routePath: []
    readonly property bool hasRouteGeometry: routePath && routePath.length > 1
    readonly property string displayRouteError: routeError.indexOf("API") !== -1
                                               || routeError.indexOf("Routing service") !== -1
                                               ? "" : routeError

    property bool childTapActive: false

    Timer {
        id: childTapReleaseTimer
        interval: 90
        repeat: false
        onTriggered: root.childTapActive = false
    }

    function beginChildTap() {
        root.childTapActive = true
        childTapReleaseTimer.stop()
    }

    function endChildTap() {
        childTapReleaseTimer.restart()
    }

    Timer {
        interval: 900
        running: root.isPlaying
        repeat: true

        onTriggered: {
            root.mediaProgress += 0.015

            if (root.mediaProgress >= 1.0) {
                root.mediaProgress = 0.0
                root.nextTrack()
            }
        }
    }

    function playPause() {
        root.isPlaying = !root.isPlaying
    }

    function nextTrack() {
        root.trackIndex = (root.trackIndex + 1) % root.playlist.length
        root.mediaProgress = 0.0
    }

    function previousTrack() {
        root.trackIndex = (root.trackIndex - 1 + root.playlist.length) % root.playlist.length
        root.mediaProgress = 0.0
    }

    Column {
        anchors.fill: parent
        spacing: root.panelSpacing

        // Live Media Widget
        Rectangle {
            id: mediaCard
            width: parent.width
            height: root.mediaHeight
            radius: root.compact ? 22 : 28
            color: root.panel
            border.color: mediaTap.pressed ? root.violet : root.line
            border.width: 1
            scale: mediaTap.pressed ? 0.99 : 1.0
            transformOrigin: Item.Center

            Behavior on scale {
                NumberAnimation {
                    duration: 110
                    easing.type: Easing.OutQuad
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                opacity: mediaTap.pressed ? 0.52 : 0.36

                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#2A1742" }
                    GradientStop { position: 0.56; color: "#151023" }
                    GradientStop { position: 1.0; color: "#080512" }
                }
            }

            Rectangle {
                width: root.compact ? 88 : 112
                height: width
                radius: width / 2
                anchors.right: parent.right
                anchors.rightMargin: root.compact ? -24 : -34
                anchors.verticalCenter: parent.verticalCenter
                color: root.violet
                opacity: root.isPlaying ? 0.13 : 0.06
            }

            // album placeholder
            Rectangle {
                id: album
                width: root.compact ? 62 : 76
                height: width
                radius: root.compact ? 20 : 24
                anchors.left: parent.left
                anchors.leftMargin: root.compact ? 14 : 18
                anchors.verticalCenter: parent.verticalCenter
                color: "#171025"
                border.color: root.isPlaying ? root.violet : "#4B2C73"
                border.width: 1

                Rectangle {
                    width: root.compact ? 42 : 48
                    height: width
                    radius: width / 2
                    anchors.centerIn: parent
                    color: "#21152F"
                    border.color: "#4B2C73"
                    border.width: 1

                    Canvas {
                        anchors.fill: parent
                        opacity: 0.92

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)

                            ctx.strokeStyle = "#CBC4CD"
                            ctx.fillStyle = "#CBC4CD"
                            ctx.lineWidth = 1.8
                            ctx.lineCap = "round"

                            ctx.beginPath()
                            ctx.moveTo(18, 13)
                            ctx.lineTo(18, 31)
                            ctx.stroke()

                            ctx.beginPath()
                            ctx.moveTo(18, 13)
                            ctx.lineTo(32, 10)
                            ctx.lineTo(32, 27)
                            ctx.stroke()

                            ctx.beginPath()
                            ctx.arc(15, 32, 4, 0, Math.PI * 2)
                            ctx.fill()

                            ctx.beginPath()
                            ctx.arc(29, 28, 4, 0, Math.PI * 2)
                            ctx.fill()
                        }
                    }
                }
            }

            // song info - top area only
            Column {
                id: songInfo
                anchors.left: album.right
                anchors.leftMargin: root.compact ? 14 : 18
                anchors.right: parent.right
                anchors.rightMargin: root.compact ? 14 : 22
                anchors.top: parent.top
                anchors.topMargin: root.compact ? 16 : 18
                spacing: root.compact ? 3 : 4

                Text {
                    text: root.isPlaying ? "NOW PLAYING" : "PAUSED"
                    color: root.isPlaying ? root.cyan : root.muted
                    font.pixelSize: root.compact ? 9 : 10
                    font.bold: true
                    font.letterSpacing: root.compact ? 1.8 : 2.4
                }

                Text {
                    text: root.songTitle
                    color: "#F4EEF7"
                    font.pixelSize: root.compact ? 14 : 16
                    font.bold: true
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: root.songArtist + " · " + root.songAlbum
                    color: root.muted
                    font.pixelSize: root.compact ? 10 : 11
                    elide: Text.ElideRight
                    width: parent.width
                    opacity: 0.92
                }
            }

            // bottom control strip
            // bottom control strip Linked to C++
            Row {
                id: mediaControls
                anchors.left: album.right
                anchors.leftMargin: root.compact ? 14 : 18
                anchors.bottom: parent.bottom
                anchors.bottomMargin: root.compact ? 14 : 16
                spacing: root.compact ? 9 : 12

                MediaControlButton {
                    icon: "‹"
                    onClicked: audioManager.prev()
                }

                MediaControlButton {
                    icon: audioManager.playing ? "Ⅱ" : "▶"
                    active: true
                    onClicked: audioManager.togglePlayPause()
                }

                MediaControlButton {
                    icon: "›"
                    onClicked: audioManager.next()
                }
            }

            // progress bar separated from buttons
            Rectangle {
                width: root.compact ? 52 : 86
                height: 4
                radius: 2
                anchors.right: parent.right
                anchors.rightMargin: root.compact ? 14 : 24
                anchors.verticalCenter: mediaControls.verticalCenter
                color: "#342544"

                Rectangle {
                    width: parent.width * root.mediaProgress
                    height: parent.height
                    radius: 2
                    color: audioManager.playing ? root.cyan : root.muted
                    opacity: audioManager.playing ? 0.9 : 0.45
                }
            }

            // progress bar separated from buttons
            Rectangle {
                width: root.compact ? 52 : 86
                height: 4
                radius: 2
                anchors.right: parent.right
                anchors.rightMargin: root.compact ? 14 : 24
                anchors.verticalCenter: mediaControls.verticalCenter
                color: "#342544"

                Rectangle {
                    width: parent.width * root.mediaProgress
                    height: parent.height
                    radius: 2
                    color: root.isPlaying ? root.cyan : root.muted
                    opacity: root.isPlaying ? 0.9 : 0.45
                }
            }

            TapHandler {
                id: mediaTap
                gesturePolicy: TapHandler.ReleaseWithinBounds

                onTapped: {
                    if (!root.childTapActive) {
                        root.mediaClicked()
                    }
                }
            }
        }

        // Live Navigation Widget
        Rectangle {
            id: mapCard
            width: parent.width
            height: parent.height - mediaCard.height - root.panelSpacing
            radius: root.compact ? 24 : 30
            color: root.panel
            border.color: mapTap.pressed ? root.violet : root.line
            border.width: 1
            clip: true
            scale: mapTap.pressed ? 0.99 : 1.0
            transformOrigin: Item.Center

            Behavior on scale {
                NumberAnimation {
                    duration: 110
                    easing.type: Easing.OutQuad
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                opacity: 0.72

                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#13202C" }
                    GradientStop { position: 0.50; color: "#0B1020" }
                    GradientStop { position: 1.0; color: "#07000E" }
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: root.compact ? 13 : 16
                spacing: root.compact ? 8 : 10

                Row {
                    width: parent.width
                    height: 28

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 92
                        text: "NAVIGATION"
                        color: root.muted
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 2.0
                    }

                    RouteStatePill {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 92
                        text: root.routeLoading ? "LOADING" : (root.routeActive ? "ACTIVE" : (root.displayRouteError.length > 0 ? "CHECK" : "READY"))
                        active: root.routeActive || root.routeLoading
                        alert: root.displayRouteError.length > 0
                    }
                }

                Rectangle {
                    width: parent.width
                    height: root.compact ? 104 : 122
                    radius: root.compact ? 19 : 22
                    color: "#080512"
                    border.color: root.displayRouteError.length > 0 ? root.red : (root.routeActive ? root.cyan : "#342544")
                    border.width: 1

                    RoutePreviewCanvas {
                        anchors.fill: parent
                        anchors.margins: 1
                        routePath: root.routePath
                        routeActive: root.routeActive
                        routeLoading: root.routeLoading
                        routeError: root.displayRouteError
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "#05020B"
                        opacity: 0.18
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: root.compact ? 12 : 14
                        anchors.rightMargin: root.compact ? 12 : 14
                        anchors.bottomMargin: root.compact ? 10 : 12
                        spacing: 3

                        Text {
                            width: parent.width
                            text: root.displayRouteError.length > 0
                                  ? root.displayRouteError
                                  : (root.routeLoading ? "Preparing route" : (root.routeActive ? root.destination : "Open route planner"))
                            color: root.displayRouteError.length > 0 ? root.red : "#F4EEF7"
                            font.pixelSize: root.compact ? 13 : 15
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: root.currentLocationValid ? "GPS REAL" : "GPS FALLBACK"
                            color: root.currentLocationValid ? root.cyan : root.muted
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1.4
                        }
                    }
                }

                Row {
                    width: parent.width
                    height: root.compact ? 54 : 60
                    spacing: root.compact ? 8 : 10

                    RouteMetricTile {
                        width: (parent.width - parent.spacing * 2) / 3
                        title: "ETA"
                        value: root.routeLoading ? "..." : root.etaText
                    }

                    RouteMetricTile {
                        width: (parent.width - parent.spacing * 2) / 3
                        title: "DIST"
                        value: root.routeLoading ? "..." : root.distanceText
                    }

                    RouteMetricTile {
                        width: (parent.width - parent.spacing * 2) / 3
                        title: "PATH"
                        value: root.routeLoading ? "..." : (root.hasRouteGeometry ? "REAL" : "--")
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 18
                    color: mapTap.pressed ? root.violet : "#171025"
                    border.color: mapTap.pressed ? "#B99CFF" : "#342544"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "OPEN MAP"
                        color: "#F4EEF7"
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1.5
                    }
                }
            }

            TapHandler {
                id: mapTap
                gesturePolicy: TapHandler.ReleaseWithinBounds

                onTapped: {
                    if (!root.childTapActive) {
                        root.mapClicked()
                    }
                }
            }
        }
    }

    component MediaControlButton: Item {
        id: mediaBtn
        width: root.compact ? 32 : 36
        height: width

        property string icon: ""
        property bool active: false

        signal clicked()

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: mediaTapButton.pressed
                   ? root.violet
                   : (mediaBtn.active ? "#F4EEF7" : "#171025")
            border.color: mediaTapButton.pressed
                          ? "#B99CFF"
                          : (mediaBtn.active ? "#F4EEF7" : "#4B2C73")
            border.width: 1
            scale: mediaTapButton.pressed ? 0.92 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.OutQuad
                }
            }

            Text {
                anchors.centerIn: parent
                text: mediaBtn.icon
                color: mediaTapButton.pressed
                       ? "#FFFFFF"
                       : (mediaBtn.active ? "#080512" : "#CBC4CD")
                font.pixelSize: mediaBtn.active ? (root.compact ? 12 : 13) : (root.compact ? 18 : 20)
                font.bold: true
            }
        }

        TapHandler {
            id: mediaTapButton
            gesturePolicy: TapHandler.ReleaseWithinBounds

            onPressedChanged: {
                if (pressed) {
                    root.beginChildTap()
                } else {
                    root.endChildTap()
                }
            }

            onTapped: {
                mediaBtn.clicked()
            }
        }
    }

    component RouteStatePill: Rectangle {
        id: statePill
        property string text: ""
        property bool active: false
        property bool alert: false

        height: 28
        radius: 14
        color: statePill.alert ? "#24090E" : (statePill.active ? "#10202A" : "#171025")
        border.color: statePill.alert ? root.red : (statePill.active ? root.cyan : "#342544")
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: statePill.text
            color: statePill.alert ? root.red : (statePill.active ? root.cyan : root.muted)
            font.pixelSize: 9
            font.bold: true
            font.letterSpacing: 1.2
        }
    }

    component RoutePreviewCanvas: Canvas {
        id: preview
        property var routePath: []
        property bool routeActive: false
        property bool routeLoading: false
        property string routeError: ""

        onRoutePathChanged: requestPaint()
        onRouteActiveChanged: requestPaint()
        onRouteLoadingChanged: requestPaint()
        onRouteErrorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var bg = ctx.createLinearGradient(0, 0, width, height)
            bg.addColorStop(0, "#0B1520")
            bg.addColorStop(0.55, "#070A13")
            bg.addColorStop(1, "#130817")
            ctx.fillStyle = bg
            ctx.fillRect(0, 0, width, height)

            var hasGeometry = preview.routePath && preview.routePath.length > 1
            if (!hasGeometry) {
                ctx.save()
                ctx.fillStyle = preview.routeError.length > 0 ? root.red : (preview.routeLoading ? root.cyan : root.muted)
                ctx.globalAlpha = preview.routeLoading ? 0.42 : 0.26
                ctx.beginPath()
                ctx.arc(width * 0.24, height * 0.42, 5, 0, Math.PI * 2)
                ctx.arc(width * 0.76, height * 0.34, 5, 0, Math.PI * 2)
                ctx.fill()
                ctx.globalAlpha = 0.18
                ctx.strokeStyle = root.muted
                ctx.lineWidth = 2
                var startX = width * 0.24
                var startY = height * 0.42
                var endX = width * 0.76
                var endY = height * 0.34
                for (var s = 0; s < 7; ++s) {
                    var t0 = s / 7
                    var t1 = t0 + 0.07
                    ctx.beginPath()
                    ctx.moveTo(startX + (endX - startX) * t0, startY + (endY - startY) * t0)
                    ctx.lineTo(startX + (endX - startX) * t1, startY + (endY - startY) * t1)
                    ctx.stroke()
                }
                ctx.restore()
                return
            }

            var minLat = 90
            var maxLat = -90
            var minLon = 180
            var maxLon = -180
            for (var r = 0; r < preview.routePath.length; ++r) {
                var pointData = preview.routePath[r]
                var lat = Number(pointData.latitude)
                var lon = Number(pointData.longitude)
                minLat = Math.min(minLat, lat)
                maxLat = Math.max(maxLat, lat)
                minLon = Math.min(minLon, lon)
                maxLon = Math.max(maxLon, lon)
            }

            var latSpan = Math.max(0.0001, maxLat - minLat)
            var lonSpan = Math.max(0.0001, maxLon - minLon)
            var padX = width * 0.16
            var padY = height * 0.18

            function xFor(lonValue) {
                return padX + ((lonValue - minLon) / lonSpan) * (width - padX * 2)
            }

            function yFor(latValue) {
                return padY + ((maxLat - latValue) / latSpan) * (height - padY * 2)
            }

            function routeStroke(lineWidth, color, alpha) {
                ctx.save()
                ctx.globalAlpha = alpha
                ctx.strokeStyle = color
                ctx.lineWidth = lineWidth
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                ctx.beginPath()
                for (var i = 0; i < preview.routePath.length; ++i) {
                    var coordinate = preview.routePath[i]
                    var x = xFor(Number(coordinate.longitude))
                    var y = yFor(Number(coordinate.latitude))
                    if (i === 0) {
                        ctx.moveTo(x, y)
                    } else {
                        ctx.lineTo(x, y)
                    }
                }
                ctx.stroke()
                ctx.restore()
            }

            routeStroke(9, "#02070D", 0.70)
            routeStroke(5, root.cyan, 0.95)

            var start = preview.routePath[0]
            var end = preview.routePath[preview.routePath.length - 1]
            ctx.save()
            ctx.fillStyle = "#F4EEF7"
            ctx.beginPath()
            ctx.arc(xFor(Number(start.longitude)), yFor(Number(start.latitude)), 4, 0, Math.PI * 2)
            ctx.fill()
            ctx.fillStyle = root.violet
            ctx.beginPath()
            ctx.arc(xFor(Number(end.longitude)), yFor(Number(end.latitude)), 5, 0, Math.PI * 2)
            ctx.fill()
            ctx.restore()
        }

        Component.onCompleted: requestPaint()
    }

    component RouteMetricTile: Rectangle {
        id: metricTile
        property string title: ""
        property string value: ""

        height: root.compact ? 54 : 60
        radius: root.compact ? 16 : 18
        color: "#080512"
        border.color: "#342544"
        border.width: 1

        Column {
            anchors.centerIn: parent
            width: parent.width - 10
            spacing: 4

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: metricTile.title
                color: root.muted
                font.pixelSize: 8
                font.bold: true
                font.letterSpacing: 1.1
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                text: metricTile.value
                color: "#F4EEF7"
                font.pixelSize: root.compact ? 11 : 12
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }
    }

    component TripMetric: Column {
        id: metric
        width: root.compact ? 62 : 78
        spacing: root.compact ? 2 : 3

        property string title: ""
        property string value: ""

        Text {
            text: metric.title
            color: root.muted
            font.pixelSize: root.compact ? 8 : 9
            font.bold: true
            font.letterSpacing: root.compact ? 1.2 : 1.8
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: metric.value
            color: "#F4EEF7"
            font.pixelSize: root.compact ? 11 : 13
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
            elide: Text.ElideRight
            width: metric.width
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
