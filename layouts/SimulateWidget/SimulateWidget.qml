import QtQuick
import QtQuick.Controls
import "../components"

/*
 * @brief: 仿真页面 — 从站列表 + 拓扑画布 + PDO 配置 + 帧查看器。
 */
Rectangle {
    id: root
    color: ThemeManager.current.bgWindow

    property bool hasSlaves: ESITreeModel.hasData
    property int slaveCount: SimEngine.slaveCount
    property int frameCount: SimEngine.frameCount
    property string simState: SimEngine.running ? "OP" : "INIT"
    property string cycleTime: "1000 μs"

    property int framePanelHeight: 180
    property bool pdoPanelOpen: false

    function openPdoPanel(chainIndex) {
        SimEngine.selectSlave(chainIndex)
        pdoPanelOpen = true
    }

    function closePdoPanel() {
        pdoPanelOpen = false
    }

    function runSimulation()   { SimEngine.runSimulation(); simState = "OP" }
    function pauseSimulation() { SimEngine.pauseSimulation() }
    function resetSimulation() { SimEngine.resetSimulation(); frameCount = 0 }
    function stepFrame()       { SimEngine.stepFrame() }

    function refreshDeviceList() {
        deviceListModel.clear()
        var devices = ESITreeModel.getLoadedDevices()
        for (var i = 0; i < devices.length; i++) {
            var d = devices[i]
            deviceListModel.append({
                fileIndex:   d.fileIndex !== undefined ? d.fileIndex : 0,
                deviceIndex: d.deviceIndex !== undefined ? d.deviceIndex : 0,
                name:        d.name || "",
                type:        d.type || "",
                vendor:      d.vendorName || "",
                productCode: d.productCode || "",
                smCount:     d.smCount || 0,
                rxCount:     d.rxCount || 0,
                txCount:     d.txCount || 0,
                hasCoe:      d.hasCoe ? "Yes" : "No",
                hasDc:       d.hasDc ? "Yes" : "No"
            })
        }
        root.hasSlaves = ESITreeModel.hasData
    }

    Component.onCompleted: refreshDeviceList()
    onVisibleChanged: { if (visible) refreshDeviceList() }

    Connections {
        target: SimEngine
        function onFrameCountChanged() { root.frameCount = SimEngine.frameCount }
        function onRunningChanged() { root.simState = SimEngine.running ? "OP" : "INIT" }
        function onSlavesChanged() {
            root.slaveCount = SimEngine.slaveCount
            if (SimEngine.slaveCount === 0 || SimEngine.selectedChainIndex < 0)
                root.closePdoPanel()
        }
        function onSelectedChainIndexChanged() {
            if (SimEngine.selectedChainIndex < 0)
                root.closePdoPanel()
        }
    }

    Connections {
        target: ESITreeModel
        function onHasDataChanged() { if (root.visible) refreshDeviceList() }
        function onFileCountChanged() { if (root.visible) refreshDeviceList() }
    }

    ListModel { id: deviceListModel }

    // ════════════════════════════════════════════════════════════
    // 空状态
    // ════════════════════════════════════════════════════════════
    Item {
        id: welcomeView
        anchors.fill: parent
        visible: !root.hasSlaves

        Column {
            anchors.centerIn: parent; spacing: 24
            width: Math.min(parent.width - 48, 440)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "EtherCAT Simulation"
                color: ThemeManager.current.textPrimary
                font.pixelSize: 20; font.weight: Font.Bold; font.family: "微软雅黑"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Load an ESI file from the ESI Browser first"
                color: ThemeManager.current.textSecondary
                font.pixelSize: 12; font.family: "微软雅黑"
            }
        }
    }

    // ════════════════════════════════════════════════════════════
    // 工作区
    // ════════════════════════════════════════════════════════════
    Item {
        id: workspace
        anchors.fill: parent
        visible: root.hasSlaves

        // ── 左侧从站列表 ──────────────────────────────────────
        Rectangle {
            id: slavePanel
            anchors.top: parent.top; anchors.left: parent.left
            anchors.bottom: framePanel.top
            width: 260
            color: "#1c1f26"
            border.color: "#2a2e36"

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

            ListView {
                id: deviceListView
                anchors.top: parent.top; anchors.topMargin: 39
                anchors.horizontalCenter: slavePanel.horizontalCenter
                anchors.bottom: parent.bottom
                width: slavePanel.width - 6
                clip: true; spacing: 2
                model: deviceListModel

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { implicitWidth: 6; radius: 3; color: "#2a2e36" }
                }

                delegate: Rectangle {
                    // ListModel 角色 → delegate 顶层属性（Qt 6.5），子组件直接用 deviceName 避免 model 作用域问题
                    required property int fileIndex
                    required property int deviceIndex
                    required property string name
                    required property string type
                    required property string vendor
                    required property int smCount
                    required property int rxCount
                    required property int txCount
                    required property string hasCoe
                    required property string hasDc

                    width: ListView.view.width - 16; height: 76
                    x: 8; radius: 6
                    color: mouseArea.containsMouse ? "#252830" : "transparent"
                    border.color: mouseArea.containsMouse ? "#2a2e36" : "transparent"

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onDoubleClicked: {
                            topologyCanvas.addSlave({
                                fileIndex:   fileIndex,
                                deviceIndex: deviceIndex,
                                name:        name,
                                vendor:      vendor,
                                type:        type,
                                smCount:     smCount,
                                rxCount:     rxCount,
                                txCount:     txCount,
                                hasCoe:      hasCoe,
                                hasDc:       hasDc
                            })
                        }
                    }

                    Column {
                        anchors.left: parent.left; anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right; anchors.rightMargin: 8
                        spacing: 3

                        // 用 Item+anchors 布局，避免 Row 无宽度导致 name Text 宽度为 0
                        Item {
                            width: parent.width
                            height: 18

                            Text {
                                id: nameText;
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: name
                                color: "#d4d7dc"
                                font.pixelSize: 12; font.weight: Font.DemiBold; font.family: "微软雅黑"
                                elide: Text.ElideMiddle
                            }
                            Rectangle {
                                id: devBadge
                                height: 15; radius: 3
                                width: devIdxText.implicitWidth + 6
                                anchors.left: nameText.right
                                anchors.leftMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                color: Qt.rgba(82/255, 148/255, 226/255, 0.12)
                                Text {
                                    id: devIdxText
                                    anchors.centerIn: parent
                                    text: "D" + (deviceIndex + 1)
                                    color: "#5294e2"; font.pixelSize: 9; font.family: "微软雅黑"
                                }
                            }

                        }
                        Text {
                            width: parent.width
                            text: type + "  ·  " + vendor
                            color: "#555c69"; font.pixelSize: 10; font.family: "微软雅黑"; elide: Text.ElideRight
                        }
                        Row {
                            spacing: 8
                            Text { text: "Rx:" + rxCount; color: "#5294e2"; font.pixelSize: 10; font.family: "微软雅黑" }
                            Text { text: "Tx:" + txCount; color: "#42a85f"; font.pixelSize: 10; font.family: "微软雅黑" }
                        }
                    }
                }
            }
        }

        // ── 中间拓扑画布 ──────────────────────────────────────
        TopologyCanvas {
            id: topologyCanvas
            anchors.top: parent.top
            anchors.left: slavePanel.right
            anchors.right: root.pdoPanelOpen ? pdoPanel.left : parent.right
            anchors.bottom: framePanel.top

            onSlaveSelected: function(chainIndex) { root.openPdoPanel(chainIndex) }
        }

        // ── 右侧 PDO 配置（双击拓扑节点后打开）────────────────
        Rectangle {
            id: pdoPanel
            anchors.top: parent.top; anchors.right: parent.right
            anchors.bottom: framePanel.top
            width: root.pdoPanelOpen ? 320 : 0
            visible: root.pdoPanelOpen
            clip: true
            color: ThemeManager.current.bgWindow
            border.color: ThemeManager.current.navBorder

            Behavior on width {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            Rectangle {
                anchors.left: parent.left; anchors.top: parent.top
                anchors.bottom: parent.bottom; width: 1
                color: ThemeManager.current.navBorder
            }

            // 标题栏 + 关闭
            Rectangle {
                id: pdoPanelHeader
                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                height: 36
                color: ThemeManager.current.bgTitleBar
                border.color: ThemeManager.current.navBorder

                Text {
                    anchors.left: parent.left; anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "PDO Mapping"
                    color: ThemeManager.current.textPrimary
                    font.pixelSize: 12; font.weight: Font.DemiBold; font.family: "微软雅黑"
                }

                MouseArea {
                    anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
                    width: 36
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closePdoPanel()

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: ThemeManager.current.textSecondary
                        font.pixelSize: 12
                    }
                }
            }

            PdoConfigPanel {
                anchors.top: pdoPanelHeader.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
            }
        }

        // ── 底部帧查看器 ──────────────────────────────────────
        Rectangle {
            id: framePanel
            anchors.left: parent.left; anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: root.framePanelHeight
            color: "#1a1d24"

            Rectangle {
                anchors.top: parent.top; anchors.left: parent.left
                anchors.right: parent.right; height: 4
                color: "transparent"

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.SizeVerCursor
                    property int startY: 0
                    property int startH: 0
                    onPressed: function(m) { startY = m.y; startH = root.framePanelHeight }
                    onPositionChanged: function(m) {
                        if (pressed) {
                            var nh = startH + (startY - m.y)
                            root.framePanelHeight = Math.max(100, Math.min(400, nh))
                        }
                    }
                }
            }

            FrameViewer {
                anchors.fill: parent
                anchors.topMargin: 2
            }
        }
    }
}
