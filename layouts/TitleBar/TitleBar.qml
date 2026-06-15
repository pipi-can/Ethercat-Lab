import QtQuick
import QtQuick.Controls

import "../components"

/*
 * @brief: 自定义标题栏。两态切换，由 main.qml 显式设置 state。
 *         state = "esi"      → Open ESI 按钮 + 文件状态 + 搜索框
 *         state = "simulate" → Run/Pause/Reset/Step + 仿真状态信息
 */
Rectangle {
    id: root

    // ── 公开接口 ────────────────────────────────────────────────
    signal openEsiClicked()
    signal searchRequested(string query)

    // 仿真页面控制信号
    signal simulateRun()
    signal simulatePause()
    signal simulateReset()
    signal simulateStep()

    // 当前状态由 main.qml 显式设置：appTitleBar.state = "esi" / "simulate"

    // ── ESI 状态属性 ────────────────────────────────────────────
    property bool hasLoadedFile: false
    property string currentFileName: ""
    property string currentFileInfo: ""

    // ── 仿真状态属性 ────────────────────────────────────────────
    property bool simHasSlaves: false
    property int simSlaveCount: 0
    property int simFrameCount: 0
    property string simState: "OP"
    property string simCycleTime: "1000 μs"

    function focusSearch() {
        if (searchInput.visible) searchInput.forceActiveFocus()
    }

    color: ThemeManager.current.bgTitleBar
    height: 45

    // ════════════════════════════════════════════════════════════
    // ESI 浏览器态：Open ESI + 文件状态 + 搜索
    // ════════════════════════════════════════════════════════════
    IconButton {
        id: openEsiBtn
        anchors {
            left: parent.left
            leftMargin: 20
            verticalCenter: parent.verticalCenter
        }
        height: 34
        iconSource: "qrc:/resources/TitleBar/file.svg"
        iconPlaceColor: ThemeManager.current.textPrimary
        iconHoverColor: ThemeManager.current.textPrimary
        iconPressColor: ThemeManager.current.textPrimary

        bgPlaceColor: ThemeManager.current.accent
        bgHoverColor: Qt.lighter(ThemeManager.current.accent, 1.2)
        bgPressColor: Qt.lighter(ThemeManager.current.accent, 1.2)

        buttonText: qsTr("Open ESI")
        textPlaceColor: ThemeManager.current.textPrimary
        textHoverColor: ThemeManager.current.textPrimary
        textPressColor: ThemeManager.current.textPrimary
        fontFamily: "微软雅黑"
        fontBold: true

        onClicked: root.openEsiClicked()
    }

    Seprator {
        id: sep1
        color: ThemeManager.current.bgSeparator
        anchors {
            left: openEsiBtn.right
            leftMargin: 10
            verticalCenter: parent.verticalCenter
        }
        width: 2
        height: 30
    }

    // 文件状态指示器
    Item {
        id: fileStateItem
        anchors {
            left: sep1.right
            leftMargin: 10
            verticalCenter: parent.verticalCenter
        }
        Rectangle {
            id: stateIndicator
            width: 10
            height: 10
            color: root.hasLoadedFile ? "#42a85f" : ThemeManager.current.textMuted
            radius: 6
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            id: stateText
            text: root.hasLoadedFile ? root.currentFileName : qsTr("No file selected")
            color: root.hasLoadedFile ? ThemeManager.current.textPrimary : ThemeManager.current.textMuted
            font.family: "微软雅黑"
            font.pixelSize: 12
            font.bold: false
            anchors {
                left: stateIndicator.right
                leftMargin: 5
                verticalCenter: parent.verticalCenter
            }
        }
    }

    // 搜索框（ESI 态可见）
    InputField {
        id: searchInput
        anchors {
            right: parent.right
            rightMargin: 20
            verticalCenter: parent.verticalCenter
        }
        width: 200
        height: 30
        placeholderText: qsTr("Search nodes... (Ctrl+F)")
        radius: 5
        iconSource: "qrc:/resources/TitleBar/search.svg"
        iconPosition: "left"
        iconSize: 16
        iconMargin: 8
        textColor: ThemeManager.current.textMuted
        textFocusColor: ThemeManager.current.accent
        iconColor: ThemeManager.current.textMuted
        iconFocusColor: ThemeManager.current.accent

        onTextChanged: root.searchRequested(text)
        onAccepted: root.searchRequested(text)
    }

    // ════════════════════════════════════════════════════════════
    // 仿真态：Run / Pause / Reset / Step + info
    // ════════════════════════════════════════════════════════════
    Row {
        id: simControls
        anchors {
            left: parent.left
            leftMargin: 20
            verticalCenter: parent.verticalCenter
        }
        spacing: 6
        visible: false

        // Run — start.svg · 绿色
        IconButton {
            iconSource: "qrc:/resources/SimulateWidget/start.svg"
            iconSize: 14
            buttonText: qsTr("Run")
            fontSize: 11
            fontBold: true
            fontFamily: "微软雅黑"

            bgPlaceColor: "#42a85f"
            bgHoverColor: "#5abe6f"
            bgPressColor: "#3a9554"

            iconPlaceColor: "#ffffff"
            iconHoverColor: "#ffffff"
            iconPressColor: "#ffffff"

            textPlaceColor: "#ffffff"
            textHoverColor: "#ffffff"
            textPressColor: "#ffffff"

            horizontalMargin: 10
            verticalMargin: 4

            onClicked: root.simulateRun()
        }

        // Pause — pause.svg · 橙色
        IconButton {
            iconSource: "qrc:/resources/SimulateWidget/pause.svg"
            iconSize: 14
            buttonText: qsTr("Pause")
            fontSize: 11
            fontBold: true
            fontFamily: "微软雅黑"

            bgPlaceColor: "#d4844a"
            bgHoverColor: "#e89a5c"
            bgPressColor: "#c0743a"

            iconPlaceColor: "#ffffff"
            iconHoverColor: "#ffffff"
            iconPressColor: "#ffffff"

            textPlaceColor: "#ffffff"
            textHoverColor: "#ffffff"
            textPressColor: "#ffffff"

            horizontalMargin: 10
            verticalMargin: 4

            onClicked: root.simulatePause()
        }

        // Reset — stop.svg · 暗色
        IconButton {
            iconSource: "qrc:/resources/SimulateWidget/stop.svg"
            iconSize: 14
            buttonText: qsTr("Reset")
            fontSize: 11
            fontFamily: "微软雅黑"

            bgPlaceColor: "#252830"
            bgHoverColor: "#3a3d45"
            bgPressColor: "#1a1d22"

            borderPlaceColor: ThemeManager.current.bgSeparator
            borderHoverColor: ThemeManager.current.bgSeparator
            borderPressColor: ThemeManager.current.bgSeparator
            borderWidth: 1

            iconPlaceColor: ThemeManager.current.textSecondary
            iconHoverColor: ThemeManager.current.textPrimary
            iconPressColor: ThemeManager.current.textPrimary

            textPlaceColor: ThemeManager.current.textSecondary
            textHoverColor: ThemeManager.current.textPrimary
            textPressColor: ThemeManager.current.textPrimary

            horizontalMargin: 10
            verticalMargin: 4

            onClicked: root.simulateReset()
        }

        Seprator {
            color: ThemeManager.current.bgSeparator
            width: 2
            height: 20
            anchors.verticalCenter: parent.verticalCenter
        }

        // Step — 暗色（无独立图标）
        IconButton {
            iconSource: ""
            iconSize: 0
            buttonText: qsTr("Step")
            fontSize: 11
            fontFamily: "微软雅黑"

            bgPlaceColor: "#252830"
            bgHoverColor: "#3a3d45"
            bgPressColor: "#1a1d22"

            borderPlaceColor: ThemeManager.current.bgSeparator
            borderHoverColor: ThemeManager.current.bgSeparator
            borderPressColor: ThemeManager.current.bgSeparator
            borderWidth: 1

            iconPlaceColor: "transparent"
            textPlaceColor: ThemeManager.current.textSecondary
            textHoverColor: ThemeManager.current.textPrimary
            textPressColor: ThemeManager.current.textPrimary

            horizontalMargin: 10
            verticalMargin: 4

            onClicked: root.simulateStep()
        }
    }

    // ════════════════════════════════════════════════════════════
    // 仿真状态信息（居中靠左）
    // ════════════════════════════════════════════════════════════
    Row {
        id: simInfoRow
        anchors {
            left: simControls.right
            leftMargin: 14
            verticalCenter: parent.verticalCenter
        }
        spacing: 14
        visible: false

        // State
        Item {
            height: 20
            width: stateInfoLabel.implicitWidth + 4
            Text {
                id: stateInfoLabel
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("State: ") + "<b style='color:#42a85f'>" + root.simState + "</b>"
                color: ThemeManager.current.textMuted
                font.pixelSize: 11
                font.family: "微软雅黑"
                textFormat: Text.StyledText
            }
        }

        // Cycle
        Text {
            text: qsTr("Cycle: ") + "<b>" + root.simCycleTime + "</b>"
            color: ThemeManager.current.textMuted
            font.pixelSize: 11
            font.family: "微软雅黑"
            textFormat: Text.StyledText
        }

        // Slave count
        Text {
            text: qsTr("Slaves: ") + "<b style='color:#5294e2'>" + root.simSlaveCount + "</b>"
            color: ThemeManager.current.textMuted
            font.pixelSize: 11
            font.family: "微软雅黑"
            textFormat: Text.StyledText
        }

        // Frame count
        Text {
            text: qsTr("Frame: ") + "<b style='color:#d4844a'>" + root.simFrameCount + "</b>"
            color: ThemeManager.current.textMuted
            font.pixelSize: 11
            font.family: "微软雅黑"
            textFormat: Text.StyledText
        }
    }

    // ════════════════════════════════════════════════════════════
    // 状态机
    // ════════════════════════════════════════════════════════════
    states: [
        State {
            name: "esi"
            PropertyChanges { target: openEsiBtn; visible: true }
            PropertyChanges { target: sep1; visible: true }
            PropertyChanges { target: fileStateItem; visible: true }
            PropertyChanges { target: searchInput; visible: true }
            PropertyChanges { target: simControls; visible: false }
            PropertyChanges { target: simInfoRow; visible: false }
        },
        State {
            name: "simulate"
            PropertyChanges { target: openEsiBtn; visible: false }
            PropertyChanges { target: sep1; visible: false }
            PropertyChanges { target: fileStateItem; visible: false }
            PropertyChanges { target: searchInput; visible: false }
            PropertyChanges { target: simControls; visible: true }
            PropertyChanges { target: simInfoRow; visible: true }
        }
    ]
}
