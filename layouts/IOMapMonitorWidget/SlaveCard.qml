import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

/*
 * @brief: 物理链路从站配置卡片（伺服 / IO）。
 */
Rectangle {
    id: root

    property int slaveIndex: 0
    property var slaveData: null

    readonly property bool hasData: slaveData !== null && slaveData !== undefined
    property bool selected: false

    // QML 无法追踪 JS 对象嵌套属性，用独立列表驱动 Repeater
    property var rxEntries: []
    property var txEntries: []

    signal dataChanged()
    signal deleteRequested()
    signal moveUpRequested()
    signal moveDownRequested()
    signal selectRequested()

    readonly property var dataTypes: ["UINT8", "UINT16", "UINT32", "INT8", "INT16", "INT32"]
    property string cardType: "servo"
    readonly property bool isIo: cardType === "io"

    width: parent ? parent.width : 400
    implicitHeight: hasData ? cardColumn.implicitHeight : 0
    visible: hasData
    height: visible ? implicitHeight : 0
    radius: 6
    color: ThemeManager.current.bgTitleBar
    border.width: 0

    // 父组件 layout 重算后 layoutTotal 会变；偏移从 layoutSlave（root.slaves[idx]）读取
    property int layoutStamp: 0
    property var layoutSlave: null

    property bool _fieldSyncing: false

    function syncFields() {
        if (!hasData)
            return
        _fieldSyncing = true
        if (nameInput)
            nameInput.text = slaveData.name || ""
        if (outByteInput)
            outByteInput.text = String(slaveData.outBytes | 0)
        if (inByteInput)
            inByteInput.text = String(slaveData.inBytes | 0)
        _fieldSyncing = false
    }

    function applyIoBytes(field, rawText, input) {
        if (!hasData)
            return
        var v = parseInt(rawText, 10)
        if (isNaN(v)) {
            if (!input)
                return
            v = 0
        }
        v = Math.max(0, Math.min(256, v))
        if (input) {
            _fieldSyncing = true
            input.text = String(v)
            _fieldSyncing = false
        }
        if ((slaveData[field] | 0) === v)
            return
        slaveData[field] = v
        dataChanged()
    }

    Component.onCompleted: {
        if (!slaveData)
            return
        cardType = slaveData.type ? slaveData.type : "servo"
        syncEntryLists()
        syncFields()
    }

    onSlaveDataChanged: {
        if (!slaveData)
            return
        syncEntryLists()
        cardType = slaveData.type ? slaveData.type : "servo"
        syncFields()
    }

    function syncEntryLists() {
        var rx = (slaveData && slaveData.rxEntries) ? slaveData.rxEntries.slice() : []
        var tx = (slaveData && slaveData.txEntries) ? slaveData.txEntries.slice() : []
        rxEntries = rx.map(normalizeEntry)
        txEntries = tx.map(normalizeEntry)
        if (slaveData) {
            slaveData.rxEntries = rxEntries
            slaveData.txEntries = txEntries
        }
    }

    function normalizeEntry(e) {
        var entry = {
            index: e.index || "",
            subIndex: e.subIndex || "",
            name: e.name || "",
            dataType: e.dataType || "UINT8",
            bitLen: e.bitLen !== undefined ? e.bitLen : 8
        }
        if (!entry.subIndex && entry.index.indexOf(":") >= 0) {
            var parts = entry.index.split(":")
            entry.index = parts[0].trim()
            var sub = parts.length > 1 ? parts[1].trim() : "00"
            if (sub && !sub.toLowerCase().startsWith("0x"))
                sub = "0x" + sub
            entry.subIndex = sub
        }
        if (!entry.subIndex)
            entry.subIndex = "0x00"
        return entry
    }

    function commitRxEntries(list) {
        rxEntries = list
        if (slaveData)
            slaveData.rxEntries = list
    }

    function commitTxEntries(list) {
        txEntries = list
        if (slaveData)
            slaveData.txEntries = list
    }

    function bitLenForType(type) {
        switch (type) {
        case "UINT8": case "INT8":   return 8
        case "UINT16": case "INT16": return 16
        case "UINT32": case "INT32": return 32
        default: return 8
        }
    }

    function makeNewEntry() {
        return { index: "", subIndex: "0x00", name: "", dataType: "UINT8", bitLen: 8 }
    }

    function applyTypeChange(newType) {
        if (!slaveData || cardType === newType)
            return
        slaveData.type = newType
        cardType = newType
        if (newType === "servo") {
            if (!slaveData.rxEntries)
                slaveData.rxEntries = []
            if (!slaveData.txEntries)
                slaveData.txEntries = []
            syncEntryLists()
        } else {
            if (slaveData.outBytes === undefined)
                slaveData.outBytes = 4
            if (slaveData.inBytes === undefined)
                slaveData.inBytes = 4
        }
        root.dataChanged()
    }

    function addEntry(dir) {
        if (!slaveData)
            return
        var entry = makeNewEntry()
        if (dir === "rx") {
            var rxList = rxEntries.slice()
            rxList.push(entry)
            commitRxEntries(rxList)
        } else {
            var txList = txEntries.slice()
            txList.push(entry)
            commitTxEntries(txList)
        }
        root.dataChanged()
    }

    function removeEntry(dir, idx) {
        if (!slaveData)
            return
        if (dir === "rx") {
            var rxList = rxEntries.slice()
            rxList.splice(idx, 1)
            commitRxEntries(rxList)
        } else {
            var txList = txEntries.slice()
            txList.splice(idx, 1)
            commitTxEntries(txList)
        }
        root.dataChanged()
    }

    function applyEntryField(dir, idx, field, value) {
        var list = dir === "rx" ? rxEntries.slice() : txEntries.slice()
        if (!list[idx])
            return
        if (list[idx][field] === value)
            return
        list[idx][field] = value
        if (field === "dataType")
            list[idx].bitLen = bitLenForType(value)
        if (dir === "rx")
            commitRxEntries(list)
        else
            commitTxEntries(list)
    }

    Column {
        id: cardColumn
        width: parent.width
        spacing: 0

        // ── 卡片头 ──────────────────────────────────────────────
        Rectangle {
            width: parent.width
            height: 44
            radius: 6
            color: ThemeManager.current.bgSurface
            border.width: 0

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 4
                    color: root.isIo ? ThemeManager.current.warnMutedBg
                                      : ThemeManager.current.accentMutedBg

                    Text {
                        anchors.centerIn: parent
                        text: "#" + (root.slaveIndex + 1)
                        color: root.isIo ? ThemeManager.current.warn : ThemeManager.current.accent
                        font.pixelSize: 11
                        font.bold: true
                        font.family: "微软雅黑"
                    }
                }

                InputField {
                    id: nameInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    radius: 4
                    font.pixelSize: 11
                    font.family: "微软雅黑"

                    onTextEdited: function(t) {
                        if (_fieldSyncing || !hasData)
                            return
                        if (slaveData.name !== t) {
                            slaveData.name = t
                            root.dataChanged()
                        }
                    }
                }

                ComboBox {
                    id: typeCombo
                    Layout.preferredWidth: 88
                    Layout.preferredHeight: 26
                    model: [qsTr("伺服"), qsTr("IO 模块")]
                    currentIndex: root.isIo ? 1 : 0

                    delegate: ItemDelegate {
                        width: typeCombo.width
                        contentItem: Text {
                            text: modelData
                            color: ThemeManager.current.inputText
                            font.pixelSize: 11
                            font.family: "微软雅黑"
                            leftPadding: 6
                        }
                        background: Rectangle {
                            color: typeCombo.highlightedIndex === index
                                   ? ThemeManager.current.bgSurfaceHover : "transparent"
                        }
                    }

                    popup: Popup {
                        y: typeCombo.height - 1
                        width: typeCombo.width
                        implicitHeight: Math.min(typeList.contentHeight + 2, 120)
                        padding: 0
                        contentItem: ListView {
                            id: typeList
                            clip: true
                            implicitHeight: contentHeight
                            model: typeCombo.popup.visible ? typeCombo.delegateModel : null
                            currentIndex: typeCombo.highlightedIndex
                            delegate: typeCombo.delegate
                        }
                        background: Rectangle {
                            color: ThemeManager.current.inputBg
                            border.color: ThemeManager.current.inputBorder
                            border.width: 1
                            radius: 4
                        }
                    }

                    background: Rectangle {
                        color: ThemeManager.current.inputBg
                        border.color: typeCombo.activeFocus
                                      ? ThemeManager.current.inputBorderFocus
                                      : ThemeManager.current.inputBorder
                        border.width: 1
                        radius: 4
                    }

                    contentItem: Text {
                        leftPadding: 6
                        text: typeCombo.displayText
                        color: ThemeManager.current.inputText
                        font.pixelSize: 11
                        font.family: "微软雅黑"
                        verticalAlignment: Text.AlignVCenter
                    }

                    onActivated: function(i) {
                        root.applyTypeChange(i === 0 ? "servo" : "io")
                    }
                }

                Row {
                    spacing: 2

                    SlaveActBtn { label: "↑"; onTriggered: root.moveUpRequested() }
                    SlaveActBtn { label: "↓"; onTriggered: root.moveDownRequested() }
                    SlaveActBtn {
                        label: "×"
                        dangerHover: true
                        onTriggered: root.deleteRequested()
                    }
                }
            }
        }

        // ── 卡片体 ──────────────────────────────────────────────
        Column {
            width: parent.width
            spacing: 12
            padding: 12

            // IO 从站
            Column {
                width: parent.width - 24
                spacing: 6
                visible: root.isIo
                height: visible ? implicitHeight : 0

                Row {
                    spacing: 16

                    Row {
                        spacing: 6

                        Text {
                            text: qsTr("输出字节")
                            color: ThemeManager.current.textMuted
                            font.pixelSize: 10
                            font.family: "微软雅黑"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        InputField {
                            id: outByteInput
                            width: 56
                            height: 26
                            radius: 4
                            font.pixelSize: 11
                            font.family: "Consolas"

                            onTextEdited: function(t) {
                                if (_fieldSyncing)
                                    return
                                root.applyIoBytes("outBytes", t, outByteInput)
                            }
                        }
                    }

                    Row {
                        spacing: 6

                        Text {
                            text: qsTr("输入字节")
                            color: ThemeManager.current.textMuted
                            font.pixelSize: 10
                            font.family: "微软雅黑"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        InputField {
                            id: inByteInput
                            width: 56
                            height: 26
                            radius: 4
                            font.pixelSize: 11
                            font.family: "Consolas"

                            onTextEdited: function(t) {
                                if (_fieldSyncing)
                                    return
                                root.applyIoBytes("inBytes", t, inByteInput)
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    readonly property string ioOffsetText: {
                        var _s = layoutStamp
                        if (!layoutSlave)
                            return qsTr("Outputs 区偏移 +—，Inputs 区偏移 +—")
                        var o = layoutSlave._outByteOff
                        var i = layoutSlave._inByteOff
                        return qsTr("Outputs 区偏移 +%1，Inputs 区偏移 +%2")
                               .arg(o !== undefined ? o : "—")
                               .arg(i !== undefined ? i : "—")
                    }
                    text: ioOffsetText
                    color: ThemeManager.current.textMuted
                    font.pixelSize: 10
                    font.family: "微软雅黑"
                    wrapMode: Text.WordWrap
                }
            }

            // 伺服从站
            Column {
                width: parent.width - 24
                spacing: 12
                visible: !root.isIo
                height: visible ? implicitHeight : 0

                PdoSection {
                    width: parent.width
                    title: qsTr("Outputs 区 / 主站写")
                    dirLabel: "RxPDO"
                    dirColor: ThemeManager.current.accent
                    dirBg: ThemeManager.current.accentMutedBg
                    entryDir: "rx"
                    entryCount: root.rxEntries.length
                    layoutSlave: root.layoutSlave
                    layoutStamp: root.layoutStamp
                    onEntryFieldChanged: function(idx, field, value) {
                        root.applyEntryField("rx", idx, field, value)
                        root.dataChanged()
                    }
                    onEntryRemoved: function(idx) { root.removeEntry("rx", idx) }
                    onAddEntry: root.addEntry("rx")
                }

                PdoSection {
                    width: parent.width
                    title: qsTr("Inputs 区 / 主站读")
                    dirLabel: "TxPDO"
                    dirColor: ThemeManager.current.success
                    dirBg: ThemeManager.current.successMutedBg
                    entryDir: "tx"
                    entryCount: root.txEntries.length
                    layoutSlave: root.layoutSlave
                    layoutStamp: root.layoutStamp
                    onEntryFieldChanged: function(idx, field, value) {
                        root.applyEntryField("tx", idx, field, value)
                        root.dataChanged()
                    }
                    onEntryRemoved: function(idx) { root.removeEntry("tx", idx) }
                    onAddEntry: root.addEntry("tx")
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onPressed: root.selectRequested()
    }

    // ── 内联子组件 ──────────────────────────────────────────────

    component SlaveActBtn: Rectangle {
        property string label: ""
        property bool dangerHover: false
        signal triggered()

        width: 26
        height: 26
        radius: 4
        color: {
            if (!actMouse.containsMouse)
                return "transparent"
            return dangerHover ? ThemeManager.current.dangerPress
                               : ThemeManager.current.bgSeparator
        }

        Text {
            anchors.centerIn: parent
            text: label
            color: actMouse.containsMouse
                   ? (dangerHover ? ThemeManager.current.danger : ThemeManager.current.textPrimary)
                   : ThemeManager.current.textMuted
            font.pixelSize: 12
            font.family: "微软雅黑"
        }

        MouseArea {
            id: actMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.triggered()
        }
    }

    component PdoSection: Column {
        property string title: ""
        property string dirLabel: ""
        property string entryDir: "rx"
        property int entryCount: 0
        property var layoutSlave: null
        property int layoutStamp: 0
        property color dirColor: ThemeManager.current.accent
        property color dirBg: ThemeManager.current.accentMutedBg

        signal entryFieldChanged(int idx, string field, var value)
        signal entryRemoved(int idx)
        signal addEntry()

        readonly property int _idxW: 64
        readonly property int _subW: 48
        readonly property int _typeW: 72
        readonly property int _numW: 48
        readonly property int _delW: 28
        readonly property int _nameW: Math.max(60, width - _idxW - _subW - _typeW - _numW * 2 - _delW - 24)

        spacing: 6

        RowLayout {
            width: parent.width
            spacing: 6

            Rectangle {
                Layout.preferredWidth: dirTag.implicitWidth + 12
                Layout.preferredHeight: 18
                radius: 3
                color: dirBg

                Text {
                    id: dirTag
                    anchors.centerIn: parent
                    text: dirLabel
                    color: dirColor
                    font.pixelSize: 9
                    font.bold: true
                    font.family: "微软雅黑"
                }
            }

            Text {
                text: title
                color: ThemeManager.current.textSecondary
                font.pixelSize: 10
                font.bold: true
                font.family: "微软雅黑"
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            PdoAddBtn {
                label: dirLabel === "RxPDO" ? qsTr("+ Rx") : qsTr("+ Tx")
                onTriggered: addEntry()
            }
        }

        Text {
            visible: entryCount === 0
            text: qsTr("无条目")
            color: ThemeManager.current.textMuted
            font.pixelSize: 10
            font.family: "微软雅黑"
        }

        Column {
            width: parent.width
            spacing: 0
            visible: entryCount > 0

            Row {
                width: parent.width
                height: 24
                spacing: 4

                PdoHeaderCell { width: _idxW; label: qsTr("主索引") }
                PdoHeaderCell { width: _subW; label: qsTr("子索引") }
                PdoHeaderCell { width: _nameW; label: qsTr("名称") }
                PdoHeaderCell { width: _typeW; label: qsTr("类型") }
                PdoHeaderCell { width: _numW; label: qsTr("位宽"); hAlign: Text.AlignHCenter }
                PdoHeaderCell { width: _numW; label: qsTr("偏移"); hAlign: Text.AlignHCenter }
                Item { width: _delW }
            }

            Repeater {
                model: entryCount

                Row {
                    required property int index
                    width: parent.width
                    height: 30
                    spacing: 4

                    readonly property int rowIdx: index
                    readonly property var entry: entryDir === "rx"
                            ? root.rxEntries[rowIdx] : root.txEntries[rowIdx]

                    InputField {
                        width: _idxW
                        height: 24
                        text: entry ? (entry.index || "") : ""
                        radius: 3
                        font.pixelSize: 10
                        font.family: "Consolas"
                        onTextEdited: function(t) {
                            if (entry && entry.index !== t)
                                entryFieldChanged(rowIdx, "index", t)
                        }
                    }

                    InputField {
                        width: _subW
                        height: 24
                        text: entry ? (entry.subIndex || "0x00") : "0x00"
                        radius: 3
                        font.pixelSize: 10
                        font.family: "Consolas"
                        onTextEdited: function(t) {
                            if (entry && entry.subIndex !== t)
                                entryFieldChanged(rowIdx, "subIndex", t)
                        }
                    }

                    InputField {
                        width: _nameW
                        height: 24
                        text: entry ? (entry.name || "") : ""
                        radius: 3
                        font.pixelSize: 10
                        font.family: "微软雅黑"
                        onTextEdited: function(t) {
                            if (entry && entry.name !== t)
                                entryFieldChanged(rowIdx, "name", t)
                        }
                    }

                    ComboBox {
                        id: typeFieldCombo
                        width: _typeW
                        height: 24
                        model: root.dataTypes
                        currentIndex: entry
                                ? Math.max(0, model.indexOf(entry.dataType || "UINT8"))
                                : 0

                        delegate: ItemDelegate {
                            width: typeFieldCombo.width
                            contentItem: Text {
                                text: modelData
                                color: ThemeManager.current.inputText
                                font.pixelSize: 10
                                font.family: "微软雅黑"
                                leftPadding: 6
                            }
                            background: Rectangle {
                                color: typeFieldCombo.highlightedIndex === index
                                       ? ThemeManager.current.bgSurfaceHover : "transparent"
                            }
                        }

                        popup: Popup {
                            y: typeFieldCombo.height - 1
                            width: typeFieldCombo.width
                            implicitHeight: Math.min(pdoTypeList.contentHeight + 2, 160)
                            padding: 0
                            contentItem: ListView {
                                id: pdoTypeList
                                clip: true
                                implicitHeight: contentHeight
                                model: typeFieldCombo.popup.visible ? typeFieldCombo.delegateModel : null
                                currentIndex: typeFieldCombo.highlightedIndex
                                delegate: typeFieldCombo.delegate
                            }
                            background: Rectangle {
                                color: ThemeManager.current.inputBg
                                border.color: ThemeManager.current.inputBorder
                                border.width: 1
                                radius: 3
                            }
                        }

                        background: Rectangle {
                            color: ThemeManager.current.inputBg
                            border.color: ThemeManager.current.inputBorder
                            border.width: 1
                            radius: 3
                        }

                        contentItem: Text {
                            leftPadding: 6
                            text: parent.displayText
                            color: ThemeManager.current.inputText
                            font.pixelSize: 10
                            font.family: "微软雅黑"
                            verticalAlignment: Text.AlignVCenter
                        }

                        onActivated: function(i) {
                            if (!entry || entry.dataType === model[i])
                                return
                            entryFieldChanged(rowIdx, "dataType", model[i])
                        }
                    }

                    Text {
                        width: _numW
                        height: 24
                        text: entry
                              ? String(entry.bitLen !== undefined
                                       ? entry.bitLen
                                       : root.bitLenForType(entry.dataType || "UINT8"))
                              : "—"
                        color: ThemeManager.current.textSecondary
                        font.pixelSize: 10
                        font.family: "微软雅黑"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        width: _numW
                        height: 24
                        readonly property string offsetText: {
                            var _s = layoutStamp
                            if (!layoutSlave)
                                return "—"
                            var list = entryDir === "rx" ? layoutSlave.rxEntries : layoutSlave.txEntries
                            var e = list && list[rowIdx] ? list[rowIdx] : null
                            var off = e ? e.byteOff : undefined
                            return off !== undefined ? ("+" + off) : "—"
                        }
                        text: offsetText
                        color: ThemeManager.current.textMuted
                        font.pixelSize: 10
                        font.family: "微软雅黑"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Rectangle {
                        width: _delW
                        height: 24
                        radius: 3
                        color: delMouse.containsMouse ? ThemeManager.current.dangerPress : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: delMouse.containsMouse ? ThemeManager.current.danger
                                                          : ThemeManager.current.textMuted
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: delMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: function() { entryRemoved(rowIdx) }
                        }
                    }
                }
            }
        }
    }

    component PdoAddBtn: Rectangle {
        property string label: ""
        signal triggered()

        height: 22
        width: btnText.implicitWidth + 14
        radius: 4
        color: addBtnMouse.containsMouse ? ThemeManager.current.accentMutedBg : "transparent"
        border.color: addBtnMouse.containsMouse ? ThemeManager.current.accent
                                                 : ThemeManager.current.bgSeparator
        border.width: 1

        Text {
            id: btnText
            anchors.centerIn: parent
            text: label
            color: addBtnMouse.containsMouse ? ThemeManager.current.accent
                                             : ThemeManager.current.textMuted
            font.pixelSize: 9
            font.family: "微软雅黑"
        }

        MouseArea {
            id: addBtnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.triggered()
        }
    }

    component PdoHeaderCell: Text {
        property int hAlign: Text.AlignLeft
        property string label: ""

        text: label
        color: ThemeManager.current.textMuted
        font.pixelSize: 10
        font.family: "微软雅黑"
        horizontalAlignment: hAlign
        verticalAlignment: Text.AlignVCenter
        height: 24
    }
}
