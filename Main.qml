import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
ApplicationWindow {
    width: rootWidth
    height: rootHeight
    visible: true
    title: qsTr("YJTest")
    visibility: "Windowed"    // 全屏显示应用程序

    x: Qt.application.screens[1].virtualX
    y: Qt.application.screens[1].virtualY + 30

    property real rootWidth : 1920
    property real rootHeight : 1010

    property int chart_force_time: 0
    property int chart_displacement_time: 1
    property int chart_displacement_force: 2
    property int currentChartIndex: chart_force_time
    property bool chartsReady: false

    Component.onCompleted: {
        // 🌟 关键：程序启动时，强制轴范围为 0-60
        chartRoot.resetAllAxisLimits();
        console.log("QML Component initialized, axis limits reset to 0-60s.");
    }


    // 2. 快捷访问 PLC 实时数据 Map
    readonly property var plcData: Cpp_ThreadManager.plcData

    Item{
        id: root
        anchors.fill: parent
    }

    Row{

        Button{
            width: 120
            height: 40
            text: "标 定"
            onClicked: systemParameter.visible = true
        }

    }

    // 数值显示部分
    Row{
        anchors.top: root.top
        anchors.topMargin: 45
        anchors.horizontalCenter: root.horizontalCenter

        spacing: 5

        Rectangle{
            width: 270
            height: 70
            border.width: 1

            Text{
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: 40
                width: 200
                height: 20
                text: "实验力 - 1(N)"
                font.pixelSize: 20
            }

            Text{
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.leftMargin: 20
                width: 200
                height: 50
                text: plcData["ExpForce1"].toFixed(3)
                font.pixelSize: 40
            }

            Button{
                anchors.right: parent.right
                anchors.top: parent.top
                width: 60
                height: 30
                text: "清 空"
                onClicked: console.log("触发清除")
            }

            Text{
                anchors.bottom: parent.bottom
                // anchors.bottomMargin: 5
                anchors.right: parent.right
                // anchors.rightMargin: 5
                width: 60
                height: 40
                font.pixelSize: 30
                text: "N"
            }

        }
        Rectangle{
            width: 270
            height: 70
            border.width: 1

            Text{
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: 40
                width: 200
                height: 20
                text: "实验力 - 2(N)"
                font.pixelSize: 20
            }

            Text{
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.leftMargin: 20
                width: 200
                height: 50
                text: plcData["ExpForce2"].toFixed(3)
                font.pixelSize: 40
            }

            Button{
                anchors.right: parent.right
                anchors.top: parent.top
                width: 60
                height: 30
                text: "清 空"
                onClicked: console.log("触发清除")
            }

            Text{
                anchors.bottom: parent.bottom
                // anchors.bottomMargin: 5
                anchors.right: parent.right
                // anchors.rightMargin: 5
                width: 60
                height: 40
                font.pixelSize: 30
                text: "N"
            }

        }
        Rectangle{
            width: 270
            height: 70
            border.width: 1

            Text{
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: 40
                width: 200
                height: 20
                text: "实验力 - 3(N)"
                font.pixelSize: 20
            }

            Text{
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.leftMargin: 20
                width: 200
                height: 50
                text: plcData["ExpForce3"].toFixed(3)
                font.pixelSize: 40
            }

            Button{
                anchors.right: parent.right
                anchors.top: parent.top
                width: 60
                height: 30
                text: "清 空"
                onClicked: console.log("触发清除")
            }

            Text{
                anchors.bottom: parent.bottom
                // anchors.bottomMargin: 5
                anchors.right: parent.right
                // anchors.rightMargin: 5
                width: 60
                height: 40
                font.pixelSize: 30
                text: "N"
            }

        }
        Rectangle{
            width: 270
            height: 70
            border.width: 1

            Text{
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: 40
                width: 200
                height: 20
                text: "位移量 - 1(mm)"
                font.pixelSize: 20
            }

            Text{
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.leftMargin: 20
                width: 200
                height: 50
                text: plcData["Displacement1"].toFixed(3)
                font.pixelSize: 40
            }

            Button{
                anchors.right: parent.right
                anchors.top: parent.top
                width: 60
                height: 30
                text: "清 空"
                onClicked: console.log("触发清除")
            }

            Text{
                anchors.bottom: parent.bottom
                // anchors.bottomMargin: 5
                anchors.right: parent.right
                // anchors.rightMargin: 5
                width: 60
                height: 40
                font.pixelSize: 30
                text: "mm"
            }

        }
        Rectangle{
            width: 270
            height: 70
            border.width: 1

            Text{
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: 40
                width: 200
                height: 20
                text: "位移量 - 2(mm)"
                font.pixelSize: 20
            }

            Text{
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.leftMargin: 20
                width: 200
                height: 50
                text: plcData["Displacement2"].toFixed(3)
                font.pixelSize: 40
            }

            Button{
                anchors.right: parent.right
                anchors.top: parent.top
                width: 60
                height: 30
                text: "清 空"
                onClicked: console.log("触发清除")
            }

            Text{
                anchors.bottom: parent.bottom
                // anchors.bottomMargin: 5
                anchors.right: parent.right
                // anchors.rightMargin: 5
                width: 60
                height: 40
                font.pixelSize: 30
                text: "mm"
            }

        }
        Rectangle{
            width: 270
            height: 70
            border.width: 1

            Text{
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: 40
                width: 200
                height: 20
                text: "位移量 - 3(mm)"
                font.pixelSize: 20
            }

            Text{
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.leftMargin: 20
                width: 200
                height: 50
                text: plcData["Displacement3"].toFixed(3)
                font.pixelSize: 40
            }

            Button{
                anchors.right: parent.right
                anchors.top: parent.top
                width: 60
                height: 30
                text: "清 空"
                onClicked: console.log("触发清除")
            }

            Text{
                anchors.bottom: parent.bottom
                // anchors.bottomMargin: 5
                anchors.right: parent.right
                // anchors.rightMargin: 5
                width: 60
                height: 40
                font.pixelSize: 30
                text: "mm"
            }

        }
        Rectangle{
            width: 270
            height: 70
            border.width: 1

            Text{
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: 20
                width: 200
                height: 20
                text: "实验时间 (s)"
                font.pixelSize: 20
            }

            Text{
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.leftMargin: 40
                width: 200
                height: 50
                text: plcData["timestampSeconds"].toFixed(2)
                font.pixelSize: 40
            }

            Button{
                anchors.right: parent.right
                anchors.top: parent.top
                width: 60
                height: 30
                text: "清 空"
                onClicked: console.log("触发清除")
            }

            Text{
                anchors.bottom: parent.bottom
                // anchors.bottomMargin: 5
                anchors.right: parent.right
                // anchors.rightMargin: 5
                width: 60
                height: 40
                font.pixelSize: 30
                text: "S"
            }

        }


    }



    SystemParameters{
        id: systemParameter
        anchors.centerIn: root
        z : 10
        visible: false
    }

    // 图表显示部分
    Item{
        id: chartRoot
        width: 1400
        height: 875
        anchors.left: root.left
        anchors.leftMargin: 5
        anchors.top: root.top
        anchors.topMargin: 125

        // 🌟 新增：用于绑定时间轴上下限的属性
        property real chartXMin: 0.0
        property real chartXMax: 30.0


        // 1. 定义选项卡模型
        TabBar {
            id: chartTabBar
            width: parent.width
            z: 1 // 确保在图表上方

            TabButton { text: "时间 / 实验力 (F-T)" }
            TabButton { text: "时间 / 位移量 (S-T)" }
            TabButton { text: "实验力 / 位移量 (F-S)" }
        }

        // 2. 使用 StackLayout 进行页面切换
        StackLayout {
            id: chartStack
            anchors.top: chartTabBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            currentIndex: chartTabBar.currentIndex

            // -------------------------------------------------
            // 图表 A: 时间 (X) - 实验力 (Y)
            // -------------------------------------------------
            ChartView {
                id: chartTimeForce
                title: "实时监控: 实验力随时间变化"
                antialiasing: true
                theme: ChartView.ChartThemeBlueCerulean

                ValueAxis { id: axisX_TF; min: chartRoot.chartXMin; max: chartRoot.chartXMax; titleText: "时间 (s)" ; tickCount: 5 }
                ValueAxis { id: axisY_TF; min: 0; max: 500; titleText: "实验力 (N)" }

                LineSeries { id: series_TF_1; name: "实验力 1"; axisX: axisX_TF; axisY: axisY_TF }
                LineSeries { id: series_TF_2; name: "实验力 2"; axisX: axisX_TF; axisY: axisY_TF }
                LineSeries { id: series_TF_3; name: "实验力 3"; axisX: axisX_TF; axisY: axisY_TF }
            }

            // -------------------------------------------------
            // 图表 B: 时间 (X) - 位移量 (Y)
            // -------------------------------------------------
            ChartView {
                id: chartTimeDisp
                title: "实时监控: 位移量随时间变化"
                antialiasing: true
                theme: ChartView.ChartThemeBrownSand

                ValueAxis { id: axisX_TD; min: chartRoot.chartXMin; max: chartRoot.chartXMax; titleText: "时间 (s)" ; tickCount: 5 }
                ValueAxis { id: axisY_TD; min: 0; max: 1000; titleText: "位移量 (mm)" }

                LineSeries { id: series_TD_1; name: "位移 1"; axisX: axisX_TD; axisY: axisY_TD }
                LineSeries { id: series_TD_2; name: "位移 2"; axisX: axisX_TD; axisY: axisY_TD }
                LineSeries { id: series_TD_3; name: "位移 3"; axisX: axisX_TD; axisY: axisY_TD }
            }

            // -------------------------------------------------
            // 图表 C: 位移量 (X) - 实验力 (Y)  (特性曲线)
            // -------------------------------------------------
            ChartView {
                id: chartDispForce
                title: "特性曲线: 实验力 vs 位移"
                antialiasing: true
                theme: ChartView.ChartThemeDark

                ValueAxis { id: axisX_DF; min: 0; max: 1000; titleText: "位移量 (mm)"  ; tickCount: 5}
                ValueAxis { id: axisY_DF; min: 0; max: 500; titleText: "实验力 (N)" }

                // 对应关系: 位移1 vs 力1
                LineSeries { id: series_DF_1; name: "CH1"; axisX: axisX_DF; axisY: axisY_DF }
                LineSeries { id: series_DF_2; name: "CH2"; axisX: axisX_DF; axisY: axisY_DF }
                LineSeries { id: series_DF_3; name: "CH3"; axisX: axisX_DF; axisY: axisY_DF }
            }
        }

        // 3. 核心逻辑: 监听 C++ 数据变化并刷新图表
        Connections {
            target: Cpp_ThreadManager

            // 监听 C++ 定义的 chartDataModelChanged 信号
            function onChartDataModelChanged() {
                chartRoot.updateVisibleChart();
            }
        }

        // 🌟 辅助函数: 增量更新 LineSeries
        function updateSeries(series, data, xKey, yKey) {
            // data 是最新数据点对象
            var xValue = data[xKey];
            var yValue = data[yKey];
            series.append(xValue, yValue);
        }

        // 4. JS 函数: 仅更新当前可见的图表
        function updateVisibleChart() {
            var dataList = Cpp_ThreadManager.chartDataModel;
            var fixedRange = 30; // 固定的显示窗口宽度

            if (!dataList || dataList.length === 0) {
                clearAllSeries();
                return;
            }

            // 1. 获取最新数据
            var latestData = dataList[dataList.length - 1];
            var currentTime = latestData.timestampSeconds;

            // ----------------------------------------------------
            // 2. 数据裁剪和 Series 同步移除 (仅在滚动阶段执行)
            // ----------------------------------------------------
            if (currentTime > fixedRange) {
                var timeThreshold = currentTime - fixedRange;

                // 循环移除所有时间戳小于 timeThreshold 的点
                while (dataList.length > 0 && dataList[0].timestampSeconds < timeThreshold) {

                    // 移除 QML 数据模型中的旧点
                    dataList.splice(0, 1);

                    // 必须同步移除 LineSeries 中的对应点 (时间轴曲线)
                    // 注意：只需处理当前Tab可能显示的时间曲线
                    if (chartTabBar.currentIndex === 0 || chartTabBar.currentIndex === 1) {
                        series_TF_1.remove(0); series_TF_2.remove(0); series_TF_3.remove(0);
                        series_TD_1.remove(0); series_TD_2.remove(0); series_TD_3.remove(0);
                    }
                    // 特性曲线（DF）不需要时间裁剪，其数据点不移除
                }
            }

            // ----------------------------------------------------
            // 3. 轴滚动/固定逻辑 (更新 chartXMin/Max 属性)
            // ----------------------------------------------------
            adjustAxisX(null, currentTime);

            // ----------------------------------------------------
            // 4. LineSeries 增量更新逻辑 (使用 switch 结构)
            // ----------------------------------------------------
            switch (chartTabBar.currentIndex) {
            case 0:
                // F-T 曲线 (X:时间, Y:力)
                updateSeries(series_TF_1, latestData, "timestampSeconds", "force1");
                updateSeries(series_TF_2, latestData, "timestampSeconds", "force2");
                updateSeries(series_TF_3, latestData, "timestampSeconds", "force3");
                break;

            case 1:
                // S-T 曲线 (X:时间, Y:位移)
                updateSeries(series_TD_1, latestData, "timestampSeconds", "disp1");
                updateSeries(series_TD_2, latestData, "timestampSeconds", "disp2");
                updateSeries(series_TD_3, latestData, "timestampSeconds", "disp3");
                break;

            case 2:
                // F-S 曲线 (X:位移, Y:力) - 特性曲线
                updateSeries(series_DF_1, latestData, "disp1", "force1");
                updateSeries(series_DF_2, latestData, "disp2", "force2");
                updateSeries(series_DF_3, latestData, "disp3", "force3");
                break;
            }
        }

        // 5. 通用工具函数: 将 C++ List 转换为 LineSeries 点
        function updateSeriesFromData(series, dataList, xKey, yKey) {
            series.clear();

            for (var i = 0; i < dataList.length; i++) {
                var item = dataList[i];
                var xValue = item[xKey];
                var yValue = item[yKey];
                series.append(xValue, yValue);
            }
        }

        // 🌟 关键修改: 工具函数: 自动滚动时间轴 (增强 $0-60$ 固定逻辑)
        function adjustAxisX(axis, currentTime) {
            var fixedRange = 30; // 固定的显示窗口宽度

            if (currentTime > fixedRange) {
                // 1. 滚动逻辑: 超过 30s，开始滚动
                // 直接更新 QML 属性，轴通过 Binding 自动更新
                chartRoot.chartXMax = currentTime;
                chartRoot.chartXMin = currentTime - fixedRange;

            } else {
                // 2. 强制固定逻辑: 0 <= currentTime <= 30s
                // 🌟 无条件强制设置 QML 属性，Binding 确保轴锁定 0-30，压制 Chart 内部调整。
                chartRoot.chartXMin = 0;
                chartRoot.chartXMax = fixedRange;
            }

            // 3. 复位逻辑 (保留)
            if (currentTime < 0) {
                chartRoot.chartXMin = 0;
                chartRoot.chartXMax = fixedRange;
            }
        }

        // 工具函数: 强制重置所有图表的轴上下限
        function resetAllAxisLimits() {
            // 🌟 关键修改: 重置 QML 属性，所有时间轴通过 Binding 自动更新
            chartRoot.chartXMin = 0;
            chartRoot.chartXMax = 30;

            // 确保其他轴的固定范围
            axisX_DF.min = 0; axisX_DF.max = 1000;
            axisY_TF.min = 0; axisY_TF.max = 500;
            axisY_TD.min = 0; axisY_TD.max = 1000;
            axisY_DF.min = 0; axisY_DF.max = 500;
        }

        // 工具函数: 清空所有曲线
        function clearAllSeries() {
            series_TF_1.clear(); series_TF_2.clear(); series_TF_3.clear();
            series_TD_1.clear(); series_TD_2.clear(); series_TD_3.clear();
            series_DF_1.clear(); series_DF_2.clear(); series_DF_3.clear();

            chartRoot.resetAllAxisLimits();
        }

    }


    Row{
        anchors.bottom: root.bottom
        anchors.bottomMargin: 5
        anchors.right: root.right
        anchors.rightMargin: 5
        width: 370
        height: 100
        spacing: 5

        Item{
            width: 120
            height: 100

            Button{
                width: 120
                height: 45
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                text: "上 移"
                onPressed: console.log("向上移动 - 按下")
                onReleased: console.log("向上移动 - 松开")
            }
            Button{
                width: 120
                height: 45
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                text: "下 移"
                onPressed: console.log("向下移动 - 按下")
                onReleased: console.log("向下移动 - 松开")
            }

        }

        Button{
            width: 120
            height: 90
            anchors.bottom: parent.bottom
            text: "开始实验"
            onClicked: {
                console.log("开始实验")

                // 🌟 关键：在 C++ 开始更新数据前，强制轴范围为 0-60
                chartRoot.resetAllAxisLimits(); // 使用一个新的、更稳定的函数

                Cpp_ThreadManager.start_Experiment()
            }
        }

        Button{
            width: 120
            height: 90
            anchors.bottom: parent.bottom
            text: "停止实验"
            onClicked: {
                console.log("停止实验")
                Cpp_ThreadManager.stop_Experiment()
            }
        }


    }

}



