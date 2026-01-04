import QtQuick
import QtQuick.Controls.Material

Item {
    width: buttonWidth
    height: buttonHeight

    property real buttonWidth : 200
    property real buttonHeight : 50
    property bool isSelected: false
    property bool isMousePressed: false  // 核心状态变量
    property bool buttonEnable: true        // 按钮是否启用

    // 颜色属性（增加禁用状态颜色）
    property string normalColor: "#ffffff"
    property string hoverColor: "#f0f8ff"
    property string pressedColor: "#e0e0e0"
    property string selectedColor: "#FFFACD"
    property string selectedBorderColor: "#FFD700"
    // 新增：禁用状态颜色
    property string disabledColor: "#f0f0f0"
    property string disabledBorderColor: "#cccccc"
    property string disabledTextColor: "#999999"

    property string normalBorderColor: "#bdc3c7"
    property string hoverBorderColor: "#2980b9"  // 更深的蓝色边框
    property string pressedBorderColor: "#3498db"

    property real contentText_Fontsize: 30
    property string contentText_Data: "按钮文本"
    property string contentText_Color: "#2c3e50"
    property bool contentText_Bold: false

    property real contentRectangle_BorderWidth: 3
    property real borderRadius: 5

    signal buttonClicked()
    signal buttonPressed()    // PLC置1
    signal buttonReleased()   // PLC置0
    signal buttonPressedAndHold()

    // 鼠标事件处理（确保悬浮状态被正确检测）
    MouseArea {
        id: mainMouseArea
        anchors.fill: parent
        propagateComposedEvents: false
        acceptedButtons: Qt.AllButtons
        // 确保鼠标进入/离开时能被检测到
        hoverEnabled: true  // 显式启用悬浮检测（关键修复）
        // 关键：根据buttonEnable控制鼠标区域是否可用
        enabled: buttonEnable

        // // 调试用：验证悬浮状态是否正确（实际使用可删除）
        // onContainsMouseChanged: {
        //     console.log("悬浮状态变化:", containsMouse)
        // }

        // 按下触发置1
        onPressed: {
            isMousePressed = true
            buttonPressed()
        }

        // 释放触发置0（无论位置）
        onReleased: {
            if (isMousePressed) {
                isMousePressed = false
                buttonReleased()
            }
        }

        // 鼠标移出且按下：强制置0
        onExited: {
            if (isMousePressed) {
                isMousePressed = false
                buttonReleased()
            }
        }

        // 点击事件
        onClicked: {
            forceActiveFocus()
            buttonClicked()
        }

        // 长按事件
        onPressAndHold: buttonPressedAndHold()
    }

    // 视觉组件（根据启用状态变化）
    Rectangle {
        id: visualButton
        anchors.fill: parent
        radius: borderRadius
        border.width: contentRectangle_BorderWidth
        // 边框颜色：受buttonEnable控制
        border.color: !buttonEnable ? disabledBorderColor
                    : isSelected ? selectedBorderColor
                    : isMousePressed ? pressedBorderColor
                    : (mainMouseArea.containsMouse ? hoverBorderColor : normalBorderColor)
        // 背景颜色：受buttonEnable控制
        color: !buttonEnable ? disabledColor
                : isSelected ? selectedColor
                : isMousePressed ? pressedColor
                : (mainMouseArea.containsMouse ? hoverColor : normalColor)

        // 按钮文本（颜色受buttonEnable控制）
        Text {
            anchors.centerIn: parent
            text: qsTr(contentText_Data)
            font.pixelSize: contentText_Fontsize
            font.bold: contentText_Bold
            // 文本颜色：禁用时变灰
            color: !buttonEnable ? disabledTextColor : contentText_Color
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
