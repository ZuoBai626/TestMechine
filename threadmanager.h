#ifndef THREADMANAGER_H
#define THREADMANAGER_H

#include <QObject>
#include <QThread>
#include <QVariantMap>
#include <QVariantList>
#include <QQuickWindow>
#include <QElapsedTimer>

#include "modbuscontrol.h"
#include "readwritecsv.h"

// 用于QML图表的点结构体
struct ChartPoint {
    Q_GADGET
    Q_PROPERTY(qreal timestampSeconds MEMBER timestampSeconds)
    Q_PROPERTY(qreal force1 MEMBER force1)
    Q_PROPERTY(qreal force2 MEMBER force2)
    Q_PROPERTY(qreal force3 MEMBER force3)
    Q_PROPERTY(qreal disp1 MEMBER disp1)
    Q_PROPERTY(qreal disp2 MEMBER disp2)
    Q_PROPERTY(qreal disp3 MEMBER disp3)
public:
    qreal timestampSeconds = 0.0;
    qreal force1 = 0.0, force2 = 0.0, force3 = 0.0;
    qreal disp1 = 0.0, disp2 = 0.0, disp3 = 0.0;

    static void registerType() { qRegisterMetaType<ChartPoint>("ChartPoint"); }
};

class ThreadManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariantMap plcData READ plcData NOTIFY plcDataChanged)
    Q_PROPERTY(QVariantList chartDataModel READ chartDataModel NOTIFY chartDataModelChanged)
    Q_PROPERTY(QVariant lastWriteCoilResult READ lastWriteCoilResult NOTIFY lastWriteCoilResultChanged)
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY isConnectedChanged)

public:
    static ThreadManager* getInstance();
    ThreadManager(const ThreadManager&) = delete;
    ThreadManager& operator=(const ThreadManager&) = delete;

    QVariantMap plcData() const { return m_latestPlcData; }
    QVariantList chartDataModel() const { return m_chartDataModel; }
    QVariant lastWriteCoilResult() const { return m_lastWriteCoilResult; }
    bool isConnected() const { return m_isConnected; }

    void setQmlRootWindow(QQuickWindow* window);
    Q_INVOKABLE QString saveChartImage();

    Q_INVOKABLE void start_Experiment();  // 开始实验：仅启动轮询+记录
    Q_INVOKABLE void stop_Experiment();   // 停止实验：仅停止轮询+保存CSV

    Q_INVOKABLE void writeCoil(const QString& qmlKey, int address, bool value);
    Q_INVOKABLE void writeRegister16(const QString& qmlKey, int address, qint16 value);
    Q_INVOKABLE void writeRegister32(const QString& qmlKey, int address, float value);

signals:
    void plcDataChanged();
    void chartDataModelChanged();
    void lastWriteCoilResultChanged();
    void isConnectedChanged();

    void writeCoilSignal(const QString& qmlKey, int address, bool value);
    void writeRegister16Signal(const QString& qmlKey, int address, qint16 value);
    void writeRegister32Signal(const QString& qmlKey, int address, float value);

    void startCsvLoggingSignal();
    void stopAndSaveCsvSignal();

private slots:
    void handleInstantData(const QVariantMap& data);
    void updateLastWriteCoilResult(const QVariant& value);
    void updateConnectionStatus(bool connected);

private:
    explicit ThreadManager(QObject *parent = nullptr);
    ~ThreadManager();

    QThread* m_PLC_Thread = nullptr;           // PLC通信专用线程
    ModbusControl* m_PLC = nullptr;            // Modbus控制对象

    QThread* m_CSV_Thread = nullptr;           // CSV记录专用线程
    ReadWriteCSV* m_CSV_Logger = nullptr;      // CSV读写器

    QVariantMap m_latestPlcData;               // 主线程缓存的最新PLC数据
    QVariantList m_chartDataModel;             // 图表数据模型
    QVariant m_lastWriteCoilResult;            // 上次线圈写入校验结果
    bool m_isConnected = false;                // 当前连接状态

    QQuickWindow* m_rootWindow = nullptr;      // QML根窗口，用于截图
    const int MAX_CHART_POINTS = 300000;       // 图表最大点数限制
};

#endif // THREADMANAGER_H
