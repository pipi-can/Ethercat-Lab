import QtQuick

import "../components"
/*
 * @brief: 自定义标题栏，替换系统默认标题栏。
 */
Rectangle {
    id: root

    signal openEsiClicked()

    color: ThemeManager.current.bgTitleBar
    height: 45
    // 占位——后续会添加窗口控制按钮、标题文字等内容

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
            color: ThemeManager.current.textMuted
            radius: 6
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            id: stateText
            text: qsTr("No file selected")
            color: ThemeManager.current.textMuted
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

    InputField {
        id: searchInput
        anchors {
            right: parent.right
            rightMargin: 20
            verticalCenter: parent.verticalCenter
        }
        width: 200
        height: 30
        placeholderText: qsTr("Search...")
        radius: 5
        iconSource: "qrc:/resources/TitleBar/search.svg"
        iconPosition: "left"
        iconSize: 16
        iconMargin: 8
        textColor: ThemeManager.current.textMuted
        textFocusColor: ThemeManager.current.accent
        iconColor: ThemeManager.current.textMuted
        iconFocusColor: ThemeManager.current.accent
    }
}
