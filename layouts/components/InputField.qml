import QtQuick
import QtQuick.Controls
import "../components"
/*
 * @brief: 通用输入框组件。
 *         支持选中/未选中两种状态的背景色、文字色、光标色、边框色，
 *         可选左侧或右侧图标，图标点击发出 iconClicked() 信号。
 */
Rectangle {
    id: root

    // ── 图标 ────────────────────────────────────────────────────────────
    /*
     * @brief: 图标源路径。为空时不显示图标。
     */
    property url iconSource: ""

    /*
     * @brief: 图标位置。"left" = 靠左，"right" = 靠右。
     *         仅在 iconSource 非空时生效。
     */
    property string iconPosition: "left"

    /*
     * @brief: 图标距边框的边距（像素）。
     */
    property int iconMargin: 6

    /*
     * @brief: 图标显示尺寸（像素）。
     */
    property real iconSize: 16

    /*
     * @brief: 图标在各状态下的颜色。
     */
    property color iconColor: "#c0c0c0"
    property color iconFocusColor: "#ffffff"

    // ── 文字内容 ────────────────────────────────────────────────────────
    property alias text: textField.text
    property alias placeholderText: textField.placeholderText
    property alias font: textField.font

    // ── 颜色接口 ────────────────────────────────────────────────────────
    /*
     * @brief: 未选中 / 选中（获得焦点）状态下的各颜色。
     *         cursorColor / cursorFocusColor 控制光标（输入线）颜色。
     */
    property color bgColor: "#252540"
    property color bgFocusColor: "#2a2a4a"

    property color textColor: "#e0e0e0"
    property color textFocusColor: "#ffffff"

    property color cursorColor: "#1a8fc9"
    property color cursorFocusColor: "#1a8fc9"

    property color borderColor: "#3a3a52"
    property color borderFocusColor: "#1a8fc9"

    property color placeholderColor: "#555566"
    property color placeholderFocusColor: "#666677"

    // ── 边框 ────────────────────────────────────────────────────────────
    property int borderWidth: 1

    // ── 信号 ────────────────────────────────────────────────────────────
    signal iconClicked()

    // ── 内部状态 ────────────────────────────────────────────────────────
    readonly property bool hasIcon: iconSource.toString() !== "" && (iconPosition === "left" || iconPosition === "right")
    readonly property bool focused: textField.activeFocus

    // ── 外观 ────────────────────────────────────────────────────────────
    color: focused ? bgFocusColor : bgColor
    border.color: focused ? borderFocusColor : borderColor
    border.width: borderWidth
    radius: 4
    implicitHeight: textField.implicitHeight + 12
    implicitWidth: {
        var w = textField.implicitWidth + 16;
        if (hasIcon)
            w += iconSize + iconMargin;
        return w;
    }

    // ── 左侧图标 ────────────────────────────────────────────────────────
    ColorImage {
        id: leftIcon
        source: iconSource
        width: iconSize
        height: iconSize
        fillMode: Image.PreserveAspectFit
        sourceColor: focused ? iconFocusColor : iconColor
        visible: hasIcon && iconPosition === "left"

        anchors {
            left: root.left
            leftMargin: iconMargin
            verticalCenter: root.verticalCenter
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }

    // ── 右侧图标 ────────────────────────────────────────────────────────
    ColorImage {
        id: rightIcon
        source: iconSource
        width: iconSize
        height: iconSize
        fillMode: Image.PreserveAspectFit
        sourceColor: focused ? iconFocusColor : iconColor
        visible: hasIcon && iconPosition === "right"

        anchors {
            right: root.right
            rightMargin: iconMargin
            verticalCenter: root.verticalCenter
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }

    // ── 输入框 ──────────────────────────────────────────────────────────
    TextField {
        id: textField
        color: focused ? textFocusColor : textColor
        selectedTextColor: textFocusColor
        selectionColor: cursorColor

        // 光标（输入线）颜色
        cursorDelegate: Rectangle {
            width: 1
            color: focused ? cursorFocusColor : cursorColor
            visible: textField.activeFocus
        }

        /*
         * @brief: 根据图标位置调整 TextField 的锚点。
         *         图标在左 → TextField 左边界紧贴图标右侧；
         *         图标在右 → TextField 左边界紧贴 root 左侧；
         *         无图标   → TextField 填满 root。
         */
        anchors {
            left: (hasIcon && iconPosition === "left") ? leftIcon.right : root.left
            right: (hasIcon && iconPosition === "right") ? rightIcon.left : root.right
            leftMargin: (hasIcon && iconPosition === "left") ? 4 : 8
            rightMargin: (hasIcon && iconPosition === "right") ? 4 : 8
            verticalCenter: root.verticalCenter
        }

        // 去掉内置背景和边框，由外层 Rectangle 接管
        background: null

        // 占位符颜色
        placeholderTextColor: focused ? placeholderFocusColor : placeholderColor
    }
}
