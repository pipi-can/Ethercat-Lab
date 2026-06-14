import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import "./layouts/TitleBar"
import "./layouts/NavigationBar"
import "./layouts/ESIBrowserWidget"
import "./layouts/components"

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 1000
    height: 680
    minimumWidth: 960
    minimumHeight: 600
    title: "EtherCAT Lab"
    x: Screen.width / 2 - width / 2
    y: Screen.height / 2 - height / 2

    Item {
        id: controller
        states: [
            State { name: "no-file" },
            State { name: "file-selected" }
        ]
    }

    // ════════════════════════════════════════════════════════════
    // 标题栏
    // ════════════════════════════════════════════════════════════
    TitleBar {
        id: appTitleBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        onOpenEsiClicked: fileDialog.open()
        onSearchRequested: function(query) {
            var bw = pageManager.pages[0]
            if (bw) bw.searchAndReveal(query)
        }
    }

    Seprator {
        id: titleBarSep
        color: ThemeManager.current.bgSeparator
        anchors.top: appTitleBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 2
    }

    // ════════════════════════════════════════════════════════════
    // 导航栏
    // ════════════════════════════════════════════════════════════
    NavigatorBar {
        id: appNavBar
        anchors.top: titleBarSep.bottom
        anchors.left: parent.left
        anchors.bottom: parent.bottom

        onNavigationChanged: function(index, name) {
            if (index >= 0 && index < pageManager.pages.length
                    && mainStackView.currentItem !== pageManager.pages[index]) {
                mainStackView.replace(pageManager.pages[index], {},
                                      StackView.Immediate)
            }
        }
    }

    // ════════════════════════════════════════════════════════════
    // 主内容区 — StackView 页面切换
    // ════════════════════════════════════════════════════════════
    StackView {
        id: mainStackView
        anchors.top: titleBarSep.bottom
        anchors.left: appNavBar.right
        anchors.right: parent.right
        anchors.bottom: parent.bottom
    }

    // ── 页面管理器（预创建所有 page，切换时 preserve 状态）────────
    Item {
        id: pageManager
        property var pages: []

        Component.onCompleted: {
            pages = [
                esiPageComp.createObject(mainStackView),
                odPageComp.createObject(mainStackView),
                pdoPageComp.createObject(mainStackView)
            ]
            mainStackView.push(pages[0])
        }
    }

    // ── Page 0: ESI Browser ────────────────────────────────────
    Component {
        id: esiPageComp
        ESIBrowserWidget {
            onFileOpenRequested: fileDialog.open()
            onFileDropped: function(url) { loadEsiFile(url) }
        }
    }

    // ── Page 1: Object Dictionary（占位）───────────────────────
    Component {
        id: odPageComp
        Rectangle {
            color: ThemeManager.current.bgWindow

        }
    }

    // ── Page 2: PDO Mapping（占位）─────────────────────────────
    Component {
        id: pdoPageComp
        Rectangle {
            color: ThemeManager.current.bgWindow

        }
    }

    // ════════════════════════════════════════════════════════════
    // 文件对话框 — 仅 XML，单选
    // ════════════════════════════════════════════════════════════
    FileDialog {
        id: fileDialog
        title: "Open ESI File"
        nameFilters: ["ESI XML files (*.xml)"]
        fileMode: FileDialog.OpenFile
        onAccepted: loadEsiFile(selectedFile)
    }

    // 统一的 ESI 文件加载入口（FileDialog / 拖放 / 快捷键均走此函数）
    function loadEsiFile(fileUrl) {
        var path = fileUrl.toString()
        // 去掉 file:/// 前缀
        if (path.startsWith("file:///"))
            path = path.substring(8)
        // Windows: /C:/... → C:/...
        if (Qt.platform.os === "windows" && path.length > 2
                && path[0] === '/' && path[2] === ':')
            path = path.substring(1)

        var lower = path.toLowerCase()
        if (!lower.endsWith(".xml")) {
            console.log("Not an XML file, ignoring:", path)
            return
        }

        console.log("Loading ESI:", path)
        var browserWidget = pageManager.pages[0]
        browserWidget.esiTree.showLoading()
        var success = ESITreeModel.loadFile(path)
        browserWidget.esiTree.hideLoading()
        if (success) {
            // 更新标题栏文件状态
            var fileName = path.split("/").pop().split("\\").pop()
            appTitleBar.hasLoadedFile = true
            appTitleBar.currentFileName = fileName
            appTitleBar.currentFileInfo = ESITreeModel.fileCount + " file(s) loaded"
        } else {
            console.warn("Failed to load ESI file:", path)
        }
    }

    // ════════════════════════════════════════════════════════════
    // 快捷键
    // ════════════════════════════════════════════════════════════
    Shortcut {
        sequence: "Ctrl+O"
        onActivated: fileDialog.open()
    }
    Shortcut {
        sequence: "Ctrl+F"
        onActivated: appTitleBar.focusSearch()
    }
}
