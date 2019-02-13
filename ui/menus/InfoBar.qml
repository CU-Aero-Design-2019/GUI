import QtQuick 2.5
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3

import "../helpers/"
import "../dialogs/"

Rectangle {
  // Expose helper functions to other qml objects
  property alias helper: infoHelper
  property alias displayItems: infoPopup
  // hack-ey way of getting at checkboxes in the popup
  property var checkBoxes: infoPopup.optionGrid.children[0].children

  id: info
  color: "light grey"
  width: parent.width
  // Scale height if lots of items are shown. 3 displays per row
  height: childrenRect.height

  InfoHelper {
    id: infoHelper
  }

  InfoPopup {
    id: infoPopup
  }

  GridLayout {
    id: displayGrid
    width: parent.width - 100
    columns: 2

    Text {
      text: "DONE!"
      font.pointSize: 14
      visible: map.helper.finishedRace
    }

    Text {
      id: velocity
      text: "Velocity: " + helper.getVelocityTxt()
      font.pointSize: 14

      visible: checkBoxes[0].checked && !map.helper.finishedRace
    }

    Text {
      id: lapsCompleted
      text: "Laps completed: " + map.helper.lapsCompleted
      font.pointSize: 14

      visible: checkBoxes[1].checked && !map.helper.finishedRace
    }

    Text {
      id: lapsRemaining
      text: "Laps remaining: " + (map.helper.numLaps - map.helper.lapsCompleted - 1)
      font.pointSize: 14

      visible: checkBoxes[2].checked && !map.helper.finishedRace
    }

    Text {
      id: nextGuide
      text: "Next Guide: " + helper.getDistTxt(map.helper.savedGuideDist)
      font.pointSize: 14

      visible: checkBoxes[3].checked && !map.helper.finishedRace
    }

    Text {
      id: reminingDist
      text: "Distance remaining: " + helper.getDistTxt(map.helper.savedDistRemaining)
      font.pointSize: 14

      visible: checkBoxes[4].checked && !map.helper.finishedRace
    }

    Text {
      id: pctRemainingDist
      text: "% distance remaining: " + helper.getRemainingDistPercentageTxt()
      font.pointSize: 14

      visible: checkBoxes[4].checked && !map.helper.finishedRace
    }

    Text {
      id: voltage
      text: "Voltage: " + helper.getVoltageTxt()
      font.pointSize: 14

      visible: checkBoxes[5].checked && !map.helper.finishedRace
    }

    Text {
      id: current
      text: "Current: " + helper.getCurrentTxt()
      font.pointSize: 14

      visible: checkBoxes[6].checked && !map.helper.finishedRace
    }
  }

  Button {
    id: skipCurTargetButton
    visible: infoHelper.canIncTarget
    anchors.right: parent.right
    anchors.rightMargin: 10
    anchors.topMargin: 5
    // Needed to make text white
    contentItem: Text {
      color: "white"
      text: "Skip target"
    }
    background: Rectangle {
      anchors.fill: parent
      color: "light green"
      radius: 5
    }
    onPressed: infoHelper.forceInc = true
  }

  Text {
    id: curTargetTxt
    visible: infoHelper.canIncTarget
    text: "Target #: " + (Number(map.helper.curTarget) + 1)
    anchors.top: skipCurTargetButton.bottom
    anchors.right: skipCurTargetButton.right
    font.pointSize: 14
  }
}
