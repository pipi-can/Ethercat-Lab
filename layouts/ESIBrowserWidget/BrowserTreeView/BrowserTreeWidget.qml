import QtQuick
import QtQuick.Controls
import "../../components"

/*
 * @brief: ESI 浏览器左侧树形面板。
 *         参考原型 #tree-panel 实现，包含：
 *         - 顶部标题栏 "ESI EXPLORER" + 节点计数
 *         - 无文件时的空状态提示
 *         - 文件加载后的树形容器（预留）
 *         - 加载遮罩
 *         - 右侧拖拽调整宽度的手柄
 */
Rectangle {
    id: root

    // ── 公开接口 ────────────────────────────────────────────────
    property int minimumWidth: 240
    property int maximumWidth: 450
    property bool hasFile: false

    // ── 外观 ────────────────────────────────────────────────────
    width: 310
    color: ThemeManager.current.bgTitleBar       // 原型 --surface #1c1f26

    // 右侧边框
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 1
        color: ThemeManager.current.navBorder    // 原型 --border #2a2e36
    }

    // ════════════════════════════════════════════════════════════
    // 顶部标题栏
    // ════════════════════════════════════════════════════════════
    Rectangle {
        id: panelHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 38
        color: "transparent"

        // 底部分割线
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: ThemeManager.current.navBorder
        }

        // 标题
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "ESI EXPLORER"
            color: ThemeManager.current.textPrimary
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 0.5
            font.capitalization: Font.AllUppercase
            font.family: "微软雅黑"
        }

        // 节点计数（有文件时显示）
        Text {
            id: nodeCountBadge
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: hasFile ? "" : ""
            color: ThemeManager.current.navIconDefault   // 原型 --text-dim
            font.pixelSize: 10
            font.family: "微软雅黑"
        }
    }

    // ════════════════════════════════════════════════════════════
    // 空状态（无文件时）
    // ════════════════════════════════════════════════════════════
    Item {
        id: emptyState
        anchors.top: panelHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: !hasFile

        Column {
            anchors.centerIn: parent
            spacing: 12

            // 文件夹图标（40x40，低透明度）
            ColorImage {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 40
                height: 40
                source: "qrc:/resources/NavigatorBar/file.svg"
                sourceColor: ThemeManager.current.navIconDefault // #555c69
                opacity: 0.4
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Open an ESI file to start"
                color: ThemeManager.current.navIconDefault       // #555c69
                font.pixelSize: 12
                font.family: "微软雅黑"
            }
        }
    }

    // ════════════════════════════════════════════════════════════
    // 树形容器（有文件时显示，预留）
    // ════════════════════════════════════════════════════════════
    Item {
        id: treeContainer
        anchors.top: panelHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: hasFile
        clip: true

        // TODO: Phase 1 — 在此添加 TreeView / ListView 渲染 ESI 树
    }

    // ════════════════════════════════════════════════════════════
    // 加载遮罩
    // ════════════════════════════════════════════════════════════
    Rectangle {
        id: loadingOverlay
        anchors.top: panelHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: "#1c1f26"                    // 原型 rgba(28,31,38,0.9)
        opacity: 0.9
        visible: false

        Column {
            anchors.centerIn: parent
            spacing: 12

            // 旋转指示器（匹配原型 .spinner）
            Canvas {
                id: spinner
                anchors.horizontalCenter: parent.horizontalCenter
                width: 28
                height: 28

                RotationAnimation on rotation {
                    running: loadingOverlay.visible
                    from: 0
                    to: 360
                    duration: 700
                    loops: Animation.Infinite
                }

                onPaint: {
                    var ctx = getContext("2d")
                    var cx = width / 2
                    var cy = height / 2
                    var r = width / 2 - 2

                    ctx.clearRect(0, 0, width, height)
                    ctx.lineCap = "round"

                    // 底圈（dim）
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                    ctx.strokeStyle = "#2a2e36"
                    ctx.lineWidth = 3
                    ctx.stroke()

                    // 强调弧（accent，占 3/4 圈）
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, -Math.PI / 2, Math.PI)
                    ctx.strokeStyle = ThemeManager.current.accent
                    ctx.lineWidth = 3
                    ctx.stroke()
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Parsing..."
                color: ThemeManager.current.textSecondary
                font.pixelSize: 11
                font.family: "微软雅黑"
            }
        }
    }

    // ════════════════════════════════════════════════════════════
    // 右侧拖拽手柄（调整面板宽度）
    // ════════════════════════════════════════════════════════════
    MouseArea {
        id: resizeHandle
        anchors.right: parent.right
        anchors.rightMargin: -3           // 居中于右边缘外侧
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 8                          // 略宽于视觉，方便抓取
        cursorShape: Qt.SplitHCursor

        // 视觉指示条
        Rectangle {
            anchors.centerIn: parent
            width: 4
            height: parent.height
            color: resizeHandle.containsMouse
                   ? ThemeManager.current.accent    // 原型 hover 效果
                   : "transparent"
        }

        // 拖拽状态
        property real startX: 0
        property real startWidth: 0

        onPressed: function(mouse) {
            startX = mouse.x
            startWidth = root.width
        }
        onPositionChanged: function(mouse) {
            var newWidth = startWidth + (mouse.x - startX)
            root.width = Math.max(root.minimumWidth,
                                  Math.min(root.maximumWidth, newWidth))
        }
    }

    // ── 公开方法 ────────────────────────────────────────────────
    /*
     * @brief: 显示加载状态。
     */
    function showLoading() {
        loadingOverlay.visible = true
    }

    /*
     * @brief: 隐藏加载状态。
     */
    function hideLoading() {
        loadingOverlay.visible = false
    }

    /*
     * @brief: 设置节点计数 badge。
     */
    function setNodeCount(count) {
        nodeCountBadge.text = count > 0 ? count + " nodes" : ""
    }
}
