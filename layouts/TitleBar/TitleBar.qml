import QtQuick

import "../components"
/*
 * @brief: 自定义标题栏，替换系统默认标题栏。
 */
Rectangle {
    id: root

    color: "#1C1F26"
    height: 45
    // 占位——后续会添加窗口控制按钮、标题文字等内容

    IconButton {
        id: openEsiBtn
        anchors {
            left: parent.left
            leftMargin: 20
            verticalCenter: parent.verticalCenter
        }
        height: 38
        iconSource: "qrc:/resources/TitleBar/file.svg"
        iconPlaceColor: "white"
        iconHoverColor: "white"
        iconPressColor: "white"

        bgPlaceColor: "#5294E2"
        bgHoverColor: Qt.lighter(bgPlaceColor, 1.2)
        bgPressColor: Qt.lighter(bgPlaceColor, 1.2)

        buttonText: qsTr("Open ESI")
        textPlaceColor: "white"
        textHoverColor: "white"
        textPressColor: "white"
        fontFamily: "微软雅黑"
        fontBold: true


    }

    Seprator {
        id: sep1
        color: "#282C34"
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
            color: "#8795B0"
            radius: 6
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            id: stateText
            text: qsTr("No file selected")
            color: "#8795B0"
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
        textColor: "#8795B0"
        textFocusColor: "#5294E2"
        iconColor: "#8795B0"
        iconFocusColor: "#5294E2"
    }
}
