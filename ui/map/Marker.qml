/****************************************************************************
**
** Copyright (C) 2017 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** BSD License Usage
** Alternatively, you may use this file under the terms of the BSD license
** as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/
import QtQuick 2.5
import QtLocation 5.6


//! [mqi-top]
MapQuickItem {
    // Variable to determine which image is used for the created marker
    property bool isGuide: false
    readonly property string regMarker: "../../res/marker.png"
    readonly property string dirMarker: "../../res/dirMarker.png"
    // Marker number will change if a marker in the middle of a path is
    // deleted. To track this, make the text a property that other elements
    // can access
    property alias num: number.text

    id: marker
    //! [mqi-top]
    anchorPoint.x: image.width / 2
    anchorPoint.y: image.height

    sourceItem: Image {
        id: image
        //! [mqi-anchor]
        source: regMarker
        opacity: markerMouseArea.pressed ? 0.6 : 1.0
        MouseArea {
            id: markerMouseArea
            property int jitterThreshold: 10
            property int lastX: -1
            property int lastY: -1
            anchors.fill: parent
            hoverEnabled: false
            drag.target: marker
            preventStealing: true

            onDoubleClicked: {
                // Parameter should be a number, not a string. Also, recall
                // the label is 1-indexed where an idx should be 0-indexed
                map.helper.deleteMarker(Number(num)-1)
            }

            onPressAndHold: {
                marker.isGuide = !marker.isGuide
            }

            drag.onActiveChanged: map.helper.updateCoords(number.text)
        }

        Text {
            id: number
            y: image.height / 10
            width: image.width
            color: "white"
            font.bold: true
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            Component.onCompleted: {
                text = map.numMarkers
            }
        }

        //! [mqi-closeimage]
        Component.onCompleted: {
            coordinate = map.toCoordinate(Qt.point(markerMouseArea.mouseX,
                                                   markerMouseArea.mouseY))
        }
    }

    onIsGuideChanged: {
        if (marker.isGuide) {
            image.source = dirMarker
        } else {
            image.source = regMarker
        }
        image.update()
    }

} //! [mqi-close]
