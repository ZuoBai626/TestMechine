import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup{
    id: systemParametersPopup
    width: 1700
    height: 950
    modal: true
    closePolicy: Popup.NoAutoClose
    background: Rectangle{
        border.width: 1
        color: "#f0f0f0"
    }

    // 2. 快捷访问 PLC 实时数据 Map
    readonly property var plcData: Cpp_ThreadManager.plcData

    Item{
        id:systemParametersRoot
        anchors.fill: parent
    }

    Rectangle{
        anchors.left: systemParametersRoot.left
        anchors.leftMargin: 10
        anchors.top: systemParametersRoot.top
        anchors.topMargin: 10
        width: 330
        height: 400
        color: "gold"
        border.width: 1

        Column{
            anchors.top: parent.top
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.leftMargin: 10
            spacing: 10

            Rectangle{
                width: 300
                height: 50
                color: "transparent"
                // border.width: 1

                Text{
                    anchors.centerIn: parent
                    font.pixelSize: 30
                    font.bold: true
                    text: "上下限设定"
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
                    text: "实验力1-上限:"
                }

                TextField{
                    width: 120
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    placeholderText: plcData["Real_端肋力1_U"].toFixed(2)

                    onEditingFinished: {
                        Cpp_ThreadManager.writeRegister32("Real_端肋力1_U",(2000/2),text)
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
                    text: "实验力2-上限:"
                }

                TextField{
                    width: 120
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    placeholderText: plcData["Real_中肋力1_U"].toFixed(2)

                    onEditingFinished: {
                        Cpp_ThreadManager.writeRegister32("Real_中肋力1_U",(2004/2),text)
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
                    text: "实验力3-上限:"
                }

                TextField{
                    width: 120
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    placeholderText: plcData["Real_端肋力2_U"].toFixed(2)

                    onEditingFinished: {
                        Cpp_ThreadManager.writeRegister32("Real_端肋力2_U",(2008/2),text)
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
                    text: "实验力1-下限:"
                }

                TextField{
                    width: 120
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    placeholderText: plcData["Real_端肋力1_L"].toFixed(2)

                    onEditingFinished: {
                        Cpp_ThreadManager.writeRegister32("Real_端肋力1_L",(2100/2),text)
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
                    text: "实验力2-下限:"
                }

                TextField{
                    width: 120
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    placeholderText: plcData["Real_中肋力1_L"].toFixed(2)

                    onEditingFinished: {
                        Cpp_ThreadManager.writeRegister32("Real_中肋力1_L",(2104/2),text)
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
                    text: "实验力3-下限:"
                }

                TextField{
                    width: 120
                    height: 40
                    horizontalAlignment: Text.AlignHCenter  // 水平居中
                    verticalAlignment: Text.AlignVCenter    // 垂直居中
                    font.pixelSize: 25
                    placeholderText: plcData["Real_端肋力2_L"].toFixed(2)

                    onEditingFinished: {
                        Cpp_ThreadManager.writeRegister32("Real_端肋力2_L",(2108/2),text)
                    }
                }
            }

        }

    }


    Rectangle{
        anchors.left: systemParametersRoot.left
        anchors.leftMargin: 360
        anchors.top: systemParametersRoot.top
        anchors.topMargin: 10
        width: 500
        height: 920
        color: "gold"
        border.width: 1

        Rectangle{
            width: 300
            height: 50
            color: "transparent"
            anchors.top: parent.top
            anchors.topMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter

            Text{
                anchors.centerIn: parent
                font.pixelSize: 30
                font.bold: true
                text: "实验力标定(五段标定)"
            }
        }

        Column{
            anchors.top: parent.top
            anchors.topMargin: 70
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10


            Rectangle{      // 第一段标定
                width: 480
                height: 160
                border.width: 1

                Column{
                    anchors.top: parent.top
                    anchors.topMargin: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    Row{
                        spacing: 10

                        Text{
                            width: 170
                            height: 40
                            horizontalAlignment: Text.AlignHCenter  // 水平居中
                            verticalAlignment: Text.AlignVCenter    // 垂直居中
                            font.pixelSize: 25
                            text: "实验力1-标定1:"
                        }

                        TextField{
                            width: 120
                            height: 40
                            horizontalAlignment: Text.AlignHCenter  // 水平居中
                            verticalAlignment: Text.AlignVCenter    // 垂直居中
                            font.pixelSize: 25
                            placeholderText: plcData["Real_端肋一标力1_I"].toFixed(2)

                            onEditingFinished: {
                                Cpp_ThreadManager.writeRegister32("Real_端肋一标力1_I",(8100/2),text)
                            }
                        }

                        Button{
                            width: 120
                            height: 40
                            text: "标 定"
                            onPressed: {
                                Cpp_ThreadManager.writeCoil("M5.0_端肋1_标定1",9040,true)
                            }
                            onReleased: {
                                Cpp_ThreadManager.writeCoil("M5.0_端肋1_标定1",9040,false)
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
                            text: "实验力2-标定1:"
                        }

                        TextField{
                            width: 120
                            height: 40
                            horizontalAlignment: Text.AlignHCenter  // 水平居中
                            verticalAlignment: Text.AlignVCenter    // 垂直居中
                            font.pixelSize: 25
                            placeholderText: plcData["Real_中肋一标力1_I"].toFixed(2)

                            onEditingFinished: {
                                Cpp_ThreadManager.writeRegister32("Real_中肋一标力1_I",(8104/2),text)
                            }
                        }

                        Button{
                            width: 120
                            height: 40
                            text: "标 定"
                            onPressed: {
                                Cpp_ThreadManager.writeCoil("M5.1_中肋1_标定",9041,true)
                            }
                            onReleased: {
                                Cpp_ThreadManager.writeCoil("M5.1_中肋1_标定",9041,false)
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
                            text: "实验力3-标定1:"
                        }

                        TextField{
                            width: 120
                            height: 40
                            horizontalAlignment: Text.AlignHCenter  // 水平居中
                            verticalAlignment: Text.AlignVCenter    // 垂直居中
                            font.pixelSize: 25
                            placeholderText: plcData["Real_端肋一标力2_I"].toFixed(2)

                            onEditingFinished: {
                                Cpp_ThreadManager.writeRegister32("Real_端肋一标力2_I",(8108/2),text)
                            }
                        }

                        Button{
                            width: 120
                            height: 40
                            text: "标 定"
                            onPressed: {
                                Cpp_ThreadManager.writeCoil("M5.2_端肋2_标定1",9042,true)
                            }
                            onReleased: {
                                Cpp_ThreadManager.writeCoil("M5.2_端肋2_标定1",9042,false)
                            }
                        }

                    }
                    // Row{

                    //     Text{
                    //         width: 170
                    //         height: 40
                    //         font.pixelSize: 25
                    //         text: "伺服一标力1:"
                    //     }

                    //     TextField{
                    //         width: 120
                    //         height: 40
                    //         horizontalAlignment: Text.AlignHCenter  // 水平居中
                    //         verticalAlignment: Text.AlignVCenter    // 垂直居中
                    //         font.pixelSize: 25
                    //         placeholderText: plcData["Real_伺服一标力1_I"].toFixed(2)

                    //         onEditingFinished: {
                    //             Cpp_ThreadManager.writeRegister32("Real_伺服一标力1_I",(8112/2),text)
                    //         }
                    //     }

                    // }

                }

            }

            Rectangle{      // 第二段标定
                width: 480
                height: 160
                border.width: 1

                Column{
                    anchors.top: parent.top
                    anchors.topMargin: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    Row{
                        spacing: 10

                        Text{
                            width: 170
                            height: 40
                            horizontalAlignment: Text.AlignHCenter  // 水平居中
                            verticalAlignment: Text.AlignVCenter    // 垂直居中
                            font.pixelSize: 25
                            text: "实验力1-标定2:"
                        }

                        TextField{
                            width: 120
                            height: 40
                            horizontalAlignment: Text.AlignHCenter  // 水平居中
                            verticalAlignment: Text.AlignVCenter    // 垂直居中
                            font.pixelSize: 25
                            placeholderText: plcData["Real_端肋二标力1_I"].toFixed(2)

                            onEditingFinished: {
                                Cpp_ThreadManager.writeRegister32("Real_端肋二标力1_I",(8120/2),text)
                            }
                        }

                        Button{
                            width: 120
                            height: 40
                            text: "标 定"
                            onPressed: {
                                Cpp_ThreadManager.writeCoil("M5.4_端肋1_标定2",9044,true)
                            }
                            onReleased: {
                                Cpp_ThreadManager.writeCoil("M5.4_端肋1_标定2",9044,false)
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
                            text: "实验力2-标定2:"
                        }

                        TextField{
                            width: 120
                            height: 40
                            horizontalAlignment: Text.AlignHCenter  // 水平居中
                            verticalAlignment: Text.AlignVCenter    // 垂直居中
                            font.pixelSize: 25
                            placeholderText: plcData["Real_中肋二标力1_I"].toFixed(2)

                            onEditingFinished: {
                                Cpp_ThreadManager.writeRegister32("Real_中肋二标力1_I",(8124/2),text)
                            }
                        }

                        Button{
                            width: 120
                            height: 40
                            text: "标 定"
                            onPressed: {
                                Cpp_ThreadManager.writeCoil("M5.5_中肋1_标定",9045,true)
                            }
                            onReleased: {
                                Cpp_ThreadManager.writeCoil("M5.5_中肋1_标定",9045,false)
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
                            text: "实验力3-标定2:"
                        }

                        TextField{
                            width: 120
                            height: 40
                            horizontalAlignment: Text.AlignHCenter  // 水平居中
                            verticalAlignment: Text.AlignVCenter    // 垂直居中
                            font.pixelSize: 25
                            placeholderText: plcData["Real_端肋二标力2_I"].toFixed(2)

                            onEditingFinished: {
                                Cpp_ThreadManager.writeRegister32("Real_端肋二标力2_I",(8128/2),text)
                            }
                        }

                        Button{
                            width: 120
                            height: 40
                            text: "标 定"
                            onPressed: {
                                Cpp_ThreadManager.writeCoil("M5.6_端肋2_标定2",9046,true)
                            }
                            onReleased: {
                                Cpp_ThreadManager.writeCoil("M5.6_端肋2_标定2",9046,false)
                            }
                        }

                    }
                    // Row{

                    //     Text{
                    //         width: 170
                    //         height: 40
                    //         font.pixelSize: 25
                    //         text: "伺服一标力1:"
                    //     }

                    //     TextField{
                    //         width: 120
                    //         height: 40
                    //         horizontalAlignment: Text.AlignHCenter  // 水平居中
                    //         verticalAlignment: Text.AlignVCenter    // 垂直居中
                    //         font.pixelSize: 25
                    //         placeholderText: plcData["Real_伺服一标力1_I"].toFixed(2)

                    //         onEditingFinished: {
                    //             Cpp_ThreadManager.writeRegister32("Real_伺服一标力1_I",(8112/2),text)
                    //         }
                    //     }

                    // }

                }
            }

            Rectangle{      // 第三段标定
                width: 480
                height: 160
                border.width: 1

                Column{
                    anchors.top: parent.top
                    anchors.topMargin: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    Row{
                        spacing: 10

                        Text{
                            width: 170
                            height: 40
                            horizontalAlignment: Text.AlignHCenter  // 水平居中
                            verticalAlignment: Text.AlignVCenter    // 垂直居中
                            font.pixelSize: 25
                            text: "实验力1-标定3:"
                        }

                        TextField{
                            width: 120
                            height: 40
                            horizontalAlignment: Text.AlignHCenter  // 水平居中
                            verticalAlignment: Text.AlignVCenter    // 垂直居中
                            font.pixelSize: 25
                            placeholderText: plcData["Real_端肋三标力1_I"].toFixed(2)

                            onEditingFinished: {
                                Cpp_ThreadManager.writeRegister32("Real_端肋三标力1_I",(8140/2),text)
                            }
                        }

                        Button{
                            width: 120
                            height: 40
                            text: "标 定"
                            onPressed: {
                                Cpp_ThreadManager.writeCoil("M6.0_端肋1_标定3",9048,true)
                            }
                            onReleased: {
                                Cpp_ThreadManager.writeCoil("M6.0_端肋1_标定3",9048,false)
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
                            text: "实验力2-标定3:"
                        }

                        TextField{
                            width: 120
                            height: 40
                            horizontalAlignment: Text.AlignHCenter  // 水平居中
                            verticalAlignment: Text.AlignVCenter    // 垂直居中
                            font.pixelSize: 25
                            placeholderText: plcData["Real_中肋三标力1_I"].toFixed(2)

                            onEditingFinished: {
                                Cpp_ThreadManager.writeRegister32("Real_中肋三标力1_I",(8144/2),text)
                            }
                        }

                        Button{
                            width: 120
                            height: 40
                            text: "标 定"
                            onPressed: {
                                Cpp_ThreadManager.writeCoil("M6.1_中肋1_标定3",9049,true)
                            }
                            onReleased: {
                                Cpp_ThreadManager.writeCoil("M6.1_中肋1_标定3",9049,false)
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
                            text: "实验力3-标定3:"
                        }

                        TextField{
                            width: 120
                            height: 40
                            horizontalAlignment: Text.AlignHCenter  // 水平居中
                            verticalAlignment: Text.AlignVCenter    // 垂直居中
                            font.pixelSize: 25
                            placeholderText: plcData["Real_端肋三标力2_I"].toFixed(2)

                            onEditingFinished: {
                                Cpp_ThreadManager.writeRegister32("Real_端肋三标力2_I",(8148/2),text)
                            }
                        }

                        Button{
                            width: 120
                            height: 40
                            text: "标 定"
                            onPressed: {
                                Cpp_ThreadManager.writeCoil("M6.2_端肋2_标定3",9050,true)
                            }
                            onReleased: {
                                Cpp_ThreadManager.writeCoil("M6.2_端肋2_标定3",9050,false)
                            }
                        }

                    }
                    // Row{

                    //     Text{
                    //         width: 170
                    //         height: 40
                    //         font.pixelSize: 25
                    //         text: "伺服一标力1:"
                    //     }

                    //     TextField{
                    //         width: 120
                    //         height: 40
                    //         horizontalAlignment: Text.AlignHCenter  // 水平居中
                    //         verticalAlignment: Text.AlignVCenter    // 垂直居中
                    //         font.pixelSize: 25
                    //         placeholderText: plcData["Real_伺服一标力1_I"].toFixed(2)

                    //         onEditingFinished: {
                    //             Cpp_ThreadManager.writeRegister32("Real_伺服一标力1_I",(8112/2),text)
                    //         }
                    //     }

                    // }

                }

            }

            Rectangle{      // 第四段标定
                width: 480
                height: 160
                border.width: 1

                Column{
                    anchors.top: parent.top
                    anchors.topMargin: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    Row{
                        spacing: 10

                        Text{
                            width: 170
                            height: 40
                            horizontalAlignment: Text.AlignHCenter  // 水平居中
                            verticalAlignment: Text.AlignVCenter    // 垂直居中
                            font.pixelSize: 25
                            text: "实验力1-标定4:"
                        }

                        TextField{
                            width: 120
                            height: 40
                            horizontalAlignment: Text.AlignHCenter  // 水平居中
                            verticalAlignment: Text.AlignVCenter    // 垂直居中
                            font.pixelSize: 25
                            placeholderText: plcData["Real_端肋四标力1_I"].toFixed(2)

                            onEditingFinished: {
                                Cpp_ThreadManager.writeRegister32("Real_端肋四标力1_I",(8160/2),text)
                            }
                        }

                        Button{
                            width: 120
                            height: 40
                            text: "标 定"
                            onPressed: {
                                Cpp_ThreadManager.writeCoil("M6.4_端肋1_标定4",9052,true)
                            }
                            onReleased: {
                                Cpp_ThreadManager.writeCoil("M6.4_端肋1_标定4",9052,false)
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
                            text: "实验力2-标定4:"
                        }

                        TextField{
                            width: 120
                            height: 40
                            horizontalAlignment: Text.AlignHCenter  // 水平居中
                            verticalAlignment: Text.AlignVCenter    // 垂直居中
                            font.pixelSize: 25
                            placeholderText: plcData["Real_中肋四标力1_I"].toFixed(2)

                            onEditingFinished: {
                                Cpp_ThreadManager.writeRegister32("Real_中肋四标力1_I",(8164/2),text)
                            }
                        }

                        Button{
                            width: 120
                            height: 40
                            text: "标 定"
                            onPressed: {
                                Cpp_ThreadManager.writeCoil("M6.5_中肋1_标定4",9053,true)
                            }
                            onReleased: {
                                Cpp_ThreadManager.writeCoil("M6.5_中肋1_标定4",9053,false)
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
                            text: "实验力3-标定4:"
                        }

                        TextField{
                            width: 120
                            height: 40
                            horizontalAlignment: Text.AlignHCenter  // 水平居中
                            verticalAlignment: Text.AlignVCenter    // 垂直居中
                            font.pixelSize: 25
                            placeholderText: plcData["Real_端肋四标力2_I"].toFixed(2)

                            onEditingFinished: {
                                Cpp_ThreadManager.writeRegister32("Real_端肋四标力2_I",(8168/2),text)
                            }
                        }

                        Button{
                            width: 120
                            height: 40
                            text: "标 定"
                            onPressed: {
                                Cpp_ThreadManager.writeCoil("M6.6_端肋2_标定4",9054,true)
                            }
                            onReleased: {
                                Cpp_ThreadManager.writeCoil("M6.6_端肋2_标定4",9054,false)
                            }
                        }

                    }
                    // Row{

                    //     Text{
                    //         width: 170
                    //         height: 40
                    //         font.pixelSize: 25
                    //         text: "伺服一标力1:"
                    //     }

                    //     TextField{
                    //         width: 120
                    //         height: 40
                    //         horizontalAlignment: Text.AlignHCenter  // 水平居中
                    //         verticalAlignment: Text.AlignVCenter    // 垂直居中
                    //         font.pixelSize: 25
                    //         placeholderText: plcData["Real_伺服一标力1_I"].toFixed(2)

                    //         onEditingFinished: {
                    //             Cpp_ThreadManager.writeRegister32("Real_伺服一标力1_I",(8112/2),text)
                    //         }
                    //     }

                    // }

                }

            }

            Rectangle{      // 第五段标定
                width: 480
                height: 160
                border.width: 1

                Column{
                    anchors.top: parent.top
                    anchors.topMargin: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    Row{
                        spacing: 10

                        Text{
                            width: 170
                            height: 40
                            horizontalAlignment: Text.AlignHCenter  // 水平居中
                            verticalAlignment: Text.AlignVCenter    // 垂直居中
                            font.pixelSize: 25
                            text: "实验力1-标定5:"
                        }

                        TextField{
                            width: 120
                            height: 40
                            horizontalAlignment: Text.AlignHCenter  // 水平居中
                            verticalAlignment: Text.AlignVCenter    // 垂直居中
                            font.pixelSize: 25
                            placeholderText: plcData["Real_端肋五标力1_I"].toFixed(2)

                            onEditingFinished: {
                                Cpp_ThreadManager.writeRegister32("Real_端肋五标力1_I",(8180/2),text)
                            }
                        }

                        Button{
                            width: 120
                            height: 40
                            text: "标 定"
                            onPressed: {
                                Cpp_ThreadManager.writeCoil("M7.0_端肋1_标定5",9056,true)
                            }
                            onReleased: {
                                Cpp_ThreadManager.writeCoil("M7.0_端肋1_标定5",9056,false)
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
                            text: "实验力2-标定5:"
                        }

                        TextField{
                            width: 120
                            height: 40
                            horizontalAlignment: Text.AlignHCenter  // 水平居中
                            verticalAlignment: Text.AlignVCenter    // 垂直居中
                            font.pixelSize: 25
                            placeholderText: plcData["Real_中肋五标力1_I"].toFixed(2)

                            onEditingFinished: {
                                Cpp_ThreadManager.writeRegister32("Real_中肋五标力1_I",(8184/2),text)
                            }
                        }

                        Button{
                            width: 120
                            height: 40
                            text: "标 定"
                            onPressed: {
                                Cpp_ThreadManager.writeCoil("M7.1_中肋1_标定5",9057,true)
                            }
                            onReleased: {
                                Cpp_ThreadManager.writeCoil("M7.1_中肋1_标定5",9057,false)
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
                            text: "实验力3-标定5:"
                        }

                        TextField{
                            width: 120
                            height: 40
                            horizontalAlignment: Text.AlignHCenter  // 水平居中
                            verticalAlignment: Text.AlignVCenter    // 垂直居中
                            font.pixelSize: 25
                            placeholderText: plcData["Real_端肋五标力2_I"].toFixed(2)

                            onEditingFinished: {
                                Cpp_ThreadManager.writeRegister32("Real_端肋五标力2_I",(8188/2),text)
                            }
                        }

                        Button{
                            width: 120
                            height: 40
                            text: "标 定"
                            onPressed: {
                                Cpp_ThreadManager.writeCoil("M7.2_端肋2_标定5",9058,true)
                            }
                            onReleased: {
                                Cpp_ThreadManager.writeCoil("M7.2_端肋2_标定5",9058,false)
                            }
                        }

                    }
                    // Row{

                    //     Text{
                    //         width: 170
                    //         height: 40
                    //         font.pixelSize: 25
                    //         text: "伺服一标力1:"
                    //     }

                    //     TextField{
                    //         width: 120
                    //         height: 40
                    //         horizontalAlignment: Text.AlignHCenter  // 水平居中
                    //         verticalAlignment: Text.AlignVCenter    // 垂直居中
                    //         font.pixelSize: 25
                    //         placeholderText: plcData["Real_伺服一标力1_I"].toFixed(2)

                    //         onEditingFinished: {
                    //             Cpp_ThreadManager.writeRegister32("Real_伺服一标力1_I",(8112/2),text)
                    //         }
                    //     }

                    // }

                }

            }            
        }


    }


    Rectangle{
        anchors.left: systemParametersRoot.left
        anchors.leftMargin: 880
        anchors.top: systemParametersRoot.top
        anchors.topMargin: 10
        width: 500
        height: 240
        color: "gold"
        border.width: 1

        Rectangle{
            width: 300
            height: 50
            color: "transparent"
            anchors.top: parent.top
            anchors.topMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter

            Text{
                anchors.centerIn: parent
                font.pixelSize: 30
                font.bold: true
                text: "位移量标定"
            }
        }


        Rectangle{      // 位移量标定
            width: 480
            height: 160
            border.width: 1
            anchors.top: parent.top
            anchors.topMargin: 70
            anchors.horizontalCenter: parent.horizontalCenter

            Column{
                anchors.top: parent.top
                anchors.topMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                Row{
                    spacing: 10

                    Text{
                        width: 170
                        height: 40
                        horizontalAlignment: Text.AlignHCenter  // 水平居中
                        verticalAlignment: Text.AlignVCenter    // 垂直居中
                        font.pixelSize: 25
                        text: "位移量1-标定 :"
                    }

                    TextField{
                        width: 120
                        height: 40
                        horizontalAlignment: Text.AlignHCenter  // 水平居中
                        verticalAlignment: Text.AlignVCenter    // 垂直居中
                        font.pixelSize: 25
                        placeholderText: plcData["Real_端肋标定位移1_I"].toFixed(2)

                        onEditingFinished: {
                            Cpp_ThreadManager.writeRegister32("Real_端肋标定位移1_I",(4300/2),text)
                        }
                    }

                    Button{
                        width: 120
                        height: 40
                        text: "标 定"
                        onPressed: {
                            Cpp_ThreadManager.writeCoil("M8.0_端肋1_校准",9064,true)
                        }
                        onReleased: {
                            Cpp_ThreadManager.writeCoil("M8.0_端肋1_校准",9064,false)
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
                        text: "位移量2-标定 :"
                    }

                    TextField{
                        width: 120
                        height: 40
                        horizontalAlignment: Text.AlignHCenter  // 水平居中
                        verticalAlignment: Text.AlignVCenter    // 垂直居中
                        font.pixelSize: 25
                        placeholderText: plcData["Real_中肋标定位移1_I"].toFixed(2)

                        onEditingFinished: {
                            Cpp_ThreadManager.writeRegister32("Real_中肋标定位移1_I",(4304/2),text)
                        }
                    }

                    Button{
                        width: 120
                        height: 40
                        text: "标 定"
                        onPressed: {
                            Cpp_ThreadManager.writeCoil("M8.1_中肋1_校准",9065,true)
                        }
                        onReleased: {
                            Cpp_ThreadManager.writeCoil("M8.1_中肋1_校准",9065,false)
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
                        text: "位移量3-标定 :"
                    }

                    TextField{
                        width: 120
                        height: 40
                        horizontalAlignment: Text.AlignHCenter  // 水平居中
                        verticalAlignment: Text.AlignVCenter    // 垂直居中
                        font.pixelSize: 25
                        placeholderText: plcData["Real_端肋标定位移2_I"].toFixed(2)

                        onEditingFinished: {
                            Cpp_ThreadManager.writeRegister32("Real_端肋标定位移2_I",(4308/2),text)
                        }
                    }

                    Button{
                        width: 120
                        height: 40
                        text: "标 定"
                        onPressed: {
                            Cpp_ThreadManager.writeCoil("M8.2_端肋2_校准",9066,true)
                        }
                        onReleased: {
                            Cpp_ThreadManager.writeCoil("M8.2_端肋2_校准",9066,false)
                        }
                    }

                }
                // Row{

                //     Text{
                //         width: 170
                //         height: 40
                //         font.pixelSize: 25
                //         text: "伺服一标力1:"
                //     }

                //     TextField{
                //         width: 120
                //         height: 40
                //         horizontalAlignment: Text.AlignHCenter  // 水平居中
                //         verticalAlignment: Text.AlignVCenter    // 垂直居中
                //         font.pixelSize: 25
                //         placeholderText: plcData["Real_伺服一标力1_I"].toFixed(2)

                //         onEditingFinished: {
                //             Cpp_ThreadManager.writeRegister32("Real_伺服一标力1_I",(8112/2),text)
                //         }
                //     }

                // }

            }

        }



    }








    Button{
        anchors.bottom: systemParametersRoot.bottom
        anchors.bottomMargin: 5
        anchors.right: systemParametersRoot.right
        anchors.rightMargin: 5
        width: 120
        height: 40
        text: "关 闭"
        onClicked: {
            console.log("关闭标定界面")
            systemParametersPopup.close()
        }
    }


}
