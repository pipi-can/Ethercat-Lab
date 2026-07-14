import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import "./layouts/TitleBar"
import "./layouts/NavigationBar"
import "./layouts/ESIBrowserWidget"
import "./layouts/SimulateWidget"
import "./layouts/IOMapMonitorWidget"
import "./layouts/components"

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 1200
    height: 800
    minimumWidth: 960
    minimumHeight: 600
    title: "EtherCAT Lab"
    x: Screen.width / 2 - width / 2
    y: Screen.height / 2 - height / 2

    // ════════════════════════════════════════════════════════════
    // 标题栏 — 显式状态切换
    // ════════════════════════════════════════════════════════════
    TitleBar {
        id: appTitleBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        state: "esi"   // 初始状态

        onOpenEsiClicked: fileDialog.open()
        onSearchRequested: function(query) {
            if (esiPage.visible && esiPage) esiPage.searchAndReveal(query)
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
    // 导航栏 — 点击时切换页面 visible + TitleBar 状态
    // ════════════════════════════════════════════════════════════
    NavigatorBar {
        id: appNavBar
        anchors.top: titleBarSep.bottom
        anchors.left: parent.left
        anchors.bottom: parent.bottom

        onNavigationChanged: function(index, name) {
            esiPage.visible       = (index === 0)
            simulatePage.visible  = (index === 1)
            iomapPage.visible     = (index === 2)

            if (index === 0)
                appTitleBar.state = "esi"
            else if (index === 1)
                appTitleBar.state = "simulate"
            else
                appTitleBar.state = "iomap"
        }
    }

    // ════════════════════════════════════════════════════════════
    // 主内容区 — 所有页面预创建，通过 visible 切换
    // ════════════════════════════════════════════════════════════
    Item {
        id: contentArea
        anchors.top: titleBarSep.bottom
        anchors.left: appNavBar.right
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        // ── Page 0: ESI Browser（默认可见）──────────────────────
        ESIBrowserWidget {
            id: esiPage
            anchors.fill: parent
            visible: true

            onFileOpenRequested: fileDialog.open()
            onFileDropped: function(url) { loadEsiFile(url) }
        }

        // ── Page 1: Simulate（默认隐藏）─────────────────────────
        SimulateWidget {
            id: simulatePage
            anchors.fill: parent
            visible: false

            // 仿真状态变化 → 同步到 TitleBar
            onHasSlavesChanged: {
                appTitleBar.simHasSlaves = simulatePage.hasSlaves
                appTitleBar.simSlaveCount = simulatePage.slaveCount
            }
            onSimStateChanged:  appTitleBar.simState       = simulatePage.simState
            onSlaveCountChanged: appTitleBar.simSlaveCount  = simulatePage.slaveCount
            onFrameCountChanged: appTitleBar.simFrameCount  = simulatePage.frameCount
            onCycleTimeChanged:  appTitleBar.simCycleTime   = simulatePage.cycleTime
        }

        // ── Page 2: IOMap Monitor（默认隐藏）──────────────────────
        IOMapMonitorWidget {
            id: iomapPage
            anchors.fill: parent
            visible: false
        }
    }

    // ════════════════════════════════════════════════════════════
    // TitleBar 仿真按钮 → SimulateWidget
    // ════════════════════════════════════════════════════════════
    Connections {
        target: appTitleBar
        function onSimulateRun()   { simulatePage.runSimulation() }
        function onSimulatePause() { simulatePage.pauseSimulation() }
        function onSimulateReset() { simulatePage.resetSimulation() }
        function onSimulateStep()  { simulatePage.stepFrame() }
        function onIomapLoadDemo() { iomapPage.loadDemoPreset() }
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
        esiPage.esiTree.showLoading()
        var success = ESITreeModel.loadFile(path)
        esiPage.esiTree.hideLoading()
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
