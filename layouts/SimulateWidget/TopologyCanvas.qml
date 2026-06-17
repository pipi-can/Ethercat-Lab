import QtQuick
import "../components"

/*
 * @brief: 拓扑画布——接收从站拖入，展示 Master → S0 → S1 → ... 线性链。
 *         拖入的从站追加到链尾；右键节点可移除。
 */
Rectangle {
    id: root
    color: ThemeManager.current.bgWindow

    // ════════════════════════════════════════════════════════════
    // 链数据模型
    // ════════════════════════════════════════════════════════════
    ListModel {
        id: chainModel
    }

    // ════════════════════════════════════════════════════════════
    // 公开接口
    // ════════════════════════════════════════════════════════════
    property bool hasTopology: chainModel.count > 0

    // 插入模式：双击从站列表时插入的位置
    property string insertMode: "append"   // "append" | "before" | "after"
    property int insertTarget: -1           // 目标节点 index

    function addSlave(info) {
        var entry = {
            name:    info.name    || "",
            vendor:  info.vendor  || "",
            type:    info.type    || "",
            smCount: info.smCount || 0,
            rxCount: info.rxCount || 0,
            txCount: info.txCount || 0,
            hasCoe:  info.hasCoe  === "Yes" || info.hasCoe  === true,
            hasDc:   info.hasDc   === "Yes" || info.hasDc   === true,
            deviceIndex: info.deviceIndex || 0
        }

        if (insertMode === "before" && insertTarget >= 0 && insertTarget < chainModel.count) {
            chainModel.insert(insertTarget, entry)
        } else if (insertMode === "after" && insertTarget >= 0 && insertTarget < chainModel.count) {
            chainModel.insert(insertTarget + 1, entry)
        } else {
            chainModel.append(entry)
        }

        // 重置为追加模式
        insertMode = "append"
        insertTarget = -1
    }

    function resetInsertMode() {
        insertMode = "append"
        insertTarget = -1
    }

    // ════════════════════════════════════════════════════════════
    // 空状态：网点 + 拖入提示
    // ════════════════════════════════════════════════════════════
    Item {
        id: emptyState
        anchors.fill: parent
        visible: !hasTopology

        // 网点背景
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

        // 虚线框拖入提示
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
                    text: "⬡  Drop slaves here"
                    color: ThemeManager.current.navIconDefault
                    font.pixelSize: 15; font.family: "微软雅黑"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Drag devices from the list on the left"
                    color: ThemeManager.current.textMuted
                    font.pixelSize: 11; font.family: "微软雅黑"
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════
    // 链视图：Master → S0 → S1 → ...
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

                // ── Master 节点 ──────────────────────────────────
                Rectangle {
                    id: masterNode
                    width: 120; height: 80
                    radius: 10
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
                            Text {
                                anchors.centerIn: parent
                                text: "⏻"; color: "#5294e2"; font.pixelSize: 14
                            }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "EtherCAT"; color: "#d4d7dc"
                            font.pixelSize: 11; font.weight: Font.Bold
                            font.family: "微软雅黑"
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Master"; color: "#555c69"
                            font.pixelSize: 9; font.family: "微软雅黑"
                        }
                    }

                    // 右侧端口
                    Rectangle {
                        anchors.right: parent.right; anchors.rightMargin: -3
                        anchors.verticalCenter: parent.verticalCenter
                        width: 6; height: 6; radius: 3; color: "#5294e2"
                    }
                }

                // ── 从站节点 Repeater ────────────────────────────
                Repeater {
                    id: chainRepeater
                    model: chainModel

                    Row {
                        spacing: 0

                        // 连接线 + 箭头
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
                                    ctx.moveTo(0, 0)
                                    ctx.lineTo(8, 5)
                                    ctx.lineTo(0, 10)
                                    ctx.closePath()
                                    ctx.fill()
                                }
                            }
                        }

                        // 从站节点卡片
                        SlaveNode {
                            width: 180
                            position: model.index
                            slaveName: model.name
                            vendorName: model.vendor
                            smCount:   model.smCount
                            rxCount:   model.rxCount
                            txCount:   model.txCount
                            hasCoe:    model.hasCoe
                            hasDc:     model.hasDc
                            deviceIndex: model.deviceIndex
                            anchors.verticalCenter: parent.verticalCenter

                            onDeleteClicked:      chainModel.remove(model.index)
                            onInsertAfterClicked:  { root.insertMode = "after";  root.insertTarget = model.index }
                            onInsertBeforeClicked: { root.insertMode = "before"; root.insertTarget = model.index }
                            onAppendClicked:       { root.insertMode = "append"; root.insertTarget = -1 }
                        }
                    }
                }

                // ── 链尾 Drop 指示区 ──────────────────────────────
                Item {
                    width: 40; height: 80
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        anchors.centerIn: parent
                        width: 30; height: 70; radius: 8
                        color: "transparent"
                        border.width: 1.5
                        border.color: Qt.rgba(82/255, 148/255, 226/255, 0.15)
                        Text {
                            anchors.centerIn: parent
                            text: "+"; color: "#3a3e4a"
                            font.pixelSize: 18; font.family: "微软雅黑"
                        }
                    }
                }
            }
        }

        // ── 底部提示 ───────────────────────────────────────────
        Text {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            text: chainModel.count + " slave(s) in chain  ·  Right-click a node to remove"
            color: ThemeManager.current.textMuted
            font.pixelSize: 10; font.family: "微软雅黑"
        }
    }

}
