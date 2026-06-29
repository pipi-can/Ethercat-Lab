import QtQuick
import "../components"

/*
 * @brief: 拓扑画布——Master → S0 → S1 → ... 线性链。
 *         数据由 SimEngine 统一管理。
 */
Rectangle {
    id: root
    color: ThemeManager.current.bgWindow

    property bool hasTopology: SimEngine.slaveCount > 0
    property string insertMode: "append"
    property int insertTarget: -1

    signal slaveSelected(int chainIndex)

    function addSlave(info) {
        var insertAt = -1
        if (insertMode === "before" && insertTarget >= 0 && insertTarget < SimEngine.slaveCount)
            insertAt = insertTarget
        else if (insertMode === "after" && insertTarget >= 0 && insertTarget < SimEngine.slaveCount)
            insertAt = insertTarget + 1

        SimEngine.addSlave(info.fileIndex, info.deviceIndex, insertAt)
        insertMode = "append"
        insertTarget = -1
    }

    function resetInsertMode() {
        insertMode = "append"
        insertTarget = -1
    }

    // ════════════════════════════════════════════════════════════
    // 空状态
    // ════════════════════════════════════════════════════════════
    Item {
        id: emptyState
        anchors.fill: parent
        visible: !hasTopology

        Canvas {
            anchors.fill: parent
            opacity: 0.12
            onPaint: {
                var ctx = getContext("2d")
                ctx.fillStyle = "#5294e2"
                var spacing = 28
                for (var x = spacing; x < width; x += spacing)
                    for (var y = spacing; y < height; y += spacing) {
                        ctx.beginPath()
                        ctx.arc(x, y, 1.2, 0, Math.PI * 2)
                        ctx.fill()
                    }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 380)
            height: 120; radius: 12
            color: "transparent"
            border.width: 2
            border.color: ThemeManager.current.navBorder

            Column {
                anchors.centerIn: parent; spacing: 10
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "⬡  Double-click slaves to add"
                    color: ThemeManager.current.navIconDefault
                    font.pixelSize: 15; font.family: "微软雅黑"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Double-click from the list on the left"
                    color: ThemeManager.current.textMuted
                    font.pixelSize: 11; font.family: "微软雅黑"
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════
    // 链视图
    // ════════════════════════════════════════════════════════════
    Item {
        id: chainView
        anchors.fill: parent
        visible: hasTopology

        Flickable {
            id: flick
            anchors.centerIn: parent
            width: Math.min(chainRow.implicitWidth + 60, parent.width - 20)
            height: 120
            contentWidth: chainRow.implicitWidth + 60
            contentHeight: height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Row {
                id: chainRow
                anchors.verticalCenter: parent.verticalCenter
                x: 30
                spacing: 0

                Rectangle {
                    width: 120; height: 80; radius: 10
                    color: "#1a1d24"
                    border.width: 1.5; border.color: "#5294e2"
                    anchors.verticalCenter: parent.verticalCenter

                    Column {
                        anchors.centerIn: parent; spacing: 5
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 26; height: 26; radius: 6
                            color: Qt.rgba(82/255, 148/255, 226/255, 0.1)
                            border.color: Qt.rgba(82/255, 148/255, 226/255, 0.2)
                            Text { anchors.centerIn: parent; text: "⏻"; color: "#5294e2"; font.pixelSize: 14 }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "EtherCAT"; color: "#d4d7dc"
                            font.pixelSize: 11; font.weight: Font.Bold; font.family: "微软雅黑"
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Master"; color: "#555c69"
                            font.pixelSize: 9; font.family: "微软雅黑"
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right; anchors.rightMargin: -3
                        anchors.verticalCenter: parent.verticalCenter
                        width: 6; height: 6; radius: 3; color: "#5294e2"
                    }
                }

                Repeater {
                    id: chainRepeater
                    model: SimEngine.slaves

                    Row {
                        spacing: 0
                        property int chainIdx: modelData.chainIndex

                        Item {
                            width: 36; height: 80
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                anchors.centerIn: parent
                                width: 26; height: 2; color: "#2a2e36"
                            }
                            Canvas {
                                anchors.right: parent.right; anchors.rightMargin: 1
                                anchors.verticalCenter: parent.verticalCenter
                                width: 9; height: 10
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.fillStyle = "#5294e2"
                                    ctx.beginPath()
                                    ctx.moveTo(0, 0); ctx.lineTo(8, 5); ctx.lineTo(0, 10)
                                    ctx.closePath(); ctx.fill()
                                }
                            }
                        }

                        SlaveNode {
                            width: 180
                            position: chainIdx
                            slaveName: modelData.name
                            vendorName: modelData.vendor
                            smCount: modelData.smCount
                            rxCount: modelData.rxCount
                            txCount: modelData.txCount
                            hasCoe: modelData.hasCoe
                            hasDc: modelData.hasDc
                            deviceIndex: modelData.deviceIndexDisplay || (modelData.deviceIndex + 1)
                            selected: SimEngine.selectedChainIndex === chainIdx
                            anchors.verticalCenter: parent.verticalCenter

                            onNodeClicked: SimEngine.selectSlave(chainIdx)
                            onNodeDoubleClicked: root.slaveSelected(chainIdx)
                            onDeleteClicked: SimEngine.removeSlave(chainIdx)
                            onInsertAfterClicked:  { root.insertMode = "after";  root.insertTarget = chainIdx }
                            onInsertBeforeClicked: { root.insertMode = "before"; root.insertTarget = chainIdx }
                            onAppendClicked:       { root.insertMode = "append"; root.insertTarget = -1 }
                        }
                    }
                }

                Item {
                    width: 40; height: 80
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        anchors.centerIn: parent
                        width: 30; height: 70; radius: 8
                        color: "transparent"
                        border.width: 1.5
                        border.color: Qt.rgba(82/255, 148/255, 226/255, 0.15)
                        Text { anchors.centerIn: parent; text: "+"; color: "#3a3e4a"; font.pixelSize: 18; font.family: "微软雅黑" }
                    }
                }
            }
        }

        Text {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            text: SimEngine.slaveCount + " slave(s)  ·  Click to select  ·  Double-click for PDO  ·  Right-click for menu"
            color: ThemeManager.current.textMuted
            font.pixelSize: 10; font.family: "微软雅黑"
        }
    }
}
