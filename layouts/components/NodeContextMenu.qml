import QtQuick
import QtQuick.Controls

/*
 * @brief: 拓扑节点右键菜单。
 *         使用方式：在目标节点里创建本组件，调用 open() 弹出。
 */
Popup {
    id: root

    // ── 信号 ──────────────────────────────────────────────────
    signal deleteClicked()
    signal insertAfterClicked()
    signal insertBeforeClicked()
    signal appendClicked()

    // ── 样式 ──────────────────────────────────────────────────
    width: 170; padding: 6
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        radius: 8; color: "#1c1f26"
        border.width: 1; border.color: "#2a2e36"
    }

    Column {
        width: parent.width
        spacing: 2

        CustomMenuItem {
            label: "Insert before"; iconChar: "↑"
            onTriggered: { root.insertBeforeClicked(); root.close() }
        }
        CustomMenuItem {
            label: "Insert after"; iconChar: "↓"
            onTriggered: { root.insertAfterClicked(); root.close() }
        }
        Rectangle { width: parent.width; height: 1; color: "#2a2e36" }
        CustomMenuItem {
            label: "Append to end"; iconChar: "↘"
            onTriggered: { root.appendClicked(); root.close() }
        }
        Rectangle { width: parent.width; height: 1; color: "#2a2e36" }
        CustomMenuItem {
            label: "Delete"; iconChar: "✕"
            iconColor: "#e05555"; textColor: "#e05555"
            onTriggered: { root.deleteClicked(); root.close() }
        }
    }

    // ── 自定义菜单项 ────────────────────────────────────────
    component CustomMenuItem: Rectangle {
        id: item

        property string label: ""
        property string iconChar: ""
        property color  iconColor: "#88909e"
        property color  textColor: "#d4d7dc"

        signal triggered()

        width: parent.width; height: 30; radius: 4
        color: mouseArea.containsMouse ? "#252830" : "transparent"

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.leftMargin: 10
            spacing: 10

            Text {
                text: item.iconChar; color: item.iconColor
                font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter
                width: 16; horizontalAlignment: Text.AlignHCenter
            }
            Text {
                text: item.label; color: item.textColor
                font.pixelSize: 12; font.family: "微软雅黑"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: item.triggered()
        }
    }
}
