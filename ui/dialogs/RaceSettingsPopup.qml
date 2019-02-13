import QtQuick 2.5
import QtQuick.Controls 2.3
import QtQuick.Dialogs 1.2

Popup {
  width: 500 //root.width
  height: 100 //root.height - appMainMenu.height - info.height
  x: info.x
  margins: info.height + appMainMenu.height
  modal: true
  focus: true

  closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape

  Column {
    width: parent.width
    Row {
      Label {
        height: parent.height
        text: qsTr("Race Type: ")
      }
      ComboBox {
        id: comboBox
        // TODO: change to enumeration
        model: ["Back-Forth", "Circular", "Start-Finish"]
        onCurrentTextChanged: {
          map.helper.updateRaceType(currentText)
          map.helper.updateRoute()
          map.changeNmea = true
          // Can't allow more than one lap for start-finish race
          comboBox.state = currentText
        }
        states: [
          State {
            name: "Start-Finish"
            PropertyChanges {
              target: numInpt
              txt: "1"
              txtEnable: false
            }
          },
          State {
            name: "Circular"
            PropertyChanges {
              target: numInpt
              txtEnable: true
            }
          },
          State {
            name: "Back-Forth"
            PropertyChanges {
              target: numInpt
              txtEnable: true
            }
          }
        ]
      }
    }
    Row {
      Label {
        height: parent.height
        text: qsTr("Number of Laps: ")
      }
      CustomNumberInput {
        id: numInpt
        onNumChanged: map.helper.numLaps = Number(num)
      }
    }
  }
}
