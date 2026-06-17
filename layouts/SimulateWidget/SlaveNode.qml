import QtQuick
import "../components"

/*
 * @brief: 拓扑链上的单个从站节点卡片。
 *         显示位置编号、设备名、厂商、SM/PDO 统计、CoE/DC 标签。
 *         交互：点击选中、hover 高亮。
 */
Rectangle {
    id: root

    // ── 外部数据绑定 ──────────────────────────────────────────
    required property int    position
    required property string slaveName
    required property string vendorName
    property string deviceType: ""
    property int    smCount: 0
    property int    rxCount: 0
    property int    txCount: 0
    property bool   hasCoe: false
    property bool   hasDc:  false
    property int    deviceIndex: 0

    // ── 状态 ──────────────────────────────────────────────────
    property bool selected: false

    // ── 尺寸 ──────────────────────────────────────────────────
    implicitWidth:  200
    implicitHeight: 100
    radius: 10

    // ── 颜色 ──────────────────────────────────────────────────
    color: mouseArea.containsMouse ? "#252830" : "#1e2128"
    border.width: selected ? 2 : 1
    border.color: selected ? "#5294e2" : (mouseArea.containsMouse ? "#3a3e4a" : "#2a2e36")

    // ── 左侧端口 ──────────────────────────────────────────────
    Rectangle {
        anchors.left: parent.left; anchors.leftMargin: -3
        anchors.verticalCenter: parent.verticalCenter
        width: 6; height: 6; radius: 3
        color: "#5294e2"
    }

    // ── 右侧端口 ──────────────────────────────────────────────
    Rectangle {
        anchors.right: parent.right; anchors.rightMargin: -3
        anchors.verticalCenter: parent.verticalCenter
        width: 6; height: 6; radius: 3
        color: "#5294e2"
    }

    // ── 内容 ──────────────────────────────────────────────────
    Column {
        anchors.fill: parent
        anchors.leftMargin: 12; anchors.rightMargin: 12
        anchors.topMargin: 12; anchors.bottomMargin: 12
        spacing: 6

        // 第一行：位置徽章 + 名称
        Row {
            spacing: 8
            anchors.left: parent.left; anchors.right: parent.right

            Rectangle {
                id: idx
                width: 22; height: 22; radius: 11
                color: Qt.rgba(82/255, 148/255, 226/255, 0.15)
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    anchors.centerIn: parent
                    text: root.position
                    color: "#5294e2"
                    font.pixelSize: 11; font.weight: Font.DemiBold
                    font.family: "微软雅黑"
                }
            }

            // 设备编号徽章（同文件内第几个Device）
            Rectangle {
                id: gidx
                visible: root.deviceIndex > 0
                width: devIdxBadge.implicitWidth + 6; height: 17; radius: 3
                color: Qt.rgba(212/255, 132/255, 74/255, 0.12)
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    id: devIdxBadge
                    anchors.centerIn: parent
                    text: "D" + root.deviceIndex; color: "#d4844a"
                    font.pixelSize: 9; font.family: "微软雅黑"
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.slaveName
                color: ThemeManager.current.textPrimary
                font.pixelSize: 13; font.weight: Font.DemiBold
                font.family: "微软雅黑"
                elide: Text.ElideMiddle
                width: parent.width - idx.width - gidx.width - 10
            }
        }

        // 第二行：厂商名
        Text {
            anchors.left: parent.left
            text: root.vendorName
            color: ThemeManager.current.textSecondary
            font.pixelSize: 10; font.family: "微软雅黑"
            elide: Text.ElideMiddle
            width: parent.width
        }

        // 第三行：SM + PDO 统计
        Row {
            anchors.left: parent.left; anchors.right: parent.right
            spacing: 8

            Text {
                text: "SM:" + root.smCount
                color: "#88909e"
                font.pixelSize: 10; font.family: "微软雅黑"
            }
            Text {
                text: "Rx:" + root.rxCount
                color: "#5294e2"
                font.pixelSize: 10; font.family: "微软雅黑"
            }
            Text {
                text: "Tx:" + root.txCount
                color: "#42a85f"
                font.pixelSize: 10; font.family: "微软雅黑"
            }
        }

        // 第四行：CoE / DC 标签
        Row {
            anchors.left: parent.left; anchors.right: parent.right
            spacing: 6

            Rectangle {
                visible: root.hasCoe
                width: coeLabel.implicitWidth + 8; height: 16; radius: 3
                color: Qt.rgba(66/255, 168/255, 95/255, 0.12)
                Text {
                    id: coeLabel
                    anchors.centerIn: parent
                    text: "CoE"; color: "#42a85f"
                    font.pixelSize: 9; font.family: "微软雅黑"
                }
            }

            Rectangle {
                visible: root.hasDc
                width: dcLabel.implicitWidth + 8; height: 16; radius: 3
                color: Qt.rgba(212/255, 132/255, 74/255, 0.12)
                Text {
                    id: dcLabel
                    anchors.centerIn: parent
                    text: "DC"; color: "#d4844a"
                    font.pixelSize: 9; font.family: "微软雅黑"
                }
            }
        }
    }

    // ── 信号 ──────────────────────────────────────────────────
    signal deleteClicked()
    signal insertAfterClicked()
    signal insertBeforeClicked()
    signal appendClicked()

    // ── 右键菜单 ──────────────────────────────────────────────
    NodeContextMenu {
        id: contextMenu
        onDeleteClicked:       root.deleteClicked()
        onInsertAfterClicked:  root.insertAfterClicked()
        onInsertBeforeClicked: root.insertBeforeClicked()
        onAppendClicked:       root.appendClicked()
    }

    // ── 交互 ──────────────────────────────────────────────────
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                contextMenu.x = mouse.x
                contextMenu.y = mouse.y
                contextMenu.open()
            }
        }
    }
}
