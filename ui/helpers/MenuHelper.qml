import QtQuick 2.5
import QtQuick.Controls 2.3
import QtQuick.Dialogs 1.2


// This gets instantiated in the MainMenuBar, so that will be the parent.
Item {
    function addToLoadPaths(pathData) {
        // We have two lists in pathData: ids, namse. Parse them into menu actions
        for (var i in pathData[0]) {
            // IdAction is simply an action with an additional property that
            // holds the path id
            var actionId = pathData[0][i]
            var idActionStr = createIdActionStr(actionId)
            var curAction = Qt.createQmlObject(idActionStr, dbPaths)
            // Assign the right parameters to the first child, which is the
            // item's action
            curAction.text = pathData[1][i]
            curAction.actionId = actionId
            curAction.deleteAction.connect(deleteAction)

            // Action is now ready to place in menu
            dbPaths.addItem(curAction)
        }
    }

    function createIdActionStr(actionId) {
        return 'import "../menus"; IdAction {}'
    }

    function deleteAction(actionId) {
        // Find this action in the action list
        var actions = dbPaths.contentData
        for (var i = 0; i < actions.length; i++) {
            if (actions[i].actionId === actionId) {
                dbPaths.removeItem(actions[i])
                break
            }
        }
    }

    //        while (curAction !== null) {
    //            if (curAction.actionId === actionId) {
    //                // Remove the action
    //                dbPaths.removeAction(curAction)
    //                break
    //            } else {
    //                idx++
    //                curAction = dbPaths.actionAt(idx)
    //            }
    //        }
}
