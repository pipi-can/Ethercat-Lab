import QtQuick
import QtQuick.Controls
import "../../components"

/*
 * @brief: ESI 浏览器中央详情区。
 *         参考原型 #center-panel，包含：
 *         - 面包屑导航条（选中节点后显示）
 *         - 欢迎页（无选中时）：Logo + 拖拽区 + 按钮
 *         - 详情视图（双击节点后显示）：Hero + 属性卡片 + Entry 表格
 */
Rectangle {
    id: root
    color: ThemeManager.current.bgWindow       // 原型 --bg #15181d

    // ── 公开接口 ────────────────────────────────────────────────
    property bool hasSelection: false
    property var nodeProperties: ({})
    property string nodeType: ""
    property string displayName: ""
    property string nodeDetail: ""

    // 请求打开文件对话框
    signal fileOpenRequested()
    // 拖拽放下文件（直接传递 URL）
    signal fileDropped(url fileUrl)

    // 供外部调用
    function showDetail(properties, ntype, dname, detail) {
        nodeProperties = properties || {}
        nodeType = ntype || ""
        displayName = dname || ""
        nodeDetail = detail || ""
        hasSelection = true
        breadcrumbPath = [dname || "Node"]
    }

    function clearSelection() {
        hasSelection = false
        nodeProperties = {}
        nodeType = ""
        displayName = ""
        nodeDetail = ""
    }

    // 面包屑路径
    property var breadcrumbPath: []

    // ════════════════════════════════════════════════════════════
    // 面包屑导航（匹配原型 #breadcrumb）
    // ════════════════════════════════════════════════════════════
    Rectangle {
        id: breadcrumb
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: hasSelection ? 32 : 0
        color: ThemeManager.current.bgTitleBar
        clip: true

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: ThemeManager.current.navBorder
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
                text: breadcrumbPath.join(" › ")
                color: ThemeManager.current.textPrimary
                font.pixelSize: 11
                font.family: "微软雅黑"
            }
        }
    }

    // ════════════════════════════════════════════════════════════
    // 欢迎页（匹配原型 #welcomeView）
    // ════════════════════════════════════════════════════════════
    Item {
        id: welcomeView
        anchors.top: breadcrumb.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: !hasSelection

        Column {
            anchors.centerIn: parent
            spacing: 24
            width: Math.min(parent.width - 48, 440)

            // ── Brand ──────────────────────────────────────────
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 70; height: 70
                    source: "qrc:/resources/MainApp/ethercat_icon.svg"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "EtherCAT Lab"
                    color: ThemeManager.current.textPrimary
                    font.pixelSize: 20
                    font.weight: Font.Bold
                    font.family: "微软雅黑"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "ESI File Browser & Visualization Tool"
                    color: ThemeManager.current.textSecondary
                    font.pixelSize: 12
                    font.family: "微软雅黑"
                }
            }

            // ── 拖拽区 ─────────────────────────────────────────
            Rectangle {
                id: dropZone
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: 180
                radius: 10

                readonly property bool highlighted: dropMouse.containsMouse
                                                    || fileDropArea.containsDrag
                color: highlighted
                       ? Qt.rgba(82 / 255, 148 / 255, 226 / 255, 0.08)
                       : "transparent"
                border.width: 2
                border.color: highlighted
                              ? ThemeManager.current.accent
                              : ThemeManager.current.navBorder

                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                Column {
                    anchors.centerIn: parent
                    spacing: 12

                    ColorImage {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 40; height: 40
                        source: "qrc:/resources/NavigatorBar/file.svg"
                        sourceColor: dropZone.highlighted
                                     ? ThemeManager.current.accent
                                     : ThemeManager.current.navIconDefault

                        Behavior on sourceColor { ColorAnimation { duration: 200 } }
                    }

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: fileDropArea.containsDrag
                                  ? "Drop to load ESI file"
                                  : "Drag & drop ESI XML file here"
                            color: ThemeManager.current.textSecondary
                            font.pixelSize: 13
                            font.family: "微软雅黑"
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "or click to browse"
                            color: ThemeManager.current.navIconDefault
                            font.pixelSize: 11
                            font.family: "微软雅黑"
                        }
                    }
                }

                // 拖放文件
                DropArea {
                    id: fileDropArea
                    anchors.fill: parent
                    onDropped: function(drop) {
                        if (drop.hasUrls) {
                            var url = drop.urls[0]
                            root.fileDropped(url)
                        }
                    }
                }

                // 点击打开文件对话框
                MouseArea {
                    id: dropMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.fileOpenRequested()
                }
            }

            // ── 按钮行 ─────────────────────────────────────────
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                // "Browse Files" 主按钮
                Rectangle {
                    id: browseBtn
                    width: browseLabel.implicitWidth + 44
                    height: 34
                    radius: 4
                    color: browseMouse.containsMouse
                           ? "#6aa3e8"
                           : ThemeManager.current.accent

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        id: browseLabel
                        anchors.centerIn: parent
                        text: "Browse Files"
                        color: "#ffffff"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        font.family: "微软雅黑"
                    }

                    MouseArea {
                        id: browseMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.fileOpenRequested()
                    }
                }

                // "Load Example" 次按钮
                Rectangle {
                    id: exampleBtn
                    width: exampleLabel.implicitWidth + 44
                    height: 34
                    radius: 4
                    color: exampleMouse.containsMouse
                           ? ThemeManager.current.navBgHover
                           : ThemeManager.current.bgTitleBar
                    border.width: 1
                    border.color: ThemeManager.current.navBorder

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        id: exampleLabel
                        anchors.centerIn: parent
                        text: "Load Example"
                        color: exampleMouse.containsMouse
                               ? ThemeManager.current.textPrimary
                               : ThemeManager.current.textSecondary
                        font.pixelSize: 12
                        font.family: "微软雅黑"
                    }

                    MouseArea {
                        id: exampleMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        // TODO: 加载内置示例 ESI 文件
                    }
                }
            }

            // ── 快捷键提示 ──────────────────────────────────────
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4

                KbdLabel { text: "Ctrl" }
                Text { text: "+"; color: ThemeManager.current.navIconDefault; font.pixelSize: 11; font.family: "微软雅黑" }
                KbdLabel { text: "O" }
                Text { text: " open  ·  "; color: ThemeManager.current.navIconDefault; font.pixelSize: 11; font.family: "微软雅黑" }
                KbdLabel { text: "Ctrl" }
                Text { text: "+"; color: ThemeManager.current.navIconDefault; font.pixelSize: 11; font.family: "微软雅黑" }
                KbdLabel { text: "F" }
                Text { text: " search"; color: ThemeManager.current.navIconDefault; font.pixelSize: 11; font.family: "微软雅黑" }
            }
        }
    }

    // ════════════════════════════════════════════════════════════
    // 详情视图（双击节点后显示）
    // ════════════════════════════════════════════════════════════
    Flickable {
        id: detailView
        anchors.top: breadcrumb.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: hasSelection
        clip: true
        contentWidth: width
        contentHeight: detailContent.implicitHeight + 32
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: detailContent
            width: parent.width - 48
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16
            topPadding: 20

            // ── Hero 区（图标 + 名称 + 类型）──────────────────
            Row {
                id: detailHero
                spacing: 16

                // 图标
                Rectangle {
                    width: 60; height: 60
                    radius: 12
                    color: Qt.rgba(82 / 255, 148 / 255, 226 / 255, 0.08)
                    anchors.verticalCenter: parent.verticalCenter

                    ColorImage {
                        anchors.centerIn: parent
                        width: 28; height: 28
                        source: "qrc:/resources/tree-icons/entry.svg"
                        sourceColor: ThemeManager.current.accent
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        text: displayName
                        color: ThemeManager.current.textPrimary
                        font.pixelSize: 20
                        font.weight: Font.Bold
                        font.family: "微软雅黑"
                    }
                    Text {
                        text: nodeType !== "" ? nodeType.toUpperCase() : ""
                        color: ThemeManager.current.textSecondary
                        font.pixelSize: 13
                        font.family: "微软雅黑"
                    }
                }
            }

            // ── Properties 卡片 ────────────────────────────────
            Rectangle {
                id: propsCard
                width: parent.width
                height: propsCardContent.height + propsCardHeader.height + 1
                color: ThemeManager.current.bgTitleBar
                border.width: 1
                border.color: ThemeManager.current.navBorder
                radius: 10

                // 卡片标题
                Rectangle {
                    id: propsCardHeader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 34
                    color: Qt.rgba(1, 1, 1, 0.02)
                    radius: 10

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: ThemeManager.current.navBorder
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: "PROPERTIES"
                        color: ThemeManager.current.textSecondary
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.5
                        font.family: "微软雅黑"
                    }
                }

                // 属性行
                Column {
                    id: propsCardContent
                    anchors.top: propsCardHeader.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Repeater {
                        model: Object.keys(nodeProperties).filter(function(k) {
                            // 排除 entries / subItems（单独渲染成表格）
                            return k !== "entries" && k !== "subItems"
                        })

                        delegate: Rectangle {
                            width: propsCard.width
                            height: 30
                            color: "transparent"

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                height: 1
                                color: Qt.rgba(42 / 255, 46 / 255, 54 / 255, 0.4)
                            }

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8

                                Text {
                                    width: 130
                                    text: modelData || ""
                                    color: ThemeManager.current.textSecondary
                                    font.pixelSize: 11
                                    font.family: "微软雅黑"
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: {
                                        var v = nodeProperties[modelData]
                                        if (typeof v === "number") return v.toString()
                                        if (typeof v === "boolean") return v ? "Yes" : "No"
                                        return v !== undefined ? v.toString() : ""
                                    }
                                    color: ThemeManager.current.textPrimary
                                    font.pixelSize: 11
                                    font.family: "微软雅黑"
                                }
                            }
                        }
                    }
                }
            }

            // ── Entry 表格（PDO 的 entries）────────────────────
            Loader {
                id: entryTableLoader
                width: parent.width
                active: nodeProperties.entries !== undefined
                        && Array.isArray(nodeProperties.entries)
                        && nodeProperties.entries.length > 0

                sourceComponent: Rectangle {
                    width: entryTableLoader.width
                    height: entryTableHeader.height + entryColumn.height + 2
                    color: ThemeManager.current.bgTitleBar
                    border.width: 1
                    border.color: ThemeManager.current.navBorder
                    radius: 10

                    // 标题
                    Rectangle {
                        id: entryTableHeader
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 34
                        color: Qt.rgba(1, 1, 1, 0.02)
                        radius: 10

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: ThemeManager.current.navBorder
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: "ENTRIES (" + nodeProperties.entries.length + ")"
                            color: ThemeManager.current.textSecondary
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.5
                            font.family: "微软雅黑"
                        }
                    }

                    // 表头
                    Row {
                        anchors.top: entryTableHeader.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 26

                        Repeater {
                            model: ["Index", "Name", "Type", "Bits"]
                            delegate: Rectangle {
                                width: [110, 200, 90, 60][index]
                                height: 26
                                color: Qt.rgba(1, 1, 1, 0.02)

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData
                                    color: ThemeManager.current.navIconDefault
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.4
                                    font.family: "微软雅黑"
                                }
                            }
                        }
                    }

                    // 表体
                    Column {
                        id: entryColumn
                        anchors.top: entryTableHeader.bottom
                        anchors.topMargin: 26
                        anchors.left: parent.left
                        anchors.right: parent.right

                        Repeater {
                            model: nodeProperties.entries || []

                            delegate: Row {
                                width: parent ? parent.width : 0
                                height: 28

                                // Index
                                Rectangle {
                                    width: 110; height: 28
                                    color: "transparent"

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: (modelData.Index || "") + ":" + (modelData.SubIndex !== undefined ? modelData.SubIndex : "0")
                                        color: ThemeManager.current.accent
                                        font.pixelSize: 11
                                        font.family: "微软雅黑"
                                        elide: Text.ElideRight
                                    }
                                }

                                // Name
                                Rectangle {
                                    width: 200; height: 28
                                    color: "transparent"

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.Name || "Padding"
                                        color: ThemeManager.current.textPrimary
                                        font.pixelSize: 11
                                        font.family: "微软雅黑"
                                        elide: Text.ElideRight
                                    }
                                }

                                // Type
                                Rectangle {
                                    width: 90; height: 28
                                    color: "transparent"

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        width: typeEntryText.implicitWidth + 8
                                        height: 18
                                        radius: 2
                                        color: Qt.rgba(136 / 255, 144 / 255, 158 / 255, 0.12)

                                        Text {
                                            id: typeEntryText
                                            anchors.centerIn: parent
                                            text: modelData["Data Type"] || "—"
                                            color: ThemeManager.current.textSecondary
                                            font.pixelSize: 10
                                            font.family: "微软雅黑"
                                        }
                                    }
                                }

                                // Bits
                                Rectangle {
                                    width: 60; height: 28
                                    color: "transparent"

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: (modelData["Bit Length"] !== undefined ? modelData["Bit Length"] : "—") + " b"
                                        color: ThemeManager.current.navIconDefault
                                        font.pixelSize: 11
                                        font.family: "微软雅黑"
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── SubItems 表格（Dictionary Object 的 subItems）───
            Loader {
                id: subItemTableLoader
                width: parent.width
                active: nodeProperties.subItems !== undefined
                        && Array.isArray(nodeProperties.subItems)
                        && nodeProperties.subItems.length > 0

                sourceComponent: Rectangle {
                    width: subItemTableLoader.width
                    height: subTableHeader.height + subColumn.height + 2
                    color: ThemeManager.current.bgTitleBar
                    border.width: 1
                    border.color: ThemeManager.current.navBorder
                    radius: 10

                    Rectangle {
                        id: subTableHeader
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 34
                        color: Qt.rgba(1, 1, 1, 0.02)
                        radius: 10

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: ThemeManager.current.navBorder
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: "SUB ITEMS (" + nodeProperties.subItems.length + ")"
                            color: ThemeManager.current.textSecondary
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.5
                            font.family: "微软雅黑"
                        }
                    }

                    Row {
                        anchors.top: subTableHeader.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 26

                        Repeater {
                            model: ["SubIdx", "Name", "Type", "BitSize", "Offs", "Access"]
                            delegate: Rectangle {
                                width: [50, 140, 80, 55, 45, 50][index]
                                height: 26
                                color: Qt.rgba(1, 1, 1, 0.02)

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData
                                    color: ThemeManager.current.navIconDefault
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                    font.family: "微软雅黑"
                                }
                            }
                        }
                    }

                    Column {
                        id: subColumn
                        anchors.top: subTableHeader.bottom
                        anchors.topMargin: 26
                        anchors.left: parent.left
                        anchors.right: parent.right

                        Repeater {
                            model: nodeProperties.subItems || []

                            delegate: Row {
                                width: parent ? parent.width : 0
                                height: 26

                                Rectangle {
                                    width: 50; height: 26
                                    color: "transparent"
                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.SubIndex !== undefined ? modelData.SubIndex : "—"
                                        color: ThemeManager.current.textPrimary
                                        font.pixelSize: 11
                                        font.family: "微软雅黑"
                                    }
                                }
                                Rectangle {
                                    width: 140; height: 26
                                    color: "transparent"
                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.Name || "—"
                                        color: ThemeManager.current.textPrimary
                                        font.pixelSize: 11
                                        font.family: "微软雅黑"
                                        elide: Text.ElideRight
                                    }
                                }
                                Rectangle {
                                    width: 80; height: 26
                                    color: "transparent"
                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.Type || "—"
                                        color: ThemeManager.current.accent
                                        font.pixelSize: 11
                                        font.family: "微软雅黑"
                                    }
                                }
                                Rectangle {
                                    width: 55; height: 26
                                    color: "transparent"
                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: (modelData["Bit Size"] !== undefined ? modelData["Bit Size"] : "—") + " b"
                                        color: ThemeManager.current.textSecondary
                                        font.pixelSize: 11
                                        font.family: "微软雅黑"
                                    }
                                }
                                Rectangle {
                                    width: 45; height: 26
                                    color: "transparent"
                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData["Bit Offset"] !== undefined ? modelData["Bit Offset"] : "0"
                                        color: ThemeManager.current.textSecondary
                                        font.pixelSize: 11
                                        font.family: "微软雅黑"
                                    }
                                }
                                Rectangle {
                                    width: 50; height: 26
                                    color: "transparent"
                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.Access || "—"
                                        color: ThemeManager.current.textSecondary
                                        font.pixelSize: 11
                                        font.family: "微软雅黑"
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 底部占位
            Item { width: 1; height: 24 }
        }
    }

    // ── 内联组件：键盘快捷键标签 ────────────────────────────────
    component KbdLabel: Rectangle {
        property string text: ""
        width: kbdText.implicitWidth + 10
        height: 20; radius: 3
        color: ThemeManager.current.bgWindow
        border.width: 1
        border.color: ThemeManager.current.navBorder

        Text {
            id: kbdText
            anchors.centerIn: parent
            text: parent.text
            color: ThemeManager.current.navIconDefault
            font.pixelSize: 10
            font.family: "微软雅黑"
        }
    }
}
