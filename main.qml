import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "./layouts/TitleBar"
import "./layouts/CenterWidget"
import "./layouts/components"

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 1000
    height: 680
    minimumWidth: 960
    minimumHeight: 600
    title: "EtherCAT Lab"
    x: Screen.width / 2 - width / 2
    y: Screen.height / 2 - height / 2

    Item {
        id: controller
        states: [
            State {
                name: "no-file"
            },
            State {
                name: "file-selected"
            }
        ]
    }

    TitleBar {
        id: appTitleBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
    }

    Seprator {
        id: titleBarSep
        color: "#282C34"
        anchors.top: appTitleBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 2
    }

    CenterWidget {
        id: centerWidget
        anchors.top: titleBarSep.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

    }


}
