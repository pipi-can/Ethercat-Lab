import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../components"

/*
 * @brief: 导航栏组件。
 *         左侧垂直导航栏，使用 ListView + ListModel 驱动，
 *         支持 hover 高亮、激活态指示条、右侧 Popup tooltip。
 */
Rectangle {
    id: root

    // ── 公开接口 ────────────────────────────────────────────────
    property alias currentIndex: navListView.currentIndex

    readonly property string currentName: {
        if (navListView.currentIndex >= 0
            && navListView.currentIndex < navModel.count)
            return navModel.get(navListView.currentIndex).name
        return ""
    }

    signal navigationChanged(int index, string name)

    // ── 外观 ────────────────────────────────────────────────────
    width: 50
    color: ThemeManager.current.bgNavRail

    // 右侧边框
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 1
        color: ThemeManager.current.navBorder
    }

    // ── Tooltip（单个 Popup，所有 delegate 共用）─────────────────
    Popup {
        id: navTooltip
        parent: Overlay.overlay   // 渲染到 overlay 层，不受 navBar 裁剪
        padding: 0
        closePolicy: Popup.NoAutoClose

        // 由 delegate 的 MouseArea 动态更新
        property real itemCenterY: 0   // hover 项在 root 坐标系中的 Y 中心
        property string itemText: ""

        // 位置：navBar 右侧 +4px 间隙
        x: {
            var p = root.mapToItem(null, root.width + 4, 0)
            return p.x
        }
        y: {
            var p = root.mapToItem(null, 0, itemCenterY - height / 2)
            return p.y
        }

        width: tooltipContent.implicitWidth + 20
        height: Math.max(tooltipContent.implicitHeight + 8, 26)

        background: Rectangle {
            color: ThemeManager.current.navTooltipBg
            radius: 4
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 2
                radius: 8
                samples: 9
                color: "#33000000"
            }
        }

        contentItem: Text {
            id: tooltipContent
            text: navTooltip.itemText
            color: ThemeManager.current.textPrimary
            font.pixelSize: 11
            font.family: "微软雅黑"
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter

        }
    }

    // 延迟关闭：防止在相邻按钮间移动鼠标时闪烁
    Timer {
        id: closeTimer
        interval: 80
        onTriggered: navTooltip.close()
    }

    // ── 数据模型 ────────────────────────────────────────────────
    ListModel {
        id: navModel

        ListElement {
            name: "ESI Browser"
            tooltip: "ESI Browser"
            iconSource: "qrc:/resources/NavigatorBar/file.svg"
            iconWidth: 22
            iconHeight: 22
        }
        ListElement {
            name: "Simulate"
            tooltip: "Simulate"
            iconSource: "qrc:/resources/NavigatorBar/simulate.svg"
            iconWidth: 18
            iconHeight: 18
        }
        ListElement {
            name: "PDO Observer"
            tooltip: "PDO Observer"
            iconSource: "qrc:/resources/NavigatorBar/iomap-monitor.svg"
            iconWidth: 20
            iconHeight: 20
        }
    }

    // ── 导航列表 ────────────────────────────────────────────────
    ListView {
        id: navListView
        anchors {
            fill: parent
            topMargin: 8
        }
        spacing: 2
        interactive: false
        currentIndex: 0
        model: navModel

        delegate: Item {
            id: delegateItem
            width: 50
            height: 44

            // ─── 按钮背景 ──────────────────────────────────────
            Rectangle {
                id: btnBg
                anchors.centerIn: parent
                width: 40
                height: 40
                radius: 6
                color: {
                    if (navListView.currentIndex === index)
                        return ThemeManager.current.navBgActive
                    if (mouseArea.containsMouse)
                        return ThemeManager.current.navBgHover
                    return "transparent"
                }

                // 激活态左侧指示条
                Rectangle {
                    visible: navListView.currentIndex === index
                    x: btnBg.x - 4
                    anchors.verticalCenter: btnBg.verticalCenter
                    width: 3
                    height: 20
                    color: ThemeManager.current.accent
                    radius: 2
                }

                // 图标
                ColorImage {
                    anchors.centerIn: parent
                    width: iconWidth
                    height: iconHeight
                    source: iconSource
                    sourceColor: {
                        if (navListView.currentIndex === index)
                            return ThemeManager.current.navIconActive
                        if (mouseArea.containsMouse)
                            return ThemeManager.current.navIconHover
                        return ThemeManager.current.navIconDefault
                    }
                }

                // 鼠标交互
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        navListView.currentIndex = index
                        root.navigationChanged(index, name)
                    }
                    onEntered: {
                        closeTimer.stop()
                        var pos = delegateItem.mapToItem(root, 0,
                                                          delegateItem.height / 2)
                        navTooltip.itemCenterY = pos.y
                        navTooltip.itemText = tooltip
                        navTooltip.open()
                    }
                    onExited: {
                        closeTimer.start()
                    }
                }
            }
        }
    }
}
