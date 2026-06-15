import QtQuick
import QtQuick.Controls
import "../components"

/*
 * @brief: 仿真页面主控件。
 *         当前阶段：左侧从站列表（已加载的 ESI 设备） + 右侧占位
 */
Rectangle {
    id: root
    color: ThemeManager.current.bgWindow

    // ── 公开接口 ────────────────────────────────────────────────
    property bool hasSlaves: false
    property int slaveCount: 0
    property int frameCount: 0
    property string simState: "OP"
    property string cycleTime: "1000 μs"

    // ── 仿真控制（供 TitleBar 信号调用）────────────────────────
    function runSimulation()   { console.log("Sim: Run"); simState = "OP" }
    function pauseSimulation() { console.log("Sim: Pause") }
    function resetSimulation() { console.log("Sim: Reset"); frameCount = 0 }
    function stepFrame()       { console.log("Sim: Step"); frameCount++ }

    // ── 刷新设备列表 ────────────────────────────────────────────
    function refreshDeviceList() {
        deviceListModel.clear()
        var devices = ESITreeModel.getLoadedDevices()
        for (var i = 0; i < devices.length; i++) {
            var d = devices[i]
            deviceListModel.append({
                dataIndex: i,
                name: d.name || "",
                type: d.type || "",
                vendor: d.vendorName || "",
                productCode: d.productCode || "",
                smCount: d.smCount || 0,
                rxCount: d.rxCount || 0,
                txCount: d.txCount || 0,
                hasCoe: d.hasCoe ? "Yes" : "No",
                hasDc: d.hasDc ? "Yes" : "No"
            })
        }
        root.hasSlaves = ESITreeModel.hasData
    }

    // 初始化 + 页面切换时刷新
    Component.onCompleted: refreshDeviceList()
    onVisibleChanged: { if (visible) refreshDeviceList() }

    // ── 数据模型 ────────────────────────────────────────────────
    ListModel { id: deviceListModel }

    // ════════════════════════════════════════════════════════════
    // 空状态：无加载文件时的欢迎页
    // ════════════════════════════════════════════════════════════
    Item {
        id: welcomeView
        anchors.fill: parent
        visible: !root.hasSlaves

        Column {
            anchors.centerIn: parent; spacing: 24
            width: Math.min(parent.width - 48, 440)

            Column {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 10

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 70; height: 70; radius: 16
                    color: Qt.rgba(82/255, 148/255, 226/255, 0.08)
                    border.width: 1
                    border.color: Qt.rgba(82/255, 148/255, 226/255, 0.15)

                    Rectangle {
                        anchors.left: parent.left; anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14; height: 20; radius: 3; color: "#d4844a"
                    }
                    Rectangle {
                        anchors.right: parent.right; anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14; height: 20; radius: 3; color: "#5294e2"
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 16; height: 2
                        color: Qt.rgba(82/255, 148/255, 226/255, 0.4)
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "EtherCAT Simulation"
                    color: ThemeManager.current.textPrimary
                    font.pixelSize: 20; font.weight: Font.Bold; font.family: "微软雅黑"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Topology Editor · Frame Viewer · Protocol Simulation"
                    color: ThemeManager.current.textSecondary
                    font.pixelSize: 12; font.family: "微软雅黑"
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width; height: 150; radius: 10
                color: "transparent"
                border.width: 2; border.color: ThemeManager.current.navBorder

                Column {
                    anchors.centerIn: parent; spacing: 8
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No slaves loaded"
                        color: ThemeManager.current.textSecondary
                        font.pixelSize: 14; font.family: "微软雅黑"
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Load an ESI XML file from the ESI Browser first"
                        color: ThemeManager.current.navIconDefault
                        font.pixelSize: 11; font.family: "微软雅黑"
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 4
                KbdLabel { text: "Ctrl" }
                Text { text: "+"; color: ThemeManager.current.navIconDefault; font.pixelSize: 11; font.family: "微软雅黑" }
                KbdLabel { text: "R" }
                Text { text: " run  ·  "; color: ThemeManager.current.navIconDefault; font.pixelSize: 11; font.family: "微软雅黑" }
                KbdLabel { text: "Space" }
                Text { text: " step  ·  "; color: ThemeManager.current.navIconDefault; font.pixelSize: 11; font.family: "微软雅黑" }
                KbdLabel { text: "Del" }
                Text { text: " remove slave"; color: ThemeManager.current.navIconDefault; font.pixelSize: 11; font.family: "微软雅黑" }
            }
        }
    }

    // ════════════════════════════════════════════════════════════
    // 已加载文件：左侧从站列表 + 右侧占位
    // ════════════════════════════════════════════════════════════
    Item {
        id: workspace
        anchors.fill: parent
        visible: root.hasSlaves

        // ── 左侧从站面板 ──────────────────────────────────────
        Rectangle {
            id: slavePanel
            anchors.top: parent.top; anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: 280
            color: "#1c1f26"
            border.color: "#2a2e36"

            // Header
            Rectangle {
                anchors.top: parent.top; anchors.left: parent.left
                anchors.right: parent.right; height: 38
                color: "transparent"
                border.color: "#2a2e36"; border.width: 1

                Text {
                    anchors.left: parent.left; anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: "AVAILABLE SLAVES"
                    color: "#d4d7dc"
                    font.pixelSize: 11; font.weight: Font.DemiBold; font.family: "微软雅黑"
                }
                Text {
                    anchors.right: parent.right; anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: deviceListModel.count + " devices"
                    color: "#555c69"; font.pixelSize: 10; font.family: "微软雅黑"
                }
            }

            // Device list
            ListView {
                id: deviceListView
                anchors.top: parent.top; anchors.topMargin: 39
                anchors.left: parent.left; anchors.right: parent.right
                anchors.bottom: parent.bottom
                clip: true; spacing: 2
                model: deviceListModel

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 6; radius: 3; color: "#2a2e36"
                    }
                }

                delegate: Rectangle {
                    width: ListView.view.width - 16; height: 64
                    x: 8; radius: 6
                    color: mouseArea.containsMouse ? "#252830" : "transparent"
                    border.color: mouseArea.containsMouse ? "#2a2e36" : "transparent"

                    MouseArea {
                        id: mouseArea; anchors.fill: parent; hoverEnabled: true
                    }

                    // 设备图标
                    Rectangle {
                        anchors.left: parent.left; anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36; height: 36; radius: 8
                        color: Qt.rgba(66/255, 168/255, 95/255, 0.08)
                        border.color: Qt.rgba(66/255, 168/255, 95/255, 0.2)

                        Text {
                            anchors.centerIn: parent
                            text: "⬡"; color: "#42a85f"; font.pixelSize: 18
                        }
                    }

                    // 设备信息
                    Column {
                        anchors.left: parent.left; anchors.leftMargin: 56
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right; anchors.rightMargin: 12
                        spacing: 3

                        Text {
                            width: parent.width
                            text: model.name; color: "#d4d7dc"
                            font.pixelSize: 13; font.weight: Font.DemiBold
                            font.family: "微软雅黑"; elide: Text.ElideRight
                        }
                        Text {
                            text: model.type + "  ·  " + model.vendor
                            color: "#555c69"; font.pixelSize: 10
                            font.family: "微软雅黑"; elide: Text.ElideRight
                        }
                        Row {
                            spacing: 10
                            Text {
                                text: "SM: " + model.smCount
                                color: "#88909e"; font.pixelSize: 10; font.family: "微软雅黑"
                            }
                            Text {
                                text: "RxPDO: " + model.rxCount
                                color: "#5294e2"; font.pixelSize: 10; font.family: "微软雅黑"
                            }
                            Text {
                                text: "TxPDO: " + model.txCount
                                color: "#42a85f"; font.pixelSize: 10; font.family: "微软雅黑"
                            }
                            Text {
                                text: "CoE: " + model.hasCoe
                                color: model.hasCoe === "Yes" ? "#42a85f" : "#555c69"
                                font.pixelSize: 10; font.family: "微软雅黑"
                            }
                        }
                    }

                    // 底部分隔线
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left; anchors.leftMargin: 56
                        anchors.right: parent.right; anchors.rightMargin: 12
                        height: 1
                        color: Qt.rgba(42/255, 46/255, 54/255, 0.4)
                        visible: index < deviceListModel.count - 1
                    }
                }

                // 列表为空
                Text {
                    anchors.centerIn: parent
                    text: "No devices loaded.\nOpen an ESI file in the ESI Browser tab first."
                    color: "#555c69"; font.pixelSize: 11; font.family: "微软雅黑"
                    horizontalAlignment: Text.AlignHCenter
                    visible: deviceListModel.count === 0
                }
            }
        }

        // ── 右侧占位 ──────────────────────────────────────────
        Rectangle {
            anchors.top: parent.top
            anchors.left: slavePanel.right
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            color: ThemeManager.current.bgWindow

            Column {
                anchors.centerIn: parent; spacing: 10
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "⬡"
                    color: "#555c69"; font.pixelSize: 40; opacity: 0.3
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Topology editor coming soon"
                    color: ThemeManager.current.textMuted
                    font.pixelSize: 13; font.family: "微软雅黑"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Select a slave to add to the topology"
                    color: ThemeManager.current.navIconDefault
                    font.pixelSize: 11; font.family: "微软雅黑"
                }
            }
        }
    }

    // ── 键盘快捷键标签 ────────────────────────────────────────
    component KbdLabel: Rectangle {
        property string text: ""
        width: kbdText.implicitWidth + 10
        height: 20; radius: 3
        color: ThemeManager.current.bgWindow
        border.width: 1; border.color: ThemeManager.current.navBorder

        Text {
            id: kbdText; anchors.centerIn: parent
            text: parent.text; color: ThemeManager.current.navIconDefault
            font.pixelSize: 10; font.family: "微软雅黑"
        }
    }
}
