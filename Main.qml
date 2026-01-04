import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
ApplicationWindow {
    width: rootWidth
    height: rootHeight
    visible: true
    title: qsTr("YJJC_Test")
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

    function saveChartView() {

        // 保持 Qt.callLater，以确保 ChartView 渲染稳定
        Qt.callLater(function() {
            console.log("调用 C++ 截图功能...");

            // 🌟 直接调用 C++ 函数
            var filePath = Cpp_ThreadManager.saveChartImage();

            if (filePath.length > 0) {
                console.log("图片保存成功:", filePath)
            } else {
                console.error("图片保存失败，请检查 C++ 端的输出。")
            }
        });
    }



    Item{
        id: root
        anchors.fill: parent
    }

    Row{

        Button{
            width: 120
            height: 40
            text: "设 置"
            font.pixelSize: 20
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
                text: plcData["ExpForce1"].toFixed(2)
                font.pixelSize: 40
            }

            Button{
                anchors.right: parent.right
                anchors.top: parent.top
                width: 60
                height: 30
                text: "清 空"
                onPressed: {
                    Cpp_ThreadManager.writeCoil("M1.4_端肋1_压力设零",9012,true)
                }
                onReleased: {
                    Cpp_ThreadManager.writeCoil("M1.4_端肋1_压力设零",9012,false)
                }
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
                text: plcData["ExpForce2"].toFixed(2)
                font.pixelSize: 40
            }

            Button{
                anchors.right: parent.right
                anchors.top: parent.top
                width: 60
                height: 30
                text: "清 空"
                onPressed: {
                    Cpp_ThreadManager.writeCoil("M1.5_中肋1_压力设零",9013,true)
                }
                onReleased: {
                    Cpp_ThreadManager.writeCoil("M1.5_中肋1_压力设零",9013,false)
                }
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
                text: plcData["ExpForce3"].toFixed(2)
                font.pixelSize: 40
            }

            Button{
                anchors.right: parent.right
                anchors.top: parent.top
                width: 60
                height: 30
                text: "清 空"
                onPressed: {
                    Cpp_ThreadManager.writeCoil("M1.6_端肋2_压力设零",9014,true)
                }
                onReleased: {
                    Cpp_ThreadManager.writeCoil("M1.6_端肋2_压力设零",9014,false)
                }
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
                text: plcData["Displacement1"].toFixed(2)
                font.pixelSize: 40
            }

            Button{
                anchors.right: parent.right
                anchors.top: parent.top
                width: 60
                height: 30
                text: "清 空"
                // onClicked: console.log("触发清除")
                onPressed: {
                    Cpp_ThreadManager.writeCoil("M1.0_端肋1_位置设零",9008,true)
                }
                onReleased: {
                    Cpp_ThreadManager.writeCoil("M1.0_端肋1_位置设零",9008,false)
                }
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
                text: plcData["Displacement2"].toFixed(2)
                font.pixelSize: 40
            }

            Button{
                anchors.right: parent.right
                anchors.top: parent.top
                width: 60
                height: 30
                text: "清 空"
                onPressed: {
                    Cpp_ThreadManager.writeCoil("M1.1_中肋1_位置设零",9009,true)
                }
                onReleased: {
                    Cpp_ThreadManager.writeCoil("M1.1_中肋1_位置设零",9009,false)
                }
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
                text: plcData["Displacement3"].toFixed(2)
                font.pixelSize: 40
            }

            Button{
                anchors.right: parent.right
                anchors.top: parent.top
                width: 60
                height: 30
                text: "清 空"
                onPressed: {
                    Cpp_ThreadManager.writeCoil("M1.2_端肋2_位置设零",9010,true)
                }
                onReleased: {
                    Cpp_ThreadManager.writeCoil("M1.2_端肋2_位置设零",9010,false)
                }
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

            // Button{
            //     anchors.right: parent.right
            //     anchors.top: parent.top
            //     width: 60
            //     height: 30
            //     text: "清 空"
            //     onClicked: console.log("触发清除")
            // }

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
        anchors.centerIn: parent
        z : 10
        visible: false
    }

    // 图表显示部分
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

            // ... (ChartViews 定义保持不变)

            // -------------------------------------------------
            // 图表 A: 时间 (X) - 实验力 (Y)
            // -------------------------------------------------
            ChartView {
                id: chartTimeForce
                title: "实时监控: 实验力随时间变化"
                antialiasing: true
                theme: ChartView.ChartThemeBlueCerulean

                ValueAxis { id: axisX_TF; min: chartRoot.chartXMin; max: chartRoot.chartXMax; titleText: "时间 (s)" ; tickCount: 9 }
                ValueAxis { id: axisY_TF; min: 0; max: 5000; titleText: "实验力 (N)" ; tickCount: 9}

                LineSeries { id: series_TF_1; name: "实验力 1"; axisX: axisX_TF; axisY: axisY_TF  }
                LineSeries { id: series_TF_2; name: "实验力 2"; axisX: axisX_TF; axisY: axisY_TF  }
                LineSeries { id: series_TF_3; name: "实验力 3"; axisX: axisX_TF; axisY: axisY_TF  }
            }

            // -------------------------------------------------
            // 图表 B: 时间 (X) - 位移量 (Y)
            // -------------------------------------------------
            ChartView {
                id: chartTimeDisp
                title: "实时监控: 位移量随时间变化"
                antialiasing: true
                theme: ChartView.ChartThemeBrownSand

                ValueAxis { id: axisX_TD; min: chartRoot.chartXMin; max: chartRoot.chartXMax; titleText: "时间 (s)" ; tickCount: 9 }
                ValueAxis { id: axisY_TD; min: 0; max: 1600; titleText: "位移量 (mm)" ; tickCount: 9 }

                LineSeries { id: series_TD_1; name: "位移 1"; axisX: axisX_TD; axisY: axisY_TD  }
                LineSeries { id: series_TD_2; name: "位移 2"; axisX: axisX_TD; axisY: axisY_TD  }
                LineSeries { id: series_TD_3; name: "位移 3"; axisX: axisX_TD; axisY: axisY_TD  }
            }

            // -------------------------------------------------
            // 图表 C: 位移量 (X) - 实验力 (Y)  (特性曲线)
            // -------------------------------------------------
            ChartView {
                id: chartDispForce
                title: "特性曲线: 实验力 vs 位移"
                antialiasing: true
                theme: ChartView.ChartThemeDark

                ValueAxis { id: axisX_DF; min: 0; max: 1600; titleText: "位移量 (mm)"  ; tickCount: 9}
                ValueAxis { id: axisY_DF; min: 0; max: 5100; titleText: "实验力 (N)"  ; tickCount: 9}

                // 对应关系: 位移1 vs 力1
                LineSeries { id: series_DF_1; name: "CH1"; axisX: axisX_DF; axisY: axisY_DF  }
                LineSeries { id: series_DF_2; name: "CH2"; axisX: axisX_DF; axisY: axisY_DF  }
                LineSeries { id: series_DF_3; name: "CH3"; axisX: axisX_DF; axisY: axisY_DF  }
            }
        }

        // 🌟 关键修改 1: 在组件完成时，连接 Tab 切换信号
        Component.onCompleted: {
            // 连接信号，Tab 切换时触发重绘逻辑
            chartTabBar.currentIndexChanged.connect(chartRoot.handleTabSwitch);
            // 初始调用，确保首次加载时轴和图表状态正确
            chartRoot.handleTabSwitch();
        }

        // 3. 核心逻辑: 监听 C++ 数据变化并刷新图表
        Connections {
            target: Cpp_ThreadManager

            // 监听 C++ 定义的 chartDataModelChanged 信号
            function onChartDataModelChanged() {
                chartRoot.updateVisibleChart();
            }
        }

        // 🌟 关键修改 2: Tab 切换处理函数 (负责清空并用历史数据重绘)
        function handleTabSwitch() {            
            // 使用 Qt.callLater 避免在 Layout 切换的同一帧内进行大量绘图操作，防止渲染崩溃
            Qt.callLater(function(){
                var dataList = Cpp_ThreadManager.chartDataModel;

                // 1. 先清空所有曲线 (防止残留)
                chartRoot.clearAllSeries();

                if (!dataList || dataList.length === 0) {
                    chartRoot.resetAllAxisLimits();
                    return;
                }

                // 2. 仅重绘当前选中的 Tab
                switch (chartTabBar.currentIndex) {
                case 0: // F-T 曲线
                    updateSeriesFromData(series_TF_1, dataList, "timestampSeconds", "force1");
                    updateSeriesFromData(series_TF_2, dataList, "timestampSeconds", "force2");
                    updateSeriesFromData(series_TF_3, dataList, "timestampSeconds", "force3");
                    break;

                case 1: // S-T 曲线
                    updateSeriesFromData(series_TD_1, dataList, "timestampSeconds", "disp1");
                    updateSeriesFromData(series_TD_2, dataList, "timestampSeconds", "disp2");
                    updateSeriesFromData(series_TD_3, dataList, "timestampSeconds", "disp3");
                    break;

                case 2: // F-S 曲线
                    updateSeriesFromData(series_DF_1, dataList, "disp1", "force1");
                    updateSeriesFromData(series_DF_2, dataList, "disp2", "force2");
                    updateSeriesFromData(series_DF_3, dataList, "disp3", "force3");
                    break;
                }

                // 3. 调整时间轴
                if (chartTabBar.currentIndex === 0 || chartTabBar.currentIndex === 1) {
                    var currentTime = dataList[dataList.length - 1].timestampSeconds;
                    adjustAxisX(null, currentTime);
                } else {
                    chartRoot.resetAllAxisLimits();
                }
            });

        }

        // 🌟 关键修改 3: 辅助函数: 增量更新 LineSeries (增加 NaN/Inf 检查)
        function updateSeries(series, data, xKey, yKey) {
            // data 是最新数据点对象
            var xValue = data[xKey];
            var yValue = data[yKey];

            // 🚨 修复 NaN/Inf 报错：只接受有限数值
            if (isFinite(xValue) && isFinite(yValue)) {
                series.append(xValue, yValue);
            } else {
                console.warn("Skipping invalid point for series " + series.name + ": X=" + xValue + ", Y=" + yValue);
            }
        }

        // 4. JS 函数: 仅更新当前可见的图表
        function updateVisibleChart() {

            var dataList = Cpp_ThreadManager.chartDataModel;
            // var fixedRange = 30; // 不需要在这里定义，adjustAxisX 会处理

            if (!dataList || dataList.length === 0) {
                // 如果没有数据，不要调用 clear，否则可能死循环或闪烁，直接返回即可
                return;
            }

            // 1. 获取最新数据
            var latestData = dataList[dataList.length - 1];
            var currentTime = latestData.timestampSeconds;
            var targetLength = dataList.length;

            // 2. 轴滚动逻辑
            adjustAxisX(null, currentTime);

            // 3. 分情况处理：裁剪旧数据 + 添加新数据
            // 🌟 核心修复：只对当前 Tab 的 Series 进行 remove 和 append
            switch (chartTabBar.currentIndex) {
            case 0: // F-T 曲线
                // 裁剪：确保 QML 曲线长度不大于 C++ 数据长度
                while (series_TF_1.count >= targetLength && series_TF_1.count > 0) {
                    series_TF_1.remove(0); series_TF_2.remove(0); series_TF_3.remove(0);
                }
                // 添加
                updateSeries(series_TF_1, latestData, "timestampSeconds", "force1");
                updateSeries(series_TF_2, latestData, "timestampSeconds", "force2");
                updateSeries(series_TF_3, latestData, "timestampSeconds", "force3");
                break;

            case 1: // S-T 曲线
                // 裁剪
                while (series_TD_1.count >= targetLength && series_TD_1.count > 0) {
                    series_TD_1.remove(0); series_TD_2.remove(0); series_TD_3.remove(0);
                }
                // 添加
                updateSeries(series_TD_1, latestData, "timestampSeconds", "disp1");
                updateSeries(series_TD_2, latestData, "timestampSeconds", "disp2");
                updateSeries(series_TD_3, latestData, "timestampSeconds", "disp3");
                break;

            case 2: // F-S 曲线
                // 裁剪
                while (series_DF_1.count >= targetLength && series_DF_1.count > 0) {
                    series_DF_1.remove(0); series_DF_2.remove(0); series_DF_3.remove(0);
                }
                // 添加
                updateSeries(series_DF_1, latestData, "disp1", "force1");
                updateSeries(series_DF_2, latestData, "disp2", "force2");
                updateSeries(series_DF_3, latestData, "disp3", "force3");
                break;
            }

        }

        // 🌟 关键修改 4: 通用工具函数: 将 C++ List 转换为 LineSeries 点 (增加 NaN/Inf 检查)
        function updateSeriesFromData(series, dataList, xKey, yKey) {
            series.clear(); // 强制清空当前曲线，确保从原点开始绘制

            for (var i = 0; i < dataList.length; i++) {
                var item = dataList[i];
                var xValue = item[xKey];
                var yValue = item[yKey];

                // 🚨 修复 NaN/Inf 报错：只接受有限数值
                if (isFinite(xValue) && isFinite(yValue)) {
                    series.append(xValue, yValue); // 重绘所有有效的历史点
                } else {
                    // 如果发现无效值，则跳过此点
                    // console.warn("Skipping historical invalid point for series " + series.name + ": X=" + xValue + ", Y=" + yValue);
                }
            }
        }

        // 🌟 工具函数: 自动滚动时间轴 (保留您的逻辑)
        function adjustAxisX(axis, currentTime) {
            var fixedRange = 30; // 固定的显示窗口宽度

            if (currentTime > fixedRange) {
                // 1. 滚动逻辑: 超过 30s，开始滚动
                chartRoot.chartXMax = currentTime;
                chartRoot.chartXMin = currentTime - fixedRange;

            } else {
                // 2. 强制固定逻辑: 0 <= currentTime <= 30s
                chartRoot.chartXMin = 0;
                chartRoot.chartXMax = fixedRange;
            }

            // 3. 复位逻辑 (保留)
            if (currentTime < 0) {
                chartRoot.chartXMin = 0;
                chartRoot.chartXMax = fixedRange;
            }
        }

        // 工具函数: 强制重置所有图表的轴上下限 (保留您的逻辑)
        function resetAllAxisLimits() {
            // 🌟 重置 QML 属性，所有时间轴通过 Binding 自动更新
            chartRoot.chartXMin = 0;
            chartRoot.chartXMax = 30;

            // 确保其他轴的固定范围
            axisX_DF.min = 0; axisX_DF.max = 1600;
            axisY_TF.min = 0; axisY_TF.max = 5100;
            axisY_TD.min = 0; axisY_TD.max = 1600;
            axisY_DF.min = 0; axisY_DF.max = 5100;
        }

        // 工具函数: 清空所有曲线 (保留您的逻辑，并确保重置轴)
        function clearAllSeries() {
            series_TF_1.clear(); series_TF_2.clear(); series_TF_3.clear();
            series_TD_1.clear(); series_TD_2.clear(); series_TD_3.clear();
            series_DF_1.clear(); series_DF_2.clear(); series_DF_3.clear();

            // chartRoot.resetAllAxisLimits();
        }

    }

    Rectangle{
        width: 490
        height: 800
        color: "gold"
        anchors.right: root.right
        anchors.rightMargin: 5
        anchors.top: root.top
        anchors.topMargin: 125
        border.width: 1

        Rectangle{
            width: 300
            height: 50
            color: "transparent"
            anchors.top: parent.top
            anchors.topMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            // border.width: 1

            Text{
                anchors.centerIn: parent
                font.pixelSize: 30
                font.bold: true
                text: "目标参数"
            }
        }


        Column{
            anchors.top: parent.top
            anchors.topMargin: 70
            anchors.left: parent.left
            anchors.leftMargin: 10
            spacing: 10

            Row{
                spacing: 10

                Text{
                    width: 170
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    text: "位移量1:"
                }

                TextField{
                    width: 120
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    placeholderText: plcData["Real_端肋设定位置1_I"].toFixed(2)

                    onEditingFinished: {
                        Cpp_ThreadManager.writeRegister32("Real_端肋设定位置1_I",(5300/2),text)
                    }
                }

                Button{
                    width: 80
                    height: 40
                    text: "启 动"
                    font.pixelSize: 20
                    onPressed: {
                        Cpp_ThreadManager.writeCoil("M2.4_端肋1_位置启动",9020,true)
                    }
                    onReleased: {
                        Cpp_ThreadManager.writeCoil("M2.4_端肋1_位置启动",9020,false)
                    }
                }
            }

            Row{
                spacing: 10

                Text{
                    width: 170
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    text: "位移量2:"
                }

                TextField{
                    width: 120
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    placeholderText: plcData["Real_中肋设定位置1_I"].toFixed(2)

                    onEditingFinished: {
                        Cpp_ThreadManager.writeRegister32("Real_中肋设定位置1_I",(5304/2),text)
                    }
                }

                Button{
                    width: 80
                    height: 40
                    text: "启 动"
                    font.pixelSize: 20
                    onPressed: {
                        Cpp_ThreadManager.writeCoil("M2.5_中肋1_位置启动",9021,true)
                    }
                    onReleased: {
                        Cpp_ThreadManager.writeCoil("M2.5_中肋1_位置启动",9021,false)
                    }
                }
            }
            Row{
                spacing: 10

                Text{
                    width: 170
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    text: "位移量3:"
                }

                TextField{
                    width: 120
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    placeholderText: plcData["Real_端肋设定位置2_I"].toFixed(2)

                    onEditingFinished: {
                        Cpp_ThreadManager.writeRegister32("Real_端肋设定位置2_I",(5308/2),text)
                    }
                }

                Button{
                    width: 80
                    height: 40
                    text: "启 动"
                    font.pixelSize: 20
                    onPressed: {
                        Cpp_ThreadManager.writeCoil("M2.6_端肋2_位置启动",9022,true)
                    }
                    onReleased: {
                        Cpp_ThreadManager.writeCoil("M2.6_端肋2_位置启动",9022,false)
                    }
                }
            }


            Rectangle{
                width: 100
                height: 25
                color: "transparent"
                // border.width: 1
            }


            Row{
                spacing: 10

                Text{
                    width: 170
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    text: "实验力1:"
                }

                TextField{
                    width: 120
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    placeholderText: plcData["Real_端肋设定力1_I"].toFixed(2)

                    onEditingFinished: {
                        Cpp_ThreadManager.writeRegister32("Real_端肋设定力1_I",(2500/2),text)
                    }
                }

                Button{
                    width: 80
                    height: 40
                    text: "启 动"
                    font.pixelSize: 20
                    onPressed: {
                        Cpp_ThreadManager.writeCoil("M2.0_端肋1_速度启动",9016,true)
                    }
                    onReleased: {
                        Cpp_ThreadManager.writeCoil("M2.0_端肋1_速度启动",9016,false)
                    }
                }
            }

            Row{
                spacing: 10

                Text{
                    width: 170
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    text: "实验力2:"
                }

                TextField{
                    width: 120
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    placeholderText: plcData["Real_中肋设定力1_I"].toFixed(2)

                    onEditingFinished: {
                        Cpp_ThreadManager.writeRegister32("Real_中肋设定力1_I",(2504/2),text)
                    }
                }

                Button{
                    width: 80
                    height: 40
                    text: "启 动"
                    font.pixelSize: 20
                    onPressed: {
                        Cpp_ThreadManager.writeCoil("M2.1_中肋1_速度启动",9017,true)
                    }
                    onReleased: {
                        Cpp_ThreadManager.writeCoil("M2.1_中肋1_速度启动",9017,false)
                    }
                }
            }

            Row{
                spacing: 10

                Text{
                    width: 170
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    text: "实验力3:"
                }

                TextField{
                    width: 120
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    placeholderText: plcData["Real_端肋设定力2_I"].toFixed(2)

                    onEditingFinished: {
                        Cpp_ThreadManager.writeRegister32("Real_端肋设定力2_I",(2508/2),text)
                    }
                }

                Button{
                    width: 80
                    height: 40
                    text: "启 动"
                    font.pixelSize: 20
                    onPressed: {
                        Cpp_ThreadManager.writeCoil("M2.2_端肋2_速度启动",9018,true)
                    }
                    onReleased: {
                        Cpp_ThreadManager.writeCoil("M2.2_端肋2_速度启动",9018,false)
                    }
                }
            }

            Rectangle{
                width: 100
                height: 25
                color: "transparent"
                // border.width: 1
            }


            Row{
                spacing: 10

                Text{
                    width: 170
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    text: "实验力1-速度:"
                }

                TextField{
                    width: 120
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    placeholderText: plcData["Real_端肋速度1_I"].toFixed(2)

                    onEditingFinished: {
                        Cpp_ThreadManager.writeRegister32("Real_端肋速度1_I",(7000/2),text)
                    }
                }

                Button{
                    width: 80
                    height: 40
                    text: "启 动"
                    font.pixelSize: 20
                    onPressed: {
                        Cpp_ThreadManager.writeCoil("M2.0_端肋1_速度启动",9016,true)
                    }
                    onReleased: {
                        Cpp_ThreadManager.writeCoil("M2.0_端肋1_速度启动",9016,false)
                    }
                }
            }

            Row{
                spacing: 10

                Text{
                    width: 170
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    text: "实验力2-速度:"
                }

                TextField{
                    width: 120
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    placeholderText: plcData["Real_中肋速度1_I"].toFixed(2)

                    onEditingFinished: {
                        Cpp_ThreadManager.writeRegister32("Real_中肋速度1_I",(7004/2),text)
                    }
                }

                Button{
                    width: 80
                    height: 40
                    text: "启 动"
                    font.pixelSize: 20
                    onPressed: {
                        Cpp_ThreadManager.writeCoil("M2.1_中肋1_速度启动",9017,true)
                    }
                    onReleased: {
                        Cpp_ThreadManager.writeCoil("M2.1_中肋1_速度启动",9017,false)
                    }
                }
            }

            Row{
                spacing: 10

                Text{
                    width: 170
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    text: "实验力3-速度:"
                }

                TextField{
                    width: 120
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    placeholderText: plcData["Real_端肋速度2_I"].toFixed(2)

                    onEditingFinished: {
                        Cpp_ThreadManager.writeRegister32("Real_端肋速度2_I",(7008/2),text)
                    }
                }

                Button{
                    width: 80
                    height: 40
                    text: "启 动"
                    font.pixelSize: 20
                    onPressed: {
                        Cpp_ThreadManager.writeCoil("M2.2_端肋2_速度启动",9018,true)
                    }
                    onReleased: {
                        Cpp_ThreadManager.writeCoil("M2.2_端肋2_速度启动",9018,false)
                    }
                }
            }

            Row{
                spacing: 10

                Text{
                    width: 170
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    text: "三端联动速度:"
                }

                TextField{
                    width: 120
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    placeholderText: plcData["Real_三缸速度1_I"].toFixed(2)

                    onEditingFinished: {
                        Cpp_ThreadManager.writeRegister32("Real_三缸速度1_I",(7016/2),text)
                    }
                }

                Button{
                    width: 80
                    height: 40
                    text: "停止"
                    font.pixelSize: 20
                    onPressed: {
                        Cpp_ThreadManager.writeCoil("M3.4_三端_停止",9028,true)
                    }
                    onReleased: {
                        Cpp_ThreadManager.writeCoil("M3.4_三端_停止",9028,false)
                    }
                }
                Button{
                    width: 80
                    height: 40
                    text: plcData["M3.6_三端_模式"] === 1 ? "联动" : "独立"
                    // text: "模式"
                    font.pixelSize: 20

                    onClicked: {
                        if(text === "联动")
                        {
                           Cpp_ThreadManager.writeCoil("M3.6_三端_模式",9030,false)
                        }
                        else
                        {
                            Cpp_ThreadManager.writeCoil("M3.6_三端_模式",9030,true)
                        }
                    }

                    // onPressed: {
                    //     Cpp_ThreadManager.writeCoil("M3.6_三端_模式",9030,true)
                    // }
                    // onReleased: {
                    //     Cpp_ThreadManager.writeCoil("M3.6_三端_模式",9030,false)
                    // }
                }
            }


            Row{
                spacing: 10

                Button{
                    width: 150
                    height: 40
                    text: "实验力1停止"
                    font.pixelSize: 20
                    onPressed: {
                        Cpp_ThreadManager.writeCoil("M3.0_端肋1_停止",9024,true)
                    }
                    onReleased: {
                        Cpp_ThreadManager.writeCoil("M3.0_端肋1_停止",9024,false)
                    }
                }
                Button{
                    width: 150
                    height: 40
                    text: "实验力2停止"
                    font.pixelSize: 20
                    onPressed: {
                        Cpp_ThreadManager.writeCoil("M3.1_中肋1_停止",9025,true)
                    }
                    onReleased: {
                        Cpp_ThreadManager.writeCoil("M3.1_中肋1_停止",9025,false)
                    }
                }
                Button{
                    width: 150
                    height: 40
                    text: "实验力3停止"
                    font.pixelSize: 20
                    onPressed: {
                        Cpp_ThreadManager.writeCoil("M3.2_端肋2_停止",9026,true)
                    }
                    onReleased: {
                        Cpp_ThreadManager.writeCoil("M3.2_端肋2_停止",9026,false)
                    }
                }

            }

            Row{
                spacing: 10

                Button{
                    width: 150
                    height: 40
                    text: "实验力1回零"
                    font.pixelSize: 20
                    onPressed: {
                        Cpp_ThreadManager.writeCoil("M4.0_端肋1_回零启动",9032,true)
                    }
                    onReleased: {
                        Cpp_ThreadManager.writeCoil("M4.0_端肋1_回零启动",9032,false)
                    }
                }
                Button{
                    width: 150
                    height: 40
                    text: "实验力2回零"
                    font.pixelSize: 20
                    onPressed: {
                        Cpp_ThreadManager.writeCoil("M4.1_中肋1_回零启动",9033,true)
                    }
                    onReleased: {
                        Cpp_ThreadManager.writeCoil("M4.1_中肋1_回零启动",9033,false)
                    }
                }
                Button{
                    width: 150
                    height: 40
                    text: "实验力3回零"
                    font.pixelSize: 20
                    onPressed: {
                        Cpp_ThreadManager.writeCoil("M4.2_端肋2_回零启动",9034,true)
                    }
                    onReleased: {
                        Cpp_ThreadManager.writeCoil("M4.2_端肋2_回零启动",9034,false)
                    }
                }
            }

            Row{
                spacing: 10

                Button{
                    width: 150
                    height: 40
                    font.pixelSize: 20
                    text: plcData["M4.4_端肋1_方向"] === 1 ? "实验力1-上" : "实验力1-下"

                    onClicked: {
                        if(text === "实验力1-上")
                        {
                            Cpp_ThreadManager.writeCoil("M4.4_端肋1_方向",9036,false)
                        }
                        else{
                            Cpp_ThreadManager.writeCoil("M4.4_端肋1_方向",9036,true)
                        }
                    }

                    // onPressed: {
                    //     Cpp_ThreadManager.writeCoil("M4.4_端肋1_方向",9036,true)
                    // }
                    // onReleased: {
                    //     Cpp_ThreadManager.writeCoil("M4.4_端肋1_方向",9036,false)
                    // }
                }
                Button{
                    width: 150
                    height: 40
                    text: plcData["M4.5_中肋1_方向"] === 1 ? "实验力2-上" : "实验力2-下"
                    font.pixelSize: 20

                    onClicked: {
                        if(text === "实验力2-上")
                        {
                            Cpp_ThreadManager.writeCoil("M4.5_中肋1_方向",9037,false)
                        }
                        else{
                            Cpp_ThreadManager.writeCoil("M4.5_中肋1_方向",9037,true)
                        }
                    }

                    // onPressed: {
                    //     Cpp_ThreadManager.writeCoil("M4.5_中肋1_方向",9037,true)
                    // }
                    // onReleased: {
                    //     Cpp_ThreadManager.writeCoil("M4.5_中肋1_方向",9037,false)
                    // }
                }
                Button{
                    width: 150
                    height: 40                    
                    text: plcData["M4.6_端肋2_方向"] === 1 ? "实验力3-上" : "实验力3-下"
                    font.pixelSize: 20

                    onClicked: {
                        if(text === "实验力3-上")
                        {
                            Cpp_ThreadManager.writeCoil("M4.6_端肋2_方向",9038,false)
                        }
                        else{
                            Cpp_ThreadManager.writeCoil("M4.6_端肋2_方向",9038,true)
                        }
                    }

                    // onPressed: {
                    //     Cpp_ThreadManager.writeCoil("M4.6_端肋2_方向",9038,true)
                    // }
                    // onReleased: {
                    //     Cpp_ThreadManager.writeCoil("M4.6_端肋2_方向",9038,false)
                    // }
                }
            }

        }

    }

    Row{
        anchors.bottom: root.bottom
        anchors.bottomMargin: 5
        anchors.right: root.right
        anchors.rightMargin: 5
        width: 370
        height: 70
        spacing: 5

        // 🌟 新增：保存曲线图片按钮
        Button{
            width: 120
            height: 70
            text: "保存曲线"
            font.pixelSize: 20
            onClicked: {
                saveChartView();
            }
        }

        Button{
            width: 120
            height: 70
            // anchors.bottom: parent.bottom
            text: "开始记录"
            font.pixelSize: 20
            onClicked: {
                console.log("开始记录实验数据")

                // 🌟 关键：在 C++ 开始更新数据前，强制轴范围为 0-60
                chartRoot.resetAllAxisLimits(); // 使用一个新的、更稳定的函数

                Cpp_ThreadManager.start_Experiment()
            }
        }

        Button{
            width: 120
            height: 70
            // anchors.bottom: parent.bottom
            text: "停止记录"
            font.pixelSize: 20
            onClicked: {
                console.log("终止实验")
                Cpp_ThreadManager.stop_Experiment()
            }
        }

    }


}
