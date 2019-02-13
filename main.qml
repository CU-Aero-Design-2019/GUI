import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick 2.5
import QtQuick.Controls 2.3
import QtLocation 5.6
import QtQml.Models 2.1

import "ui/map"
import "ui/menus"
import "ui/helpers"

// Test comment
Item {
    id: root
    visible: true

    MainMenuBar {
        id: appMainMenu
    }

    InfoBar {
        anchors.top: appMainMenu.bottom
        id: info
    }

    MapComponent {
        id: map
        height: root.height - appMainMenu.height - info.height
        width: root.width
        anchors.top: info.bottom

    }
}
