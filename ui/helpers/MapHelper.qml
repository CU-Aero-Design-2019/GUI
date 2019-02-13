import QtQuick 2.5
import QtQuick.Controls 2.3
import QtQuick.Dialogs 1.2
import QtPositioning 5.8

Item {
  // QML optimizes performances if this is its own variable rather than
  // constantly accessing a subobject of a map object. This gets repopulated
  // as markers change in the map
    property int back_forth: 1
    property int circular: 2
    property int start_finish: 3
  property var markerCoords: []
  property int savedDistRemaining: 0
  property int savedGuideDist: 0
  property int totalRaceDist: 0
  property int lapsCompleted: 0
  property bool finishedRace: false
  property int raceType: back_forth
  property bool upDir: true

  // Tolerance (m) acceptable to consider current location as reaching the next marker
  readonly property int distanceThreshold: 15
  property int curTarget: 1 // What marker the GPS is aiming for next

  // Race setting variables
  property int numLaps: 1

  function updateRoute() {
    if (map.numMarkers === 0) {
      // No path, so don't try to change the path
      return
    }

    var pathCoords = []
    for (var i in markerCoords) {
      pathCoords.push(markerCoords[i])
    }
    // Complete the loop if this is a circular race
    if (raceType === circular) {
      pathCoords.push(markerCoords[0])
    }

    mapLinePath.path = pathCoords
  }

  function updateCoords(markerNumber) {
    // Number is 1-based, index is 0-based
    var idx = Number(markerNumber) - 1
    markerCoords[idx] = map.markers[idx].coordinate
    updateRoute()
  }

  function activateGps() {
    gpsData.active = true
  }

  function addMarker(coords, isGuide) {
    // isGuide will default to false if not provided
    isGuide = isGuide || false
    map.numMarkers++
    var marker = Qt.createQmlObject('import "../map"; Marker {}', map)
    map.addMapItem(marker)
    marker.z = map.z + 1
    marker.coordinate = coords
    marker.isGuide = isGuide
    markerCoords.push(coords)

    map.markers.push(marker)
    map.markersChanged()
    updateRoute()
  }

  function deleteMarker(idx) {
    // If the last marker is removed, we don't have to do any renaming
    if (idx !== map.numMarkers - 1) {
      // All markers before the removed one will not be changed. Thus,
      // We can start the iteration at the first changed marker
      for (var i = idx + 1; i < map.numMarkers; i++) {
        // Shift the number of each marker so that nothing is skipped
        map.markers[i].num--
      }
    }
    // Keep the removed element to delete it from the map
    var removedMarker = map.markers.splice(idx, 1)[0]
    // Delete from coord list, too. Assign to variable because QML forces
    // you to...
    var uselessVariable = markerCoords.splice(idx, 1)[0]
    map.removeMapItem(removedMarker)
    map.numMarkers--
    removedMarker.destroy()
    updateRoute()
  }

  function deleteAllMarkers() {
    var newMarkers = []
    var count = map.markers.length
    for (var i = 0; i < count; i++) {
      map.removeMapItem(map.markers[i])
      map.markers[i].destroy()
    }
    map.numMarkers = 0
    map.markers = newMarkers
    markerCoords = []
    mapLinePath.visible = false
  }

  function toggleMarkers() {
    // Shouldn't do anything if there are no markers
    if (map.numMarkers == 0)
      return
    var visibility = map.markers[0].visible
    for (var el in map.markers) {
      map.markers[el].visible = !visibility
    }
  }

  function toggleRoute() {
    if (mapLinePath.visible == true) {
      mapLinePath.visible = false
    } else {
      mapHelper.updateRoute()
      mapLinePath.visible = true
    }
  }

  function loadPath(pathId) {
    var newMarkers = DBMarker.readPathMarkers(pathId)
    // Order list by marker number, which is the third column returned
    newMarkers.sort(function (x, y) {
      return x[3] - y[3]
    })
    // Clean out markers already on map
    deleteAllMarkers()
    for (var i in newMarkers) {
      addMarker(QtPositioning.coordinate(newMarkers[i][0], newMarkers[i][1]),
                newMarkers[i][2])
    }
  }

  function savePath(pathName) {
    // Put each portion of the current markers in a list to add them to db
    var lat = []
    var lon = []
    var is_guide = []
    var marker_num = []
    for (var i in markerCoords) {
      lon.push(markerCoords[i].longitude)
      lat.push(markerCoords[i].latitude)
      is_guide.push(map.markers[i].isGuide)
      marker_num.push(Number(i) + 1)
    }
    return DBPath.createPath(pathName, lat, lon, is_guide, marker_num)
  }

  function updateDistance() {
    if (!mapLinePath.visible) {
      // No path. Don't calculate anything
      return
    }

    // Init the function that we use for distance calculation. This
    // will save from needing if statements later
    var getLapDist
    var distToDirMarker
    switch (raceType) {
    case back_forth:
      getLapDist = backForthLapDist
      distToDirMarker = backForthGuideDist
      break
    case circular:
      getLapDist = circularLapDist
      distToDirMarker = circularGuideDist
      break
    case start_finish:
      // Basically the same as circular, but don't add distance from finish
      // to first marker
      getLapDist = circularLapDist
      distToDirMarker = circularGuideDist
    }

    var distRemaining = 0
    var lapDist = 0

    lapDist += getLapDist(true)
    totalRaceDist = lapDist * numLaps;
    // Increase total distance by the number of completely untraversed laps
    distRemaining += lapDist * (numLaps - lapsCompleted - 1)

    var gpsCoord = gpsData.position.coordinate
    var curDist = gpsCoord.distanceTo(markerCoords[curTarget])
    // Find remaining distance in current lap
    distRemaining += getLapDist(false)

    // Separate logic to determine whether the user should be able to increment
    // the current target. This should be allowable as long as there is at
    // least one more marker
    info.helper.canIncTarget = (distRemaining > 0)

    // This will happen if GPS is close to another marker and there is still at least
    // one more waypoint past the objective
    // Alternatively, curMarker should increment if forced from the GUI button
    if ((distRemaining != 0 && curDist < distanceThreshold)
        || info.helper.forceInc) {

      // This will account for lap wrap around when we just finished
      // another lap.
      if (curTarget === 0) {
        lapsCompleted++
      }
      //For a back-forth path, change directions if at either bound
      if (raceType === back_forth
          && (curTarget === 0 || curTarget === map.numMarkers - 1)) {
        upDir = !upDir
      }
      // Choose the next marker based on whether the path is incrementing
      // or decrementing along the markers
      if (upDir) {
        curTarget = (curTarget + 1) % map.numMarkers
      } else {
        curTarget--
      }
      curDist = gpsCoord.distanceTo(markerCoords[curTarget])
    } else if (curDist < distanceThreshold) {
      // Within tolerance of final marker. Consider race finished
      finishedRace = true
      info.helper.forceInc = false
      return
    }

    // We don't want to increment curMarker again on the next update
    info.helper.forceInc = false

    distRemaining += curDist
    // Total distance should now be accurate regardless of whether a new objective was set
    savedDistRemaining = distRemaining
    // Find the closest direction marker, since this is part of the information
    // the user wants to see
    savedGuideDist = distToDirMarker()
  }

  function circularLapDist(wholeLap) {
    var endIdx = (raceType === circular ? 0 : map.numMarkers - 1)
    // If the next target is the end, there is no path distance
    if (!wholeLap && curTarget === endIdx) {
      return 0
    }
    // Init lap distance with dist from end to beginning. 0 if start-finish
    var lapDist = markerCoords[map.numMarkers - 1].distanceTo(
          markerCoords[endIdx])
    // Fill in the rest of the lap to get total lap distance
    var start = (wholeLap ? 0 : curTarget)
    for (var i = start; i < map.numMarkers - 1; i++) {
      // Find the distance to end of markers
      lapDist += markerCoords[i].distanceTo(markerCoords[i + 1])
    }
    return lapDist
  }

  function backForthLapDist(wholeLap) {
    // Used for partial distance calculation
    var startIdx = 0
    var endIdx = map.numMarkers - 1
    // Get one way distance since in most cases it is needed
    var oneWayDist = 0
    var runningTot = 0
    for (var i = 0; i < map.numMarkers - 1; i++) {
      oneWayDist += markerCoords[i].distanceTo(markerCoords[i + 1])
    }
    // For a whole lap, simply double this distance
    if (wholeLap) {
      return oneWayDist * 2
    } else {
      // Find portion of lap needed based on direction we are
      // currently going
      if (upDir) {
        startIdx = curTarget
        // If going up, we will eventually have to go down. Account
        // for this by adding in the one way dist
        runningTot += oneWayDist
      } else {
        endIdx = curTarget
      }
      // Iterate through the specified idx's to get running tot
      for (var i = startIdx; i < endIdx; i++) {
        runningTot += markerCoords[i].distanceTo(markerCoords[i + 1])
      }
      return runningTot
    }
  }

  function circularGuideDist() {
    var totDist = 0
    var curDist = gpsData.position.coordinate.distanceTo(
          markerCoords[curTarget])
    // This gets hoisted anyway, so just declare it here
    var curIdx
    // Simply check all markers in a circle to see if they are guides
    var end = map.numMarkers + curTarget
    for (var i = curTarget; i < end; i++) {
      curIdx = i % map.numMarkers
      // Don't roll over if there are no more laps to complete, or this is
      // a start-finish race
      if (curIdx === 0 && lapsCompleted === numLaps - 1) {
        break
      }
      if (map.markers[curIdx].isGuide) {
        return curDist + totDist
      }

      totDist += markerCoords[curIdx].distanceTo(
            markerCoords[(curIdx + 1) % map.numMarkers])
    }
    // Reached if there are no guide markers
    return -1
  }

  function backForthGuideDist() {
    var existingGuide = false
    var totDist = 0
    // Will vary based on direction
    if (upDir) {
      // Keep going up, adding distances until a guide marker is reached
      for (var i = curTarget; i < map.numMarkers - 1; i++) {
        if (map.markers[i].isGuide) {
          // Found the proper marker distance, so stop iterating
          existingGuide = true
          break
        }
        totDist += markerCoords[i].distanceTo(markerCoords[i + 1])
      }
      // Possible that the unchecked marker is a guide
      if (map.markers[map.numMarkers - 1].isGuide) {
        existingGuide = true
      }

      if (!existingGuide) {
        // If this point is reached, there was no guide in the higher markers.
        // Double the distance (what it takes to get back to current target)
        // and look the other way for more guides
        totDist *= 2
        for (var i = curTarget; i >= 1; i--) {
          if (map.markers[i].isGuide) {
            existingGuide = true
            break
          }
          totDist += markerCoords[i].distanceTo(markerCoords[i - 1])
        }
      }
      // Possible that the unchecked marker is a guide
      if (map.markers[0].isGuide) {
        existingGuide = true
      }
    } else {
      // Just do the same thing, but switch the loops
      for (var i = curTarget; i >= 1; i--) {
        if (map.markers[i].isGuide) {
          existingGuide = true
          break
        }
        totDist += markerCoords[i].distanceTo(markerCoords[i - 1])
      }
      // Possible that the unchecked marker is a guide
      if (map.markers[0].isGuide) {
        existingGuide = true
      }
      // Only check up the markers if there's more than one lap remaining
      // and no guide has been found
      if (!existingGuide && lapsCompleted !== numLaps - 1) {
        totDist *= 2
        for (var i = curTarget; i < map.numMarkers - 1; i++) {
          if (map.markers[i].isGuide) {
            // Found the proper marker distance, so stop iterating
            existingGuide = true
            break
          }
          totDist += markerCoords[i].distanceTo(markerCoords[i + 1])
        }
        // Possible that the unchecked marker is a guide
        if (map.markers[map.numMarkers - 1].isGuide) {
          existingGuide = true
        }
      }
    }
    if (!existingGuide) {
      return -1
    } else {
      // Add on the distance between my current position and target
      return totDist + gpsData.position.coordinate.distanceTo(
            markerCoords[curTarget])
    }
  }

  function displayGPSCoord() {
    console.log(currentLoc.gpsData.position.coordinate)
  }

  function snapUnsnapGPS() {
    map.followingGPS = !map.followingGPS
    map.center = (map.followingGPS ? gpsData.position.coordinate : map.center)
  }

  function setNewTarget(newTarget) {
    curTarget = newTarget
    map.updateDistances()
  }

  function updateRaceType(newRaceType) {
    switch (newRaceType) {
    case "circular":
      raceType = circular
      break
    case "Back-Forth":
      raceType = back_forth
      break
    case "Start-Finish":
      raceType = start_finish
      numLaps = 1
    }
  }

  function getNewNmeaSrc() {
    map.changeNmea = false;
    switch (raceType) {
    case circular:
      return "../../res/sampleData/output.nmea"
    case back_forth:
      return "../../res/sampleData/backForth.nmea"
    case start_finish:
      return "../../res/sampleData/startFinish.nmea"
    }
  }
}
