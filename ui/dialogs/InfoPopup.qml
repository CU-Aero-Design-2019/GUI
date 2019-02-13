import QtQuick 2.5
import QtQuick.Controls 2.3
import QtQuick.Dialogs 1.2

Popup {
  // IMPORTANT: if this list is changed, change the corresponding indices for the
  // display text
  readonly property var options: ["Velocity", "Laps Completed", "Laps Remaining",
    "Next Guide", "Distance Remaining", "Voltage", "Current"]
  property alias optionGrid: grid
  width: 500 //root.width
  height: childrenRect.height + 200
  leftMargin: Math.floor((root.width - infoPopup.width) / 2)
  topMargin: appMainMenu.height + info.height
  modal: true
  focus: true

  closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape
  // Populates a popup of information the user can choose to see
  GridView {
    id: grid
    anchors.fill: parent
    anchors.centerIn: parent
    cellWidth: 150
    cellHeight: 50
    model: options
    clip: true

    delegate: optionDelegate
  }

  Component {
    id: optionDelegate

    CheckBox {
      text: modelData
    }
  }
}
