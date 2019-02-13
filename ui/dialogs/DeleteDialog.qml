import QtQuick 2.5
import QtQuick.Controls 2.3
import QtQuick.Dialogs 1.2

MessageDialog {
    title: "Confirm Delete"
    text: "Are you sure you want to delete this?"
    standardButtons: StandardButton.Cancel | StandardButton.Yes
}
