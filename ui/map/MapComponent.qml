import QtQuick 2.5
import QtLocation 5.9
import QtPositioning 5.6
import QtQuick.Controls 2.2

import "../helpers"

Map {
    // Markers
    property int numMarkers: 0
    // Independently keep track of markers that note directions
    property int numDirMarkers: 0
    property var markers

    property double speed: 0 // in m/s

    // Snap/unsnap GPS
    property bool followingGPS: false
    property bool changeNmea: false
    property int currentMarker: -1
    property var leeuwarden: QtPositioning.coordinate(53.2012, 5.7999)

    // Expose the map helper to other qml components
    property alias helper: mapHelper

    id: map

    plugin: Plugin {
        name: "osm"
    }
    center: leeuwarden
    zoomLevel: 15

    MapHelper {
        id: mapHelper
    }

    MapPolyline {
        id: mapLinePath
        line.width: 2
        line.color: 'green'
        enabled: false // This will change once a route is added
    }

    PositionSource {
        id: gpsData
        active: false
        nmeaSource: mapHelper.getNewNmeaSrc()
        updateInterval: 3000 // In milliseconds
        onPositionChanged: {
            if (active && !helper.finishedRace) {
                helper.updateDistance()
            }
            map.speed = position.speed // in m/s
            if (map.followingGPS) {
                map.center = position.coordinate
            }
        }
    }

    onChangeNmeaChanged: gpsData.nmeaSource = mapHelper.getNewNmeaSrc()

    CurrentLocation {
    }

    MapQuickItem {
        sourceItem: Text {
            text: "A"
            color: "red"
            font.bold: true
            styleColor: "#ECECEC"
            style: Text.Outline
            font.pointSize: 15
        }
        coordinate: QtPositioning.coordinate(53.20370367,
                                             5.80089859) // GPS start
        anchorPoint: Qt.point(sourceItem.width * 0.5, sourceItem.height * 0.5)
    }

    MapQuickItem {
        sourceItem: Text {
            text: "B"
            color: "red"
            font.bold: true
            styleColor: "#ECECEC"
            style: Text.Outline
            font.pointSize: 15
        }
        coordinate: QtPositioning.coordinate(53.20285297, 5.80311816)
        anchorPoint: Qt.point(sourceItem.width * 0.5, sourceItem.height * 0.5)
    }

    MapQuickItem {
        sourceItem: Text {
            text: "C"
            color: "red"
            font.bold: true
            styleColor: "#ECECEC"
            style: Text.Outline
            font.pointSize: 15
        }
        coordinate: QtPositioning.coordinate(53.20224578, 5.80162871)
        anchorPoint: Qt.point(sourceItem.width * 0.5, sourceItem.height * 0.5)
    }

    MapQuickItem {
        sourceItem: Text {
            text: "D"
            color: "red"
            font.bold: true
            styleColor: "#ECECEC"
            style: Text.Outline
            font.pointSize: 15
        }
        coordinate: QtPositioning.coordinate(53.20346821, 5.80067635)
        anchorPoint: Qt.point(sourceItem.width * 0.5, sourceItem.height * 0.5)
    }

    MouseArea {
        anchors.fill: parent

        onPressAndHold: {
            // For some reason, the coordinates are offset from the click location.
            // Rectify by adding 'fudge factor'
            /*var fudgeX = 0.0001;
            var fudgeY = fudgeX;*/
            var coords = map.toCoordinate(Qt.point(mouse.x, mouse.y))
            mapHelper.addMarker(coords)
        }
    }

    Component.onCompleted: {
        markers = []
    }
}
