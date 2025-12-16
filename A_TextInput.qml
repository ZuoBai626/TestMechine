import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Item {
    id: styledInput
    width: inputWidth
    height: inputHeight

    // 基本尺寸属性
    property real inputWidth: 200
    property real inputHeight: 50

    // 核心功能属性
    property string text: ""  // 实际存储的文本
    property bool isEditing: false     // 编辑状态切换
    property bool isSelected: false    // 选中状态
    property bool isPassword: false    // 密码模式开关（仅控制是否启用密码模式）

    // 样式属性（与按钮保持一致）
    property string normalColor: "#ffffff"
    property string hoverColor: "#ffffff"
    property string pressedColor: "#f0f8ff"
    property string selectedColor: "#FFFACD"
    property string selectedBorderColor: "#FFD700"

    property string normalBorderColor: "#bdc3c7"
    property string hoverBorderColor: "#3498db"
    property string pressedBorderColor: "#3498db"
    property string editingBorderColor: "#3498db"

    // 字体样式
    property real fontPixelSize: 35
    property string fontColor: "#2c3e50"
    property bool fontBold: false

    // 布局样式
    property real borderWidth: 3
    property real borderRadius: 5
    property real innerPadding: 10  // 统一内边距

    // 密码模式相关属性（仅保留基础掩码设置）
    property string passwordMask: "*"  // 密码遮盖字符

    // 功能信号
    signal valueChanged(string newValue)
    signal editingFinished(string finalValue)
    signal editCancelled()

    // 背景容器
    Rectangle {
        id: inputContainer
        anchors.fill: parent
        radius: borderRadius
        border.width: borderWidth
        border.color: isSelected ? selectedBorderColor
                    : isEditing ? editingBorderColor
                    : (hoverDetector.hovered ? hoverBorderColor : normalBorderColor)
        color: isSelected ? selectedColor
              : isEditing ? pressedColor
              : (hoverDetector.hovered ? hoverColor : normalColor)
    }

    // 悬停状态检测
    MouseArea {
        id: hoverDetector
        anchors.fill: parent
        hoverEnabled: true
        property bool hovered: false
        onEntered: hovered = true
        onExited: hovered = false
    }

    // 显示模式组件（密码始终以掩码显示）
    Text {
        id: displayText
        visible: !isEditing
        anchors.fill: parent
        // 密码模式下始终显示掩码，无切换功能
        text: isPassword && styledInput.text.length > 0
              ? passwordMask.repeat(styledInput.text.length)
              : styledInput.text || "点击输入"
        font.pixelSize: fontPixelSize
        font.bold: fontBold
        color: styledInput.text ? fontColor : "#bdc3c7"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        padding: innerPadding
        elide: Text.ElideMiddle
        maximumLineCount: 1

        MouseArea {
            anchors.fill: parent
            onClicked: {
                isEditing = true
                inputField.text = styledInput.text
                inputField.forceActiveFocus()
            }
        }
    }

    // 输入模式组件（密码始终隐藏）
    TextField {
        id: inputField
        visible: isEditing
        anchors.fill: parent
        text: styledInput.text
        font.pixelSize: fontPixelSize
        font.bold: fontBold
        color: fontColor
        padding: innerPadding
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        selectionColor: selectedColor
        selectedTextColor: fontColor

        // 密码模式下始终隐藏输入内容，无切换功能
        echoMode: isPassword ? TextInput.Password : TextInput.Normal

        background: Rectangle {
            color: "transparent"
            border.width: 0
        }

        Keys.onEnterPressed: confirmEdit()
        Keys.onReturnPressed: confirmEdit()
        Keys.onEscapePressed: cancelEdit()
        onEditingFinished: confirmEdit()
    }

    // 确认编辑
    function confirmEdit() {
        if (inputField.text !== styledInput.text) {
            styledInput.text = inputField.text;
            valueChanged(styledInput.text);
        }
        editingFinished(styledInput.text);
        isEditing = false;
    }

    // 取消编辑
    function cancelEdit() {
        inputField.text = styledInput.text;
        editCancelled();
        isEditing = false;
    }
}
