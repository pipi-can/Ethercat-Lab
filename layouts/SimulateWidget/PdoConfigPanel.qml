import QtQuick
import QtQuick.Controls
import "../components"

/*
 * @brief: PDO 映射配置面板 — 由 SimulateWidget 双击拓扑节点后打开。
 */
Rectangle {
    id: root
    color: ThemeManager.current.bgWindow

    property int chainIndex: SimEngine.selectedChainIndex
    property var pdoConfig: chainIndex >= 0 ? SimEngine.getSlavePdoConfig(chainIndex) : ({})

    function refreshConfig() {
        pdoConfig = chainIndex >= 0 ? SimEngine.getSlavePdoConfig(chainIndex) : ({})
    }

    Connections {
        target: SimEngine
        function onPdoConfigChanged() { root.refreshConfig() }
        function onSelectedChainIndexChanged() { root.refreshConfig() }
    }

    Flickable {
        anchors.fill: parent
        clip: true
        contentHeight: configColumn.implicitHeight + 24
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: configColumn
            width: parent.width
            spacing: 12
            topPadding: 12; leftPadding: 10; rightPadding: 10; bottomPadding: 12

            Text {
                text: pdoConfig.name || ""
                color: ThemeManager.current.textPrimary
                font.pixelSize: 14; font.weight: Font.Bold; font.family: "微软雅黑"
            }
            Text {
                text: (pdoConfig.vendor || "") + (pdoConfig.profileNo ? "  ·  CiA " + pdoConfig.profileNo : "")
                color: ThemeManager.current.textSecondary
                font.pixelSize: 10; font.family: "微软雅黑"
            }

            PdoSection {
                width: parent.width - 20
                sectionTitle: "OUTPUTS (RxPDO · Master → Slave)"
                accentColor: "#5294e2"
                pdoList: pdoConfig.rxpdos || []
                isRx: true
                chainIdx: root.chainIndex
            }

            PdoSection {
                width: parent.width - 20
                sectionTitle: "INPUTS (TxPDO · Slave → Master)"
                accentColor: "#42a85f"
                pdoList: pdoConfig.txpdos || []
                isRx: false
                chainIdx: root.chainIndex
            }

            Rectangle {
                width: parent.width - 20; height: 30; radius: 6
                color: ThemeManager.current.bgTitleBar
                border.color: ThemeManager.current.navBorder
                Text {
                    anchors.centerIn: parent
                    text: "Output: " + (pdoConfig.outputBytes || 0) + " B  ·  Input: "
                          + (pdoConfig.inputBytes || 0) + " B  ·  Total: "
                          + (pdoConfig.totalBytes || 0) + " B"
                    color: ThemeManager.current.textSecondary
                    font.pixelSize: 10; font.family: "微软雅黑"
                }
            }
        }
    }

    component PdoSection: Column {
        id: sectionRoot
        property string sectionTitle: ""
        property color accentColor: "#5294e2"
        property var pdoList: []
        property bool isRx: true
        property int chainIdx: -1

        spacing: 6; width: parent ? parent.width : 300

        Text {
            text: sectionTitle
            color: accentColor
            font.pixelSize: 10; font.weight: Font.DemiBold; font.family: "微软雅黑"
        }

        Repeater {
            model: pdoList

            Column {
                width: sectionRoot.width
                spacing: 0
                property int pdoIdx: index
                property var pdoData: modelData
                property bool pdoFixed: pdoData.fixed === true
                property bool pdoEnabled: pdoData.enabled !== false

                Rectangle {
                    width: parent.width; height: 26; radius: 4
                    color: ThemeManager.current.bgTitleBar
                    border.color: ThemeManager.current.navBorder

                    Row {
                        anchors.fill: parent; anchors.leftMargin: 6; spacing: 6

                        CheckBox {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: pdoEnabled
                            onToggled: SimEngine.setPdoEnabled(chainIdx, isRx, pdoIdx, checked)
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: (pdoData.index || "") + "  " + (pdoData.name || "")
                            color: ThemeManager.current.textPrimary
                            font.pixelSize: 10; font.weight: Font.DemiBold; font.family: "微软雅黑"
                            elide: Text.ElideRight
                            width: parent.width - 30
                        }
                    }
                }

                Row {
                    width: parent.width; height: 20
                    visible: (pdoData.entries || []).length > 0
                    Text { width: 22; text: ""; font.pixelSize: 9 }
                    Text { width: 58; text: "Entry"; color: ThemeManager.current.navIconDefault; font.pixelSize: 9; font.weight: Font.DemiBold; font.family: "微软雅黑" }
                    Text { width: parent.width - 22 - 58 - 32 - 32 - 52; text: "Name"; color: ThemeManager.current.navIconDefault; font.pixelSize: 9; font.weight: Font.DemiBold; font.family: "微软雅黑" }
                    Text { width: 32; text: "Bits"; color: ThemeManager.current.navIconDefault; font.pixelSize: 9; font.weight: Font.DemiBold; font.family: "微软雅黑" }
                    Text { width: 32; text: "Offs"; color: ThemeManager.current.navIconDefault; font.pixelSize: 9; font.weight: Font.DemiBold; font.family: "微软雅黑" }
                    Text { width: 52; text: "Value"; color: ThemeManager.current.navIconDefault; font.pixelSize: 9; font.weight: Font.DemiBold; font.family: "微软雅黑" }
                }

                Repeater {
                    model: pdoData.entries || []

                    Row {
                        width: sectionRoot.width; height: 24
                        property int entryIdx: index
                        property var entryData: modelData

                        CheckBox {
                            width: 22; height: 24
                            checked: entryData.enabled !== false
                            enabled: pdoEnabled && !pdoFixed
                            onToggled: SimEngine.setEntryEnabled(chainIdx, isRx, pdoIdx, entryIdx, checked)
                        }
                        Text {
                            width: 58; height: 24
                            text: (entryData.index || "") + ":" + (entryData.subIndex !== undefined ? entryData.subIndex : 0)
                            color: ThemeManager.current.textPrimary
                            font.pixelSize: 9; font.family: "Consolas"
                            verticalAlignment: Text.AlignVCenter
                        }
                        Text {
                            width: parent.width - 22 - 58 - 32 - 32 - 52
                            height: 24
                            text: entryData.name || ""
                            color: ThemeManager.current.textSecondary
                            font.pixelSize: 9; font.family: "微软雅黑"
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        Text {
                            width: 32; height: 24
                            text: entryData.bitLen !== undefined ? entryData.bitLen : ""
                            color: ThemeManager.current.textPrimary
                            font.pixelSize: 9; font.family: "微软雅黑"
                            verticalAlignment: Text.AlignVCenter
                        }
                        Text {
                            width: 32; height: 24
                            text: entryData.byteOffset !== undefined ? entryData.byteOffset : "—"
                            color: "#5294e2"
                            font.pixelSize: 9; font.family: "Consolas"
                            verticalAlignment: Text.AlignVCenter
                        }
                        TextField {
                            width: 52; height: 22
                            text: entryData.value !== undefined ? String(entryData.value) : "0"
                            color: ThemeManager.current.textPrimary
                            font.pixelSize: 9; font.family: "Consolas"
                            background: Rectangle {
                                color: ThemeManager.current.bgWindow
                                border.color: ThemeManager.current.navBorder; radius: 3
                            }
                            onEditingFinished: SimEngine.setEntryValue(chainIdx, isRx, pdoIdx, entryIdx, parseInt(text) || 0)
                        }
                    }
                }
            }
        }

        Text {
            visible: pdoList.length === 0
            text: "No PDO defined"
            color: ThemeManager.current.textMuted
            font.pixelSize: 10; font.family: "微软雅黑"
        }
    }
}
