import QtQuick
import QtQuick.Controls
import "../../components"

/*
 * @brief: ESI 浏览器左侧树形面板。
 *         参考原型 #tree-panel 实现，包含：
 *         - 顶部标题栏 "ESI EXPLORER" + 节点计数
 *         - 无文件时的空状态提示
 *         - 多文件 TreeView（图标 + 展开箭头 + 双击详情）
 *         - 加载遮罩
 *         - 右侧拖拽调整宽度的手柄
 */
Rectangle {
    id: root

    // ── 公开接口 ────────────────────────────────────────────────
    property int minimumWidth: 240
    property int maximumWidth: 450
    property bool hasFile: ESITreeModel.hasData

    // 当前选中节点（供 CenterInfoWidget 详情面板使用）
    property var selectedProperties: ({})
    property string selectedNodeType: ""
    property string selectedDisplayName: ""
    property string selectedDetail: ""
    property int selectedRow: -1
    signal nodeDoubleClicked(var properties, string nodeType, string displayName, string detail)

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

        // 文件计数（有文件时显示）
        Text {
            id: nodeCountBadge
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: hasFile ? ESITreeModel.fileCount + " file(s)" : ""
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
    // 树形容器（有文件时显示）
    // ════════════════════════════════════════════════════════════
    Item {
        id: treeContainer
        anchors.top: panelHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: hasFile
        clip: true

        TreeView {
            id: esiTreeView
            model: ESITreeModel
            anchors.fill: parent
            anchors.margins: 4
            clip: true
            // 禁用 rubber-band 拖拽回弹，只保留正常滚动
            boundsBehavior: Flickable.StopAtBounds

            // 右侧滚动条（透明背景 + 灰色半透明 handle）
            ScrollBar.vertical: ScrollBar {
                id: vBar
                policy: ScrollBar.AsNeeded
                width: 6

                background: Item {}

                contentItem: Rectangle {
                    implicitWidth: 4
                    implicitHeight: 20
                    radius: 2
                    color: vBar.pressed
                           ? Qt.rgba(136/255, 144/255, 158/255, 0.5)
                           : (vBar.hovered
                              ? Qt.rgba(136/255, 144/255, 158/255, 0.35)
                              : Qt.rgba(136/255, 144/255, 158/255, 0.18))
                }
            }

            delegate: Item {
                id: treeDelegate
                implicitWidth: esiTreeView.width - 8
                implicitHeight: 28

                required property bool hasChildren
                required property bool expanded
                required property int depth
                required property int row

                // 行背景（hover / selected）
                Rectangle {
                    anchors.fill: parent
                    color: row === root.selectedRow
                           ? ThemeManager.current.navBgHover
                           : "transparent"
                }

                // 缩进
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: depth * 16 + 8
                    color: "transparent"
                }

                // 展开/折叠箭头（大两个字号：10→12）
                Text {
                    id: arrow
                    anchors.left: parent.left
                    anchors.leftMargin: depth * 16 + 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    text: hasChildren ? (expanded ? "▾" : "▸") : ""
                    color: ThemeManager.current.textSecondary
                    font.pixelSize: 14
                    visible: hasChildren
                }

                // 节点图标（原型 .tree-icon + 彩色 iconColor）
                ColorImage {
                    id: nodeIcon
                    anchors.left: arrow.right
                    anchors.leftMargin: arrow.visible ? 4 : 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14
                    height: 14
                    source: model.iconSource ?? ""
                    sourceColor: model.iconColor ?? ThemeManager.current.textSecondary
                    visible: model.iconSource !== ""
                }

                // 节点名称
                Text {
                    anchors.left: nodeIcon.visible ? nodeIcon.right : (arrow.visible ? arrow.right : parent.left)
                    anchors.leftMargin: {
                        if (nodeIcon.visible) return 4
                        if (arrow.visible) return 4
                        return depth * 16 + 12
                    }
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    text: model.display ?? ""
                    color: ThemeManager.current.textPrimary
                    font.pixelSize: 12
                    font.family: "微软雅黑"
                    elide: Text.ElideRight
                }

                // 单击展开/折叠
                TapHandler {
                    onTapped: {
                        root.selectedRow = row
                        if (treeDelegate.hasChildren) {
                            esiTreeView.toggleExpanded(row)
                        }
                    }
                }

                // 双击 → 右侧详情面板
                TapHandler {
                    onDoubleTapped: {
                        root.selectedRow = row
                        var props = model.properties ?? {}
                        var ntype = model.nodeType ?? ""
                        var dname = model.display ?? ""
                        var detailStr = model.detail ?? ""
                        root.selectedProperties = props
                        root.selectedNodeType = ntype
                        root.selectedDisplayName = dname
                        root.selectedDetail = detailStr
                        root.nodeDoubleClicked(props, ntype, dname, detailStr)
                    }
                }
            }
        }
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
        anchors.rightMargin: -3
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 8
        cursorShape: Qt.SplitHCursor

        Rectangle {
            anchors.centerIn: parent
            width: 4
            height: parent.height
            color: resizeHandle.containsMouse
                   ? ThemeManager.current.accent
                   : "transparent"
        }

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
     * @brief: 搜索节点并跳转到匹配项。
     */
    function searchAndReveal(query) {
        if (!query || query.trim() === "") return

        var targetRow = ESITreeModel.findMatchRow(query.trim())
        if (targetRow < 0) return

        // 逐层展开直到目标行可见
        var maxIter = 50
        while (esiTreeView.rows <= targetRow && maxIter > 0) {
            maxIter--
            var didExpand = false
            for (var r = 0; r < esiTreeView.rows; r++) {
                if (!esiTreeView.isExpanded(r)) {
                    esiTreeView.expand(r)
                    didExpand = true
                }
            }
            if (!didExpand) break
        }

        // 定位到目标行
        if (targetRow < esiTreeView.rows) {
            esiTreeView.positionViewAtRow(targetRow, Qt.AlignCenter)
            root.selectedRow = targetRow
        }
    }
}
