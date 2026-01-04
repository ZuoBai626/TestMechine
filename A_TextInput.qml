import QtQuick

Item {
    id: root
    width: inputWidth
    height: inputHeight
    clip: true

    // ==================== 属性 ====================
    property real inputWidth: 220
    property real inputHeight: 60

    property real plcValue: 0.0
    property int  decimals: 2
    property real minimumValue: -Infinity
    property real maximumValue: Infinity
    property bool allowNegative: true

    property bool isEditing: false

    // 样式属性
    property string normalColor: "#ffffff"
    property string hoverColor: "#ffffff"
    property string pressedColor: "#f0f8ff"
    property string normalBorderColor: "#bdc3c7"
    property string hoverBorderColor: "#3498db"
    property string editingBorderColor: "#3498db"

    property real fontPixelSize: 35
    property string fontColor: "#2c3e50"
    property bool fontBold: false

    property real borderWidth: 3
    property real borderRadius: 5
    property real innerPadding: 10

    signal userEditRequested(real newValue)
    signal editingCompleted(real finalValue)
    signal editingCanceled()

    // ==================== 背景 ====================
    Rectangle {
        id: container
        anchors.fill: parent
        radius: root.borderRadius
        border.width: root.borderWidth
        border.color: root.isEditing ? root.editingBorderColor
                    : (mouseArea.containsMouse ? root.hoverBorderColor : root.normalBorderColor)
        color: root.isEditing ? root.pressedColor
              : (mouseArea.containsMouse ? root.hoverColor : root.normalColor)
    }

    // ==================== 共享 FontMetrics ====================
    FontMetrics {
        id: sharedMetrics
        font.pixelSize: root.fontPixelSize
        font.bold: root.fontBold
    }

    // ==================== 显示文本 ====================
    Text {
        id: displayText
        width: root.width - 2 * (root.borderWidth + root.innerPadding)
        height: sharedMetrics.lineSpacing + 2 * root.innerPadding
        anchors.centerIn: parent

        opacity: root.isEditing ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 120 } }

        text: plcValue === 0 ? "点击设置" : Number(plcValue).toLocaleString(Qt.locale(), 'f', decimals)
        font: sharedMetrics.font
        color: plcValue !== 0 ? root.fontColor : "#bdc3c7"

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideMiddle
    }

    // ==================== 输入组件（TextInput） ====================
    TextInput {
        id: textInput
        width: root.width - 2 * (root.borderWidth + root.innerPadding)
        height: sharedMetrics.lineSpacing + 2 * root.innerPadding
        anchors.centerIn: parent

        // 始终存在于场景中，只用 opacity 控制视觉
        visible: true
        opacity: root.isEditing ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }

        font: sharedMetrics.font
        color: root.fontColor

        horizontalAlignment: Text.AlignHCenter

        selectionColor: "#FFFACD"
        selectedTextColor: "#2c3e50"

        validator: RegularExpressionValidator {
            regularExpression: root.allowNegative
                ? new RegExp("-?\\d*\\.?\\d{0," + root.decimals + "}")
                : new RegExp("\\d*\\.?\\d{0," + root.decimals + "}")
        }

        focus: true  // 允许获得焦点
        cursorVisible: root.isEditing

        Keys.onEnterPressed: root.confirmEdit()
        Keys.onReturnPressed: root.confirmEdit()
        Keys.onEscapePressed: root.cancelEdit()
        onActiveFocusChanged: if (!activeFocus && root.isEditing) root.confirmEdit()
    }

    // ==================== 父级 MouseArea：仅在非编辑状态下启用（负责首次点击激活） ====================
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: !root.isEditing  // 编辑时禁用悬停检测
        enabled: !root.isEditing       // 编辑时完全禁用，防止拦截事件

        onClicked: {
            root.isEditing = true
            // 延迟确保 opacity 已更新，再激活焦点
            Qt.callLater(function() {
                textInput.forceActiveFocus()
                textInput.text = plcValue.toFixed(decimals)
                textInput.cursorPosition = textInput.length
                textInput.selectAll()
            })
        }
    }

    // ==================== TextInput 专用 MouseArea：编辑状态下捕获点击（激活光标） ====================
    MouseArea {
        anchors.fill: textInput
        enabled: root.isEditing
        propagateComposedEvents: true
        onPressed: mouse => mouse.accepted = false
        onReleased: mouse => mouse.accepted = false
        onClicked: mouse => mouse.accepted = false
        onDoubleClicked: mouse => mouse.accepted = false
        onPressAndHold: mouse => mouse.accepted = false
    }

    // ==================== 确认与取消 ====================
    function confirmEdit() {
        if (!root.isEditing) return

        var inputText = textInput.text.trim()
        if (inputText === "" || inputText === "-" || inputText === ".") {
            inputText = "0"
        }

        var num = parseFloat(inputText)
        if (isNaN(num) || num < minimumValue || num > maximumValue || (!allowNegative && num < 0)) {
            textInput.text = plcValue.toFixed(decimals)
            root.cancelEdit()
            return
        }

        var newValue = Number(num.toFixed(decimals))
        if (Math.abs(newValue - plcValue) > 0.000001) {
            plcValue = newValue
            userEditRequested(newValue)
        }

        editingCompleted(newValue)
        root.isEditing = false
    }

    function cancelEdit() {
        textInput.text = plcValue.toFixed(decimals)
        editingCanceled()
        root.isEditing = false
    }
}
