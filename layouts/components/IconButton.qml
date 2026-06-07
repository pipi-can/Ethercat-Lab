import QtQuick

import "../components"

/*
 * @brief: 带图标的通用按钮组件。
 *         支持水平布局（图标左、文字右）和垂直布局（图标上、文字下）两种模式，
 *         提供放置/悬停/按下三种状态的背景色、图标色、文字色接口，
 *         通过 MouseArea 发出 hovered() / clicked() 信号。
 */
Rectangle {
    id: root

    /*
     * @brief: 布局方向。"horizontal" = 图标在左、文字在右；
     *                          "vertical"   = 图标在上、文字在下。
     */
    property string layoutMode: "horizontal"

    /*
     * @brief: 内容区域（icon + text）距离 Rectangle 边框的边距（像素）。
     */
    property int horizontalMargin: 8
    property int verticalMargin: 4

    property url iconSource: ""
    property real iconSize: 16
    property string buttonText: ""
    property int fontSize: 12
    property bool fontBold: false
    property string fontFamily: ""

    // ── 背景颜色 ────────────────────────────────────────────────────────
    property color bgPlaceColor: "#2a2a3a"
    property color bgHoverColor: "#3a3a4e"
    property color bgPressColor: "#1a1a2a"

    // ── 图标着色 ────────────────────────────────────────────────────────
    property color iconPlaceColor: "#c0c0c0"
    property color iconHoverColor: "#ffffff"
    property color iconPressColor: "#ffffff"

    // ── 文字颜色 ────────────────────────────────────────────────────────
    property color textPlaceColor: "#c0c0c0"
    property color textHoverColor: "#ffffff"
    property color textPressColor: "#ffffff"

    // ── 边框 ────────────────────────────────────────────────────────────
    property color borderPlaceColor: "transparent"
    property color borderHoverColor: "transparent"
    property color borderPressColor: "transparent"
    property int borderWidth: 0

    readonly property bool buttonHovered: mouseArea.containsMouse
    readonly property bool buttonPressed: mouseArea.pressed

    signal hovered()
    signal clicked()

    // ── 外观绑定 ────────────────────────────────────────────────────────
    color: buttonPressed ? bgPressColor
                         : (buttonHovered ? bgHoverColor : bgPlaceColor)

    border.color: buttonPressed ? borderPressColor
                                : (buttonHovered ? borderHoverColor : borderPlaceColor)
    border.width: borderWidth
    radius: 4

    // 隐式尺寸：供 Layout 自动计算使用
    implicitWidth: {
        if (layoutMode === "horizontal")
            return iconSize + label.implicitWidth + horizontalMargin * 2 + 4;
        else
            return Math.max(iconSize, label.implicitWidth) + horizontalMargin * 2;
    }
    implicitHeight: {
        if (layoutMode === "horizontal")
            return Math.max(iconSize, label.implicitHeight) + verticalMargin * 2;
        else
            return iconSize + label.implicitHeight + verticalMargin * 2 + 2;
    }

    // ── 内容容器 ────────────────────────────────────────────────────────
    Item {
        id: content
        anchors {
            fill: parent
            leftMargin: horizontalMargin
            rightMargin: horizontalMargin
            topMargin: verticalMargin
            bottomMargin: verticalMargin
        }

        /*
         * @brief: 使用 ColorImage 组件实现图标着色。
         *         ColorImage → ColorOverlay 将图标非透明区域替换为当前状态颜色。
         */
        ColorImage {
            id: icon
            source: iconSource
            width: iconSize
            height: iconSize
            fillMode: Image.PreserveAspectFit
            visible: iconSource.toString() !== ""
            sourceColor: buttonPressed ? iconPressColor
                                       : (buttonHovered ? iconHoverColor : iconPlaceColor)
        }

        Text {
            id: label
            text: buttonText
            font.pixelSize: fontSize
            font.bold: fontBold
            font.family: fontFamily
            color: buttonPressed ? textPressColor
                                 : (buttonHovered ? textHoverColor : textPlaceColor)
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
    }

    // ── 布局状态切换 ────────────────────────────────────────────────────
    states: [
        State {
            name: "horizontalLayout"
            when: layoutMode === "horizontal"

            AnchorChanges {
                target: icon
                anchors.left: content.left
                anchors.verticalCenter: content.verticalCenter
            }
            AnchorChanges {
                target: label
                anchors.left: icon.visible ? icon.right : content.left
                anchors.verticalCenter: content.verticalCenter
            }
            PropertyChanges {
                target: label
                anchors.leftMargin: icon.visible ? 4 : 0
            }
        },
        State {
            name: "verticalLayout"
            when: layoutMode === "vertical"

            AnchorChanges {
                target: icon
                anchors.top: content.top
                anchors.horizontalCenter: content.horizontalCenter
            }
            AnchorChanges {
                target: label
                anchors.top: icon.visible ? icon.bottom : content.top
                anchors.horizontalCenter: content.horizontalCenter
            }
            PropertyChanges {
                target: label
                anchors.leftMargin: 0
                anchors.topMargin: icon.visible ? 2 : 0
            }
        }
    ]

    // ── 鼠标交互 ────────────────────────────────────────────────────────
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: root.clicked()
        onEntered: root.hovered()
    }
}
