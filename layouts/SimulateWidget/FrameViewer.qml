import QtQuick
import QtQuick.Controls
import "../components"

/*
 * @brief: 帧查看器 — 左侧字段列表，右侧 16 字节/行 hex；双击字段高亮对应字节。
 */
Rectangle {
    id: root
    color: "#1a1d24"
    border.color: ThemeManager.current.navBorder

    property alias frameHeight: root.height
    property var frameBytes: SimEngine.getLastFrameBytes()

    property int highlightOffset: -1
    property int highlightLength: 0

    readonly property int hexRowCount: frameBytes.length > 0
        ? Math.ceil(frameBytes.length / 16) : 0

    Connections {
        target: SimEngine
        function onLastFrameChanged() {
            root.frameBytes = SimEngine.getLastFrameBytes()
            root.highlightOffset = -1
            root.highlightLength = 0
        }
        function onFrameCountChanged() {
            root.frameBytes = SimEngine.getLastFrameBytes()
        }
    }

    function byteValue(index) {
        if (index < 0 || index >= frameBytes.length)
            return -1
        return frameBytes[index] & 0xFF
    }

    function isByteHighlighted(index) {
        if (highlightOffset < 0 || index < 0)
            return false
        return index >= highlightOffset && index < highlightOffset + highlightLength
    }

    function selectField(offset, length) {
        highlightOffset = offset
        highlightLength = Math.max(1, length)
        var row = Math.floor(offset / 16)
        if (row >= 0 && row < hexRowCount)
            hexList.positionViewAtIndex(row, ListView.Center)
    }

    Row {
        anchors.fill: parent
        spacing: 0

        // ── 左侧字段列表 ──────────────────────────────────────
        Rectangle {
            width: parent.width * 0.55
            height: parent.height
            color: "transparent"

            Column {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    width: parent.width; height: 28
                    color: Qt.rgba(255, 255, 255, 0.02)
                    border.color: ThemeManager.current.navBorder; border.width: 1

                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "FRAME STRUCTURE  ·  Cycle #" + SimEngine.frameCount
                        color: ThemeManager.current.textSecondary
                        font.pixelSize: 10; font.weight: Font.DemiBold; font.family: "微软雅黑"
                    }
                    Text {
                        anchors.right: parent.right; anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Double-click to highlight"
                        color: ThemeManager.current.textMuted
                        font.pixelSize: 9; font.family: "微软雅黑"
                    }
                }

                ListView {
                    id: fieldList
                    width: parent.width
                    height: parent.height - 28
                    clip: true
                    model: SimEngine.frameFields

                    delegate: Rectangle {
                        width: fieldList.width
                        height: 22

                        property int fieldOffset: modelData.offset !== undefined ? modelData.offset : -1
                        property int fieldLength: modelData.length !== undefined ? modelData.length : 1
                        property bool fieldSelected: root.highlightOffset === fieldOffset
                                                    && root.highlightLength === fieldLength

                        color: fieldSelected ? Qt.rgba(82/255, 148/255, 226/255, 0.18)
                             : mouseArea.containsMouse ? Qt.rgba(82/255, 148/255, 226/255, 0.06)
                             : "transparent"

                        Item {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8

                            Text {
                                id: offsetText
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 36
                                text: "0x" + fieldOffset.toString(16).toUpperCase().padStart(2, '0')
                                color: "#d4844a"
                                font.pixelSize: 9; font.family: "Consolas"
                            }

                            Rectangle {
                                id: dirBadge
                                anchors.left: offsetText.right
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 28; height: 14; radius: 2
                                color: modelData.dir === "rx" ? Qt.rgba(82/255,148/255,226/255,0.15)
                                     : modelData.dir === "tx" ? Qt.rgba(66/255,168/255,95/255,0.15)
                                     : Qt.rgba(255,255,255,0.05)
                                Text {
                                    anchors.centerIn: parent
                                    text: (modelData.dir || "hdr").toUpperCase()
                                    color: modelData.dir === "rx" ? "#5294e2"
                                         : modelData.dir === "tx" ? "#42a85f"
                                         : ThemeManager.current.textMuted
                                    font.pixelSize: 8; font.family: "微软雅黑"
                                }
                            }

                            Text {
                                id: descText
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.max(100, parent.width * 0.32)
                                text: modelData.desc || ""
                                color: ThemeManager.current.textMuted
                                font.pixelSize: 9; font.family: "微软雅黑"
                                horizontalAlignment: Text.AlignRight
                            }

                            Text {
                                anchors.left: dirBadge.right
                                anchors.leftMargin: 8
                                anchors.right: descText.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name || ""
                                color: ThemeManager.current.textPrimary
                                font.pixelSize: 9; font.family: "微软雅黑"
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onDoubleClicked: root.selectField(fieldOffset, fieldLength)
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Press Step to generate a frame"
                        color: ThemeManager.current.textMuted
                        font.pixelSize: 10; font.family: "微软雅黑"
                        visible: fieldList.count === 0
                    }
                }
            }
        }

        // ── 右侧 Hex：16 字节/行，双击左侧字段高亮 ─────────────
        Rectangle {
            width: parent.width * 0.45
            height: parent.height
            color: "#14171c"

            Column {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    width: parent.width; height: 28
                    color: Qt.rgba(255, 255, 255, 0.02)
                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "HEX  ·  " + root.frameBytes.length + " bytes"
                        color: ThemeManager.current.textSecondary
                        font.pixelSize: 10; font.weight: Font.DemiBold; font.family: "Consolas"
                    }
                }

                ListView {
                    id: hexList
                    width: parent.width
                    height: parent.height - 28
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.hexRowCount

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        contentItem: Rectangle { implicitWidth: 6; radius: 3; color: "#2a2e36" }
                    }

                    delegate: Row {
                        width: hexList.width
                        height: 22
                        spacing: 0
                        leftPadding: 10

                        property int rowStart: index * 16

                        // 行地址
                        Text {
                            width: 44
                            anchors.verticalCenter: parent.verticalCenter
                            text: rowStart.toString(16).toUpperCase().padStart(4, '0') + " "
                            color: "#555c69"
                            font.pixelSize: 10; font.family: "Consolas"
                        }

                        // 16 个字节
                        Repeater {
                            model: 16

                            Rectangle {
                                width: 23; height: 18
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 2

                                property int byteIndex: rowStart + index
                                property int byteVal: root.byteValue(byteIndex)
                                property bool lit: root.isByteHighlighted(byteIndex)

                                color: lit ? Qt.rgba(212/255, 132/255, 74/255, 0.35)
                                     : byteVal >= 0 && mouseArea.containsMouse
                                       ? Qt.rgba(255, 255, 255, 0.06) : "transparent"
                                border.width: lit ? 1 : 0
                                border.color: "#d4844a"

                                Text {
                                    anchors.centerIn: parent
                                    text: byteVal >= 0
                                          ? byteVal.toString(16).toUpperCase().padStart(2, '0')
                                          : "  "
                                    color: parent.lit ? "#ffd080" : "#88909e"
                                    font.pixelSize: 10; font.family: "Consolas"
                                }

                                MouseArea {
                                    id: mouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                            }
                        }

                        // ASCII
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            leftPadding: 8
                            text: {
                                var s = ""
                                for (var i = 0; i < 16; i++) {
                                    var v = root.byteValue(rowStart + i)
                                    if (v < 0) break
                                    s += (v >= 32 && v < 127) ? String.fromCharCode(v) : "."
                                }
                                return s
                            }
                            color: "#555c69"
                            font.pixelSize: 10; font.family: "Consolas"
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "—"
                        color: ThemeManager.current.textMuted
                        font.pixelSize: 10; font.family: "Consolas"
                        visible: hexList.count === 0
                    }
                }
            }
        }
    }
}
