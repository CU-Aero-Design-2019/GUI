import QtQuick 2.9
import QtQuick.Controls 2.3

Dialog {
  id: nameDialog
  signal savePath(string newPath)
  height: 300
  width: 250
  x: 100
  y: 100
  title: "New Path Name"

  contentItem: Rectangle {
    height: nameDialog.height
    width: nameDialog.width
    anchors.left: nameDialog.left
    anchors.leftMargin: 25
    CustomTextInput {
      id: newPathInpt
    }
    // Enter cannot directly bind to native pressed function
    Keys.onReturnPressed: saveBtn.saved()
    Keys.onEnterPressed: saveBtn.saved()
    Button {
      id: cancelBtn
      anchors.left: newPathInpt.left
      anchors.top: newPathInpt.bottom
      anchors.topMargin: 10
      width: 100
      text: qsTr("Cancel")
      onPressed: nameDialog.close()
    }
    Button {
      signal saved
      id: saveBtn
      anchors.top: cancelBtn.top
      anchors.left: cancelBtn.right
      anchors.leftMargin: 10
      width: cancelBtn.width
      text: qsTr("Save")
      onPressed: saved()
      onSaved: {
        savePath(newPathInpt.textStr)
        nameDialog.close()
        rootItem.forceActiveFocus()
      }
    }
  }
}
