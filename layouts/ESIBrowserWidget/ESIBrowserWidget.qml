import QtQuick
import "../components"
import "./BrowserTreeView"
import "./CenterInfoWidget"

/*
 * @brief: ESI 浏览器主控件。
 *         左右分栏：左侧 ESI 树面板 + 右侧详情面板。
 *         作为 StackView 的第 0 个页面，由导航栏切换。
 */
Rectangle {
    id: root
    color: ThemeManager.current.bgWindow

    // 转发给 main.qml 的文件操作
    signal fileOpenRequested()
    signal fileDropped(url fileUrl)

    // ── 左侧：ESI 树 ──────────────────────────────────────────
    BrowserTreeWidget {
        id: esiTree
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom
    }

    // ── 右侧：详情 ────────────────────────────────────────────
    CenterInfoWidget {
        id: centerInfo
        anchors.top: parent.top
        anchors.left: esiTree.right
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        onFileOpenRequested: root.fileOpenRequested()
        onFileDropped: function(url) { root.fileDropped(url) }
    }
}
