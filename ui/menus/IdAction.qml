import QtQuick 2.5
import QtQuick.Controls 2.3

import "../helpers"
import "../dialogs"

MenuItem {
    signal deleteAction(int actionId)
    property int actionId
    Action {
        id: action
        // 'id' is a special field, so use an attr. name that can be externally set
        onTriggered: {
            map.helper.loadPath(actionId)
            // Show the path between the markers after loading
            map.helper.toggleRoute()
            // Collapse the main menu after triggering. This doesn't happen
            // automatically with a propagated trigger
            dbPaths.close();
        }
    }
    function deletePaths() {
        var success = DBPath.deletePath(actionId)
        if (!success) {
            console.log("Delete failed.")
        } else {
            // Remove path from GUI
            menuHelper.deleteAction(actionId)
        }
    }
    DeleteDialog {
        id: deleteDialog
        onYes: deletePaths()
    }

    MouseArea {
        // The press event must propagate to the action
        onClicked: action.trigger()

        anchors.fill: parent
        onPressAndHold: deleteDialog.open()
    }
}
