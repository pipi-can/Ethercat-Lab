import QtQuick
import QtQuick.Controls
import "../../components"

/*
 * @brief: ESI 浏览器中央详情区。
 *         参考原型 #center-panel，包含：
 *         - 面包屑导航条（选中节点后显示）
 *         - 欢迎页（无文件/无选中时）：Logo + 拖拽区 + 按钮
 *         - 详情视图（选中节点后显示，预留）
 */
Rectangle {
    id: root
    color: ThemeManager.current.bgWindow       // 原型 --bg #15181d

    // ── 公开接口 ────────────────────────────────────────────────
    property bool hasSelection: false

    // 请求打开文件对话框
    signal fileOpenRequested()
    // 拖拽放下文件（直接传递 URL）
    signal fileDropped(url fileUrl)

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
                text: "Select a node…"
                color: ThemeManager.current.navIconDefault
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

            // ── 拖拽区（匹配原型 .drop-zone）─────────────────────
            Rectangle {
                id: dropZone
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: 180
                radius: 10

                // 统一 hover + dragover 状态
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

            // ── 按钮行（匹配原型 .open-btn-row）─────────────────
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
    // 详情视图（选中节点后，预留）
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
        contentHeight: detailContent.height
        boundsBehavior: Flickable.StopAtBounds

        Item {
            id: detailContent
            width: parent.width
            height: 200
            // TODO: Phase 1 — detail-hero + entry 表格 + prop-card
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
