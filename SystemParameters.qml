import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup{
    id: systemParametersPopup
    width: 600
    height: 900
    modal: true
    closePolicy: Popup.NoAutoClose

    Item{
        id:systemParametersRoot
        anchors.fill: parent
    }

    Rectangle{
        anchors.fill: parent
        // color: "gold"
        border.width: 1
        color: "#f0f0f0"
    }

    Column{
        anchors.horizontalCenter: systemParametersRoot.horizontalCenter
        anchors.top: systemParametersRoot.top
        anchors.topMargin: 20
        spacing: 30
        Row{

            Item{
                width: 550
                height: 60
                Rectangle{
                    anchors.fill: parent
                    color: "gold"
                }

            }

        }
        Row{

            Item{
                width: 550
                height: 60
                Rectangle{
                    anchors.fill: parent
                    color: "gold"
                }

            }

        }
        Row{

            Item{
                width: 550
                height: 60
                Rectangle{
                    anchors.fill: parent
                    color: "gold"
                }

            }

        }
        Row{

            Item{
                width: 550
                height: 60
                Rectangle{
                    anchors.fill: parent
                    color: "gold"
                }

            }

        }
        Row{

            Item{
                width: 550
                height: 60
                Rectangle{
                    anchors.fill: parent
                    color: "gold"
                }

            }

        }
        Row{

            Item{
                width: 550
                height: 60
                Rectangle{
                    anchors.fill: parent
                    color: "gold"
                }

            }

        }
        Row{

            Item{
                width: 550
                height: 60
                Rectangle{
                    anchors.fill: parent
                    color: "gold"
                }

            }

        }
        Row{

            Item{
                width: 550
                height: 60
                Rectangle{
                    anchors.fill: parent
                    color: "gold"
                }

            }

        }
        Row{

            Item{
                width: 550
                height: 60
                Rectangle{
                    anchors.fill: parent
                    color: "gold"
                }

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
