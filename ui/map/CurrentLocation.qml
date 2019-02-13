import QtQuick 2.5
import QtLocation 5.6
import QtPositioning 5.2

MapQuickItem {
    id: gpsMarker
    opacity: 1.0
    sourceItem: Image {
        id: image
        source: "qrc:/res/curGPS.png"
        //anchors.fill: parent
    }
//    sourceItem: Text {
//        text: "This is a test"
//        font.pointSize: 18
//        color: "red"
//    }

    coordinate: gpsData.position.coordinate
    anchorPoint.x: image.width / 2
    anchorPoint.y: image.height / 2
}
