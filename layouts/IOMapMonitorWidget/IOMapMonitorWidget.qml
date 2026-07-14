import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

/*
 * @brief: PDO 数据观察者 / IOMap 监视页面（空壳布局）。
 *         从站配置与实时数值区域预留，后续接入 IOMapReceiver。
 */
Rectangle {
    id: root
    color: ThemeManager.current.bgWindow

    readonly property int connBarHeight: 44
    readonly property int statusAreaHeight: 220

    property var slaves: []
    readonly property int slaveCount: slaves.length
    property string selectedSlaveId: ""
    property int layoutObytes: 0
    property int layoutIbytes: 0
    property int layoutTotal: 0

    function _uid() {
        return "s" + Math.random().toString(36).slice(2, 9)
    }

    function _defaultEntry(dir) {
        if (dir === "rx")
            return { index: "0x6040", subIndex: "0x00", name: "Control Word", dataType: "UINT16", bitLen: 16 }
        return { index: "0x6041", subIndex: "0x00", name: "Status Word", dataType: "UINT16", bitLen: 16 }
    }

    function formatEntryLabel(e) {
        if (!e)
            return ""
        var sub = e.subIndex || "0x00"
        return e.index + ":" + sub + " " + e.name
    }

    function newSlave(type) {
        type = type || "servo"
        return {
            id: _uid(),
            name: type === "servo" ? "Servo Axis" : "IO Module",
            type: type,
            outBytes: 4,
            inBytes: 4,
            rxEntries: [],
            txEntries: []
        }
    }

    function _alignBits(bitPos) {
        if (bitPos % 8 !== 0)
            bitPos += 8 - (bitPos % 8)
        return bitPos
    }

    // 按物理链路顺序重算布局，末尾 refreshLivePanel() 刷新右侧列表。
    function recomputeLayout() {
        var bitPos = 0
        var list = slaves

        for (var i = 0; i < list.length; i++) {
            var s = list[i]
            if (s.type === "io") {
                bitPos = _alignBits(bitPos)
                s._outByteOff = bitPos / 8
                s._outBytes = s.outBytes | 0
                bitPos += s._outBytes * 8
            } else {
                var rx = s.rxEntries || []
                for (var j = 0; j < rx.length; j++) {
                    bitPos = _alignBits(bitPos)
                    rx[j].byteOff = bitPos / 8
                    rx[j].bitOff = 0
                    bitPos += (rx[j].bitLen | 0)
                }
            }
        }

        var obytes = _alignBits(bitPos) / 8
        bitPos = obytes * 8

        for (i = 0; i < list.length; i++) {
            s = list[i]
            if (s.type === "io") {
                bitPos = _alignBits(bitPos)
                s._inByteOff = bitPos / 8
                s._inBytes = s.inBytes | 0
                bitPos += s._inBytes * 8
            } else {
                var tx = s.txEntries || []
                for (j = 0; j < tx.length; j++) {
                    bitPos = _alignBits(bitPos)
                    tx[j].byteOff = bitPos / 8
                    tx[j].bitOff = 0
                    bitPos += (tx[j].bitLen | 0)
                }
            }
        }

        layoutObytes = obytes
        layoutIbytes = _alignBits(bitPos) / 8 - obytes
        layoutTotal = layoutObytes + layoutIbytes
        refreshLivePanel()
    }

    // 右侧实时列表数据，recomputeLayout 末尾调用 refreshLivePanel() 更新
    ListModel {
        id: liveSlaveModel
    }

    function buildLiveRows(s) {
        var rows = []
        if (s.type === "io") {
            var outN = s.outBytes | 0
            var inN = s.inBytes | 0
            for (var i = 0; i < outN; i++)
                rows.push({ label: "OUT" + i, valueKey: s.id + "_out_" + i })
            for (i = 0; i < inN; i++)
                rows.push({ label: "IN" + i, valueKey: s.id + "_in_" + i })
        } else {
            var rx = s.rxEntries || []
            for (i = 0; i < rx.length; i++)
                rows.push({ label: formatEntryLabel(rx[i]), valueKey: s.id + "_rx_" + i })
            var tx = s.txEntries || []
            for (i = 0; i < tx.length; i++)
                rows.push({ label: formatEntryLabel(tx[i]), valueKey: s.id + "_tx_" + i })
        }
        return rows
    }

    function refreshLivePanel() {
        liveSlaveModel.clear()
        for (var i = 0; i < slaves.length; i++) {
            var s = slaves[i]
            var typeLabel = s.type === "io" ? qsTr("IO") : qsTr("伺服")
            var header = (s.name || "") + "  (" + typeLabel + ")"
            var rowsJson = JSON.stringify(buildLiveRows(s))
            liveSlaveModel.append({
                pos: i + 1,
                header: header,
                isIo: s.type === "io",
                rowsJson: rowsJson
            })
        }
    }

    function _setSlaves(list) {
        slaves = list
    }

    function syncSlaveFromCard(idx, cardData) {
        if (!cardData || idx < 0 || idx >= slaves.length)
            return
        var t = slaves[idx]
        t.name = cardData.name
        t.type = cardData.type
        t.outBytes = cardData.outBytes | 0
        t.inBytes = cardData.inBytes | 0
        t.rxEntries = cardData.rxEntries || []
        t.txEntries = cardData.txEntries || []
    }

    function addSlave() {
        var list = slaves.slice()
        var slave = newSlave()
        list.push(slave)
        _setSlaves(list)
        selectedSlaveId = slave.id
        recomputeLayout()
        Qt.callLater(function() {
            chainScroll.contentY = Math.max(0, chainScroll.contentHeight - chainScroll.height)
        })
    }

    function deleteSlave(id) {
        var list = slaves.filter(function(s) { return s.id !== id })
        _setSlaves(list)
        if (selectedSlaveId === id)
            selectedSlaveId = list.length ? list[0].id : ""
        recomputeLayout()
    }

    function moveSlave(id, dir) {
        var idx = -1
        for (var i = 0; i < slaves.length; i++) {
            if (slaves[i].id === id) {
                idx = i
                break
            }
        }
        if (idx < 0)
            return
        var ni = idx + dir
        if (ni < 0 || ni >= slaves.length)
            return
        var list = slaves.slice()
        var tmp = list[idx]
        list[idx] = list[ni]
        list[ni] = tmp
        _setSlaves(list)
        recomputeLayout()
    }

    function moveSelectedSlave(dir) {
        if (!selectedSlaveId)
            return
        moveSlave(selectedSlaveId, dir)
    }

    function buildNetworkConfig() {
        var list = []
        for (var i = 0; i < slaves.length; i++) {
            var s = slaves[i]
            var item = {
                id: s.id,
                name: s.name,
                type: s.type,
                outBytes: s.outBytes | 0,
                inBytes: s.inBytes | 0,
                _outByteOff: s._outByteOff | 0,
                _inByteOff: s._inByteOff | 0,
                rxEntries: [],
                txEntries: []
            }
            if (s.rxEntries) {
                for (var j = 0; j < s.rxEntries.length; j++) {
                    var e = s.rxEntries[j]
                    item.rxEntries.push({
                        index: e.index,
                        subIndex: e.subIndex || "0x00",
                        name: e.name,
                        dataType: e.dataType,
                        bitLen: e.bitLen | 0,
                        byteOff: e.byteOff | 0
                    })
                }
            }
            if (s.txEntries) {
                for (j = 0; j < s.txEntries.length; j++) {
                    e = s.txEntries[j]
                    item.txEntries.push({
                        index: e.index,
                        subIndex: e.subIndex || "0x00",
                        name: e.name,
                        dataType: e.dataType,
                        bitLen: e.bitLen | 0,
                        byteOff: e.byteOff | 0
                    })
                }
            }
            list.push(item)
        }
        return {
            Obytes: layoutObytes,
            Ibytes: layoutIbytes,
            total: layoutTotal,
            slaves: list
        }
    }

    readonly property bool canListen: NetworkManager.clientState === "idle" && slaveCount > 0
    readonly property bool canReceive: {
        if (NetworkManager.receiving)
            return false
        if (NetworkManager.clientState === "connected")
            return true
        return NetworkManager.clientState === "handshaked"
               && NetworkManager.bridgeState === "handshaked"
    }
    readonly property bool canDisconnect: NetworkManager.clientState !== "idle"

    function clientStateLabel() {
        switch (NetworkManager.clientState) {
        case "listening": return qsTr("监听中")
        case "connected": return qsTr("已连接")
        case "handshaked": return qsTr("已握手")
        default: return qsTr("未监听")
        }
    }

    function clientDotColor() {
        switch (NetworkManager.clientState) {
        case "listening":
        case "connected":
            return ThemeManager.current.warn
        case "handshaked":
            return ThemeManager.current.success
        default:
            return ThemeManager.current.textMuted
        }
    }

    function bridgeStateLabel() {
        switch (NetworkManager.bridgeState) {
        case "connected": return qsTr("TCP已连接")
        case "handshaked": return qsTr("已握手")
        case "streaming": return qsTr("数据流")
        default: return qsTr("未连接")
        }
    }

    function bridgeDotColor() {
        switch (NetworkManager.bridgeState) {
        case "connected":
            return ThemeManager.current.warn
        case "handshaked":
        case "streaming":
            return ThemeManager.current.success
        default:
            return ThemeManager.current.textMuted
        }
    }

    function logLineColor(level) {
        switch (level) {
        case "ok": return ThemeManager.current.success
        case "warn": return ThemeManager.current.warn
        case "err": return ThemeManager.current.danger
        case "frame": return ThemeManager.current.accent
        default: return ThemeManager.current.textSecondary
        }
    }

    property string validationErrorText: ""

    function loadDemoPreset() {
        if (NetworkManager.receiving)
            NetworkManager.stopReceive()

        _setSlaves([
            {
                id: _uid(), name: "TerminalCoupler", type: "io",
                outBytes: 4, inBytes: 4,
                rxEntries: [], txEntries: []
            },
            {
                id: _uid(), name: "从站1", type: "servo",
                rxEntries: [
                    { index: "0x6040", subIndex: "0x00", name: "ControlWord", dataType: "UINT16", bitLen: 16 },
                    { index: "0x607A", subIndex: "0x00", name: "TargetPosition", dataType: "INT32", bitLen: 32 },
                    { index: "0x6060", subIndex: "0x00", name: "ModeOfOperation", dataType: "UINT8", bitLen: 8 },
                    { index: "0x60FF", subIndex: "0x00", name: "TargetVelocity", dataType: "INT32", bitLen: 32 },
                    { index: "0x60B8", subIndex: "0x00", name: "TouchProbeFunc", dataType: "UINT16", bitLen: 16 },
                    { index: "0x60FE", subIndex: "0x01", name: "PhysicalOutput", dataType: "UINT32", bitLen: 32 }
                ],
                txEntries: [
                    { index: "0x6041", subIndex: "0x00", name: "StatusWord", dataType: "UINT16", bitLen: 16 },
                    { index: "0x6064", subIndex: "0x00", name: "PositionActualValue", dataType: "INT32", bitLen: 32 },
                    { index: "0x603F", subIndex: "0x00", name: "ServoErrorCode", dataType: "UINT16", bitLen: 16 },
                    { index: "0x6077", subIndex: "0x00", name: "TorqueActualValue", dataType: "INT16", bitLen: 16 },
                    { index: "0x606C", subIndex: "0x00", name: "VelocityActualValue", dataType: "INT32", bitLen: 32 },
                    { index: "0x60B9", subIndex: "0x00", name: "TouchPeobeStatus", dataType: "UINT16", bitLen: 16 },
                    { index: "0x60BA", subIndex: "0x00", name: "TouchProbePos1", dataType: "UINT32", bitLen: 32 },
                    { index: "0x6061", subIndex: "0x00", name: "ModeOfOperation", dataType: "UINT8", bitLen: 8 },
                    { index: "0x60FD", subIndex: "0x00", name: "DigitalInput", dataType: "UINT32", bitLen: 32 }
                ]
            }
        ])
        selectedSlaveId = slaves.length ? slaves[0].id : ""
        recomputeLayout()
    }

    Connections {
        target: NetworkManager
        function onFrameValidationFailed(reason) {
            root.validationErrorText = reason
            validationErrorDialog.open()
        }
    }

    Dialog {
        id: validationErrorDialog
        title: qsTr("帧校验失败")
        modal: true
        standardButtons: Dialog.Ok
        anchors.centerIn: parent
        width: Math.min(400, root.width - 40)

        Label {
            width: parent.width
            text: root.validationErrorText
            wrapMode: Text.Wrap
            color: ThemeManager.current.textPrimary
            font.pixelSize: 12
            font.family: "微软雅黑"
        }
    }

    // ── 连接配置条 ──────────────────────────────────────────────
    Rectangle {
        id: connBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.connBarHeight
        color: ThemeManager.current.bgTitleBar

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: ThemeManager.current.bgSeparator
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 12

            Text {
                text: qsTr("本机监听 IP")
                color: ThemeManager.current.textMuted
                font.pixelSize: 11
                font.family: "微软雅黑"
            }

            InputField {
                id: listenIpField
                Layout.preferredWidth: 140
                Layout.preferredHeight: 28
                text: "0.0.0.0"
                placeholderText: ""
                radius: 4
                font.family: "Consolas"
                font.pixelSize: 11
            }

            Text {
                text: qsTr("桥接器 IP")
                color: ThemeManager.current.textMuted
                font.pixelSize: 11
                font.family: "微软雅黑"
            }

            InputField {
                id: connectorIPField
                Layout.preferredWidth: 140
                Layout.preferredHeight: 28
                text: "0.0.0.0"
                placeholderText: ""
                radius: 4
                font.family: "Consolas"
                font.pixelSize: 11
            }

            Text {
                text: qsTr("端口")
                color: ThemeManager.current.textMuted
                font.pixelSize: 11
                font.family: "微软雅黑"
            }

            InputField {
                id: listenPortField
                Layout.preferredWidth: 72
                Layout.preferredHeight: 28
                text: "9527"
                placeholderText: ""
                radius: 4
                font.family: "Consolas"
                font.pixelSize: 11
            }

            Item { Layout.fillWidth: true }

            Row {
                spacing: 14
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: qsTr("Obytes")
                    color: ThemeManager.current.textSecondary
                    font.pixelSize: 11
                    font.family: "Consolas"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: String(root.layoutObytes)
                    color: ThemeManager.current.accent
                    font.pixelSize: 11
                    font.bold: true
                    font.family: "Consolas"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "|"
                    color: ThemeManager.current.bgSeparator
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: qsTr("Ibytes")
                    color: ThemeManager.current.textSecondary
                    font.pixelSize: 11
                    font.family: "Consolas"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: String(root.layoutIbytes)
                    color: ThemeManager.current.accent
                    font.pixelSize: 11
                    font.bold: true
                    font.family: "Consolas"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "|"
                    color: ThemeManager.current.bgSeparator
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: qsTr("total")
                    color: ThemeManager.current.textSecondary
                    font.pixelSize: 11
                    font.family: "Consolas"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: String(root.layoutTotal)
                    color: ThemeManager.current.accent
                    font.pixelSize: 11
                    font.bold: true
                    font.family: "Consolas"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // ── 下部状态区 ──────────────────────────────────────────────
    Rectangle {
        id: statusArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.statusAreaHeight
        color: ThemeManager.current.bgTitleBar

        Rectangle {
            anchors.top: parent.top
            width: parent.width
            height: 1
            color: ThemeManager.current.bgSeparator
        }

        Column {
            anchors.fill: parent
            spacing: 0

            // 状态 + 控制按钮
            Item {
                width: parent.width
                height: 52

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    StatusPill {
                        label: qsTr("客户端 (PC)")
                        stateText: root.clientStateLabel()
                        dotColor: root.clientDotColor()
                    }
                    StatusPill {
                        label: qsTr("桥接层 (设备)")
                        stateText: root.bridgeStateLabel()
                        dotColor: root.bridgeDotColor()
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    MonitorToolButton {
                        id: btnListen
                        text: qsTr("开始监听")
                        variant: "accent"
                        enabled: root.canListen
                        onClicked: {
                            var port = parseInt(listenPortField.text, 10)
                            if (isNaN(port) || port < 1 || port > 65535)
                                return
                            NetworkManager.startListen(listenIpField.text, port, connectorIPField.text)
                        }
                    }
                    MonitorToolButton {
                        id: btnReceive
                        text: qsTr("开始接收")
                        variant: "success"
                        enabled: root.canReceive
                        onClicked: {
                            root.recomputeLayout()
                            NetworkManager.startReceive(root.buildNetworkConfig())
                        }
                    }
                    MonitorToolButton {
                        id: btnStopReceive
                        text: qsTr("停止接收")
                        enabled: NetworkManager.receiving
                        onClicked: NetworkManager.stopReceive()
                    }
                    MonitorToolButton {
                        id: btnInjectErr
                        text: qsTr("注入错误帧")
                        variant: "warn"
                        enabled: NetworkManager.clientState === "handshaked"
                                 && NetworkManager.bridgeState === "handshaked"
                                 && !NetworkManager.receiving
                        onClicked: NetworkManager.injectNextFrameError()
                    }
                    MonitorToolButton {
                        id: btnDisconnect
                        text: qsTr("断开")
                        variant: "danger"
                        enabled: root.canDisconnect
                        onClicked: NetworkManager.disconnect()
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: ThemeManager.current.bgSeparator
            }

            // 指标行
            Row {
                width: parent.width
                height: 32
                leftPadding: 14
                spacing: 20

                MetricItem {
                    label: "seq"
                    value: NetworkManager.frameCount > 0 ? String(NetworkManager.seq) : "—"
                }
                MetricItem {
                    label: "delta"
                    value: NetworkManager.frameCount > 0 ? String(NetworkManager.delta) : "—"
                }
                MetricItem {
                    label: "~Hz"
                    value: NetworkManager.frameCount > 0
                           ? NetworkManager.hz.toFixed(1) : "—"
                }
                MetricItem {
                    label: qsTr("帧 O+I")
                    value: NetworkManager.receiving
                           ? (root.layoutObytes + "+" + root.layoutIbytes) : "—"
                }
                MetricItem {
                    label: qsTr("校验")
                    value: NetworkManager.checkStatus
                    valueColor: NetworkManager.checkStatus === "失败"
                                ? ThemeManager.current.danger
                                : (NetworkManager.checkStatus === "通过"
                                   ? ThemeManager.current.success
                                   : ThemeManager.current.textPrimary)
                }
                MetricItem {
                    label: qsTr("帧数")
                    value: String(NetworkManager.frameCount)
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: ThemeManager.current.bgSeparator
            }

            // 日志区
            ListView {
                id: logList
                width: parent.width
                height: parent.height - 52 - 32 - 2
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: NetworkManager.logModel
                spacing: 2

                onCountChanged: Qt.callLater(function() {
                    if (count > 0)
                        logList.positionViewAtEnd()
                })

                delegate: Text {
                    required property int index
                    required property var modelData
                    width: logList.width - 28
                    x: 14
                    wrapMode: Text.Wrap
                    font.pixelSize: 10
                    font.family: "Consolas"
                    color: root.logLineColor(modelData.level)
                    text: "[" + modelData.time + "] " + modelData.text
                }
            }
        }
    }

    // ── 上部配置区（左配置 / 右实时）──────────────────────────────
    Item {
        id: configArea
        anchors.top: connBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: statusArea.top

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: ThemeManager.current.bgSeparator
        }

        // 左侧：从站配置（空）
        Rectangle {
            id: slaveConfigPanel
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: parent.width * 0.6
            color: ThemeManager.current.bgWindow

            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: 1
                color: ThemeManager.current.bgSeparator
            }

            SlavePanelHeader {
                id: slaveConfigHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                title: qsTr("物理链路从站配置")
                subtitle: slaveCount + qsTr(" 个从站")
                moveEnabled: slaveCount >= 2

                onAddSlaveClicked: root.addSlave()
                onMoveUpClicked: root.moveSelectedSlave(-1)
                onMoveDownClicked: root.moveSelectedSlave(1)
            }

            Flickable {
                id: chainScroll
                anchors.top: slaveConfigHeader.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: chainColumn.implicitHeight

                Column {
                    id: chainColumn
                    width: chainScroll.width
                    spacing: 10
                    topPadding: 10
                    leftPadding: 10
                    rightPadding: 10
                    bottomPadding: 10

                    ChainEmptyHint {
                        width: parent.width - 20
                        visible: slaveCount === 0
                        onAddFirstSlave: root.addSlave()
                    }

                    Repeater {
                        model: root.slaves

                        SlaveCard {
                            required property int index
                            required property var modelData
                            width: chainColumn.width - 20
                            slaveIndex: index
                            slaveData: modelData
                            layoutSlave: root.slaves[index]
                            layoutStamp: root.layoutTotal
                            selected: modelData && modelData.id === root.selectedSlaveId

                            onDataChanged: {
                                root.syncSlaveFromCard(index, slaveData)
                                root.recomputeLayout()
                            }
                            onDeleteRequested: {
                                if (slaveData)
                                    root.deleteSlave(slaveData.id)
                            }
                            onMoveUpRequested: {
                                if (slaveData)
                                    root.moveSlave(slaveData.id, -1)
                            }
                            onMoveDownRequested: {
                                if (slaveData)
                                    root.moveSlave(slaveData.id, 1)
                            }
                            onSelectRequested: {
                                if (slaveData)
                                    root.selectedSlaveId = slaveData.id
                            }
                        }
                    }
                }
            }
        }

        // 右侧：实时数值（空）
        Rectangle {
            id: liveValuesPanel
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.left: slaveConfigPanel.right
            color: ThemeManager.current.bgTitleBar

            PanelHeaderBar {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                title: qsTr("实时数值")
                subtitle: NetworkManager.receiving ? qsTr("接收中")
                        : (slaveCount === 0 ? qsTr("等待接收") : qsTr("等待接收"))
            }

            Flickable {
                id: liveScroll
                anchors.top: parent.top
                anchors.topMargin: 36
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: liveColumn.implicitHeight

                Column {
                    id: liveColumn
                    width: liveScroll.width
                    spacing: 8
                    topPadding: 8
                    leftPadding: 8
                    rightPadding: 8
                    bottomPadding: 8

                    EmptyHint {
                        width: parent.width - 16
                        visible: slaveCount === 0
                        message: qsTr("建立连接后点击「开始接收」") + "\n"
                                 + qsTr("此处显示过程数据解码值")
                    }

                    Repeater {
                        model: liveSlaveModel

                        LiveSlaveBlock {
                            required property int index
                            required property int pos
                            required property string header
                            required property bool isIo
                            required property string rowsJson
                            width: liveColumn.width - 16
                            slaveIndex: pos - 1
                            headerText: header
                            isIoType: isIo
                            rows: JSON.parse(rowsJson)
                        }
                    }
                }
            }
        }
    }

    component SlavePanelHeader: Rectangle {
        property string title: ""
        property string subtitle: ""
        property bool moveEnabled: false

        signal addSlaveClicked()
        signal moveUpClicked()
        signal moveDownClicked()

        height: 36
        color: ThemeManager.current.bgTitleBar

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: ThemeManager.current.bgSeparator
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            Text {
                text: title
                color: ThemeManager.current.textPrimary
                font.pixelSize: 11
                font.bold: true
                font.family: "微软雅黑"
                font.letterSpacing: 0.5
            }

            Text {
                text: subtitle
                color: ThemeManager.current.textMuted
                font.pixelSize: 10
                font.family: "微软雅黑"
            }

            Item { Layout.fillWidth: true }

            Row {
                spacing: 4

                PanelActionBtn {
                    text: qsTr("上移")
                    enabled: moveEnabled
                    onTriggered: moveUpClicked()
                }
                PanelActionBtn {
                    text: qsTr("下移")
                    enabled: moveEnabled
                    onTriggered: moveDownClicked()
                }
                PanelActionBtn {
                    text: qsTr("添加从站")
                    accent: true
                    onTriggered: addSlaveClicked()
                }
            }
        }
    }

    component PanelActionBtn: Rectangle {
        property string text: ""
        property bool accent: false
        signal triggered()

        height: 24
        width: label.implicitWidth + 16
        radius: 4
        opacity: enabled ? 1.0 : 0.35

        color: {
            if (accent) {
                if (!enabled) return ThemeManager.current.accent
                if (actMouse.pressed) return ThemeManager.current.accentPress
                if (actMouse.containsMouse) return ThemeManager.current.accentHover
                return ThemeManager.current.accent
            }
            if (!enabled) return "transparent"
            if (actMouse.containsMouse) return ThemeManager.current.bgSurfaceHover
            return "transparent"
        }

        border.width: accent ? 0 : 1
        border.color: ThemeManager.current.bgSeparator

        Text {
            id: label
            anchors.centerIn: parent
            text: parent.text
            color: accent ? ThemeManager.current.textOnSolid
                           : (actMouse.containsMouse ? ThemeManager.current.textPrimary
                                                     : ThemeManager.current.textSecondary)
            font.pixelSize: 10
            font.bold: accent
            font.family: "微软雅黑"
        }

        MouseArea {
            id: actMouse
            anchors.fill: parent
            enabled: parent.enabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (enabled) parent.triggered()
        }
    }

    component ChainEmptyHint: Item {
        signal addFirstSlave()

        implicitHeight: emptyCol.implicitHeight + 64

        Column {
            id: emptyCol
            anchors.centerIn: parent
            spacing: 10
            width: Math.min(parent.width, 320)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                text: qsTr("按物理链路顺序添加从站") + "\n"
                      + qsTr("顺序必须与 IOMap 排布一致") + "\n"
                      + qsTr("左侧列表可滚动，每张卡片完整展示配置")
                color: ThemeManager.current.textMuted
                font.pixelSize: 11
                font.family: "微软雅黑"
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.6
                wrapMode: Text.WordWrap
            }

            PanelActionBtn {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("添加第一个从站")
                accent: true
                onTriggered: addFirstSlave()
            }
        }
    }

    component LiveSlaveBlock: Rectangle {
        id: liveBlockRoot
        property int slaveIndex: 0
        property string headerText: ""
        property bool isIoType: false
        property var rows: []

        visible: rows.length > 0 || headerText !== ""
        height: visible ? implicitHeight : 0

        radius: 6
        color: ThemeManager.current.bgWindow
        border.color: ThemeManager.current.bgSeparator
        border.width: 1
        implicitHeight: liveBody.implicitHeight

        Column {
            id: liveBody
            width: parent.width
            spacing: 0

            Rectangle {
                width: parent.width
                height: 28
                color: ThemeManager.current.bgSurface

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 6

                    Rectangle {
                        width: posLabel.implicitWidth + 10
                        height: 18
                        radius: 3
                        color: liveBlockRoot.isIoType ? ThemeManager.current.warnMutedBg
                                                        : ThemeManager.current.accentMutedBg
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            id: posLabel
                            anchors.centerIn: parent
                            text: "#" + (slaveIndex + 1)
                            color: liveBlockRoot.isIoType ? ThemeManager.current.warn
                                                            : ThemeManager.current.accent
                            font.pixelSize: 9
                            font.bold: true
                            font.family: "微软雅黑"
                        }
                    }

                    Text {
                        text: liveBlockRoot.headerText
                        color: ThemeManager.current.textPrimary
                        font.pixelSize: 10
                        font.bold: true
                        font.family: "微软雅黑"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 0
                padding: 4

                Repeater {
                    model: liveBlockRoot.rows.length

                    LiveValueRow {
                        required property int index
                        width: parent.width - 8
                        label: liveBlockRoot.rows[index].label
                        valueKey: liveBlockRoot.rows[index].valueKey
                    }
                }
            }
        }
    }

    component LiveValueRow: Item {
        id: liveValueRow
        property string label: ""
        property string valueKey: ""

        readonly property var liveVal: {
            var _r = NetworkManager.liveRevision
            if (!valueKey)
                return null
            var map = NetworkManager.liveValues
            return map && map[valueKey] !== undefined ? map[valueKey] : null
        }

        readonly property string hexText: {
            if (!liveVal || liveVal.hex === undefined || liveVal.hex === null)
                return "—"
            var h = String(liveVal.hex)
            return h.toLowerCase().startsWith("0x") ? h : ("0x" + h)
        }

        height: 24

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 10
            spacing: 0

            Text {
                Layout.preferredWidth: Math.min(160, liveValueRow.width * 0.48)
                Layout.maximumWidth: liveValueRow.width * 0.5
                text: label
                color: ThemeManager.current.textMuted
                font.pixelSize: 10
                font.family: "Consolas"
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Text {
                Layout.preferredWidth: 76
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                horizontalAlignment: Text.AlignRight
                text: hexText
                color: liveVal ? ThemeManager.current.accent : ThemeManager.current.textMuted
                font.pixelSize: 10
                font.family: "Consolas"
            }

            Text {
                Layout.preferredWidth: 72
                Layout.leftMargin: 18
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                horizontalAlignment: Text.AlignRight
                text: liveVal ? String(liveVal.dec) : "—"
                color: liveVal ? ThemeManager.current.textSecondary : ThemeManager.current.textMuted
                font.pixelSize: 10
                font.family: "Consolas"
            }
        }
    }

    component PanelHeaderBar: Rectangle {
        property string title: ""
        property string subtitle: ""

        height: 36
        color: ThemeManager.current.bgTitleBar

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: ThemeManager.current.bgSeparator
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            Text {
                text: title
                color: ThemeManager.current.textPrimary
                font.pixelSize: 11
                font.bold: true
                font.family: "微软雅黑"
                font.letterSpacing: 0.5
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: subtitle
                color: ThemeManager.current.textMuted
                font.pixelSize: 10
                font.family: "微软雅黑"
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    component EmptyHint: Item {
        property string message: ""

        Column {
            anchors.centerIn: parent
            spacing: 10
            width: Math.min(parent.width - 48, 320)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                text: message
                color: ThemeManager.current.textMuted
                font.pixelSize: 11
                font.family: "微软雅黑"
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.6
                wrapMode: Text.WordWrap
            }
        }
    }

    component StatusPill: Rectangle {
        property string label: ""
        property string stateText: ""
        property color dotColor: ThemeManager.current.textMuted

        height: 32
        width: pillRow.implicitWidth + 24
        radius: 6
        color: ThemeManager.current.bgWindow
        border.color: ThemeManager.current.bgSeparator
        border.width: 1

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: label
                color: ThemeManager.current.textMuted
                font.pixelSize: 10
                font.family: "微软雅黑"
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: dotColor
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: stateText
                color: ThemeManager.current.textPrimary
                font.pixelSize: 11
                font.bold: true
                font.family: "微软雅黑"
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    component MonitorToolButton: Rectangle {
        id: toolBtn
        property string text: ""
        property string variant: "neutral"   // neutral | accent | success | warn | danger
        signal clicked()

        height: 30
        width: btnLabel.implicitWidth + 20
        radius: 4
        opacity: enabled ? 1.0 : 0.45

        readonly property var pal: {
            var t = ThemeManager.current
            switch (variant) {
            case "accent":
                return { bg: t.accent, hover: t.accentHover, press: t.accentPress,
                         fg: t.textOnSolid, border: "transparent", bold: true }
            case "success":
                return { bg: t.success, hover: t.successHover, press: t.successPress,
                         fg: t.textOnSolid, border: "transparent", bold: true }
            case "warn":
                return { bg: t.warn, hover: t.warnHover, press: t.warnPress,
                         fg: t.textOnSolid, border: "transparent", bold: true }
            case "danger":
                return { bg: t.danger, hover: t.dangerHover, press: t.dangerPress,
                         fg: t.textOnSolid, border: "transparent", bold: true }
            default:
                return { bg: t.bgSurface, hover: t.bgSurfaceHover, press: t.bgSurface,
                         fg: t.textSecondary, border: t.bgSeparator, bold: false }
            }
        }

        color: {
            if (!enabled) return pal.bg
            if (btnMouse.pressed) return pal.press
            if (btnMouse.containsMouse) return pal.hover
            return pal.bg
        }

        border.width: pal.border === "transparent" ? 0 : 1
        border.color: pal.border

        Text {
            id: btnLabel
            anchors.centerIn: parent
            text: toolBtn.text
            color: {
                if (!toolBtn.enabled) return toolBtn.pal.fg
                if (toolBtn.variant === "neutral") {
                    return btnMouse.containsMouse
                           ? ThemeManager.current.textPrimary
                           : ThemeManager.current.textSecondary
                }
                return toolBtn.pal.fg
            }
            font.pixelSize: 11
            font.bold: toolBtn.pal.bold
            font.family: "微软雅黑"
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            enabled: toolBtn.enabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: toolBtn.clicked()
        }
    }

    component MetricItem: Row {
        property string label: ""
        property string value: ""
        property color valueColor: ThemeManager.current.textPrimary

        spacing: 4
        anchors.verticalCenter: parent.verticalCenter

        Text {
            text: label
            color: ThemeManager.current.textMuted
            font.pixelSize: 11
            font.family: "Consolas"
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: value
            color: valueColor
            font.pixelSize: 11
            font.bold: true
            font.family: "Consolas"
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
