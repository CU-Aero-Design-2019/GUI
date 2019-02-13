import QtQuick 2.5
import QtQuick.Controls 2.3
import QtQuick.Dialogs 1.2

Item {
  property bool canIncTarget: false
  property bool forceInc: false

  function getDistTxt(dist) {
    return dist + " m"
  }

  function getRemainingDistPercentageTxt() {
    return Math.round(map.speed * 100) / 100 + "%"
  }

  function getVelocityTxt() {
    // Round to two decimal places
    return Math.round(map.speed * 100) / 100 + " m/s"
  }

  function getCurrentTxt() {
    return CANDisplay.current + " A"
  }

  function getVoltageTxt() {
    return CANDisplay.voltage + " V"
  }

//  function updateCanValues(newVals) {
//    // newVals is an object array that contains each changed property and the
//    // new value for that property
//    for (var i in newVals) {
//      switch (newVals[i].prop) {
//      case "Voltage":
//        info.voltageTxt = "Voltage: " + newVals[i].val + "V"
//        break
//      default:
//        break
//      }
//    }
//  }

//  // This will allow the CANDisplay class to update the dislpay when CAN values
//  // change. I think this is unnecessary
//  Connections {
//    target: CANDisplay
//    onUpdateCanVals: {
//      updateCanValues(newVals)
//    }
//  }
}
