import QtQuick 2.5
import QtQuick.Controls 2.3
import QtQuick.Dialogs 1.2

Rectangle {
    property int num: Number(numInpt.displayText)
    property alias txt: numInpt.text
    property alias txtEnable: numInpt.enabled
    height: 25
    width: 50
    color: "white"
    border.width: 1
    border.color: "black"

    TextInput {
        id: numInpt
        focus: true
        anchors.fill: parent
        anchors.margins: 4
        mouseSelectionMode: TextInput.SelectCharacters
        selectByMouse: true
        validator: IntValidator {
            bottom: 1
            top: 20
        }
//        onEditingFinished: {
////            num = Number(numInpt.displayText)
//        }
    }
}
