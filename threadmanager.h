#ifndef THREADMANAGER_H
#define THREADMANAGER_H

#include <QObject>
#include <QThread>
#include <QVariantMap>
#include <QVariantList>
#include "modbuscontrol.h"
#include "readwritecsv.h"


// ChartPoint 结构体
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
    qreal timestampSeconds;
    qreal force1, force2, force3;
    qreal disp1, disp2, disp3;

    static void registerType() { qRegisterMetaType<ChartPoint>("ChartPoint"); }
};

class ThreadManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariantMap plcData READ plcData NOTIFY plcDataChanged)
    Q_PROPERTY(QVariantList chartDataModel READ chartDataModel NOTIFY chartDataModelChanged)
    Q_PROPERTY(QVariant lastWriteCoilResult READ lastWriteCoilResult NOTIFY lastWriteCoilResultChanged)
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY isConnectedChanged) // 新增连接状态属性

public:
    // [单例] 静态方法获取单例实例
    static ThreadManager* getInstance();

    // 禁止拷贝
    ThreadManager(const ThreadManager&) = delete;
    ThreadManager& operator=(const ThreadManager&) = delete;

    // Getter 方法
    QVariantMap plcData() const { return m_latestPlcData; }
    QVariantList chartDataModel() const { return m_chartDataModel; }
    QVariant lastWriteCoilResult() const { return m_lastWriteCoilResult; }
    bool isConnected() const { return m_isConnected; } // Getter 实现

    // Q_INVOKABLE 方法
    Q_INVOKABLE void start_Experiment();
    Q_INVOKABLE void stop_Experiment();
    Q_INVOKABLE void writeCoil(const QString& qmlKey, int address, bool value);
    Q_INVOKABLE void writeRegister16(const QString& qmlKey, int address, qint16 value); // 新增 16位写入 QML 接口
    Q_INVOKABLE void writeRegister32(const QString& qmlKey, int address, float value);

signals:
    void plcDataChanged();
    void chartDataModelChanged();
    void lastWriteCoilResultChanged();
    void isConnectedChanged(); // 状态变更信号

    // 🌟 新增信号：请求子线程重置周期计数器
    void resetCycleCountSignal();

    // 🌟 新增信号：通知 CSV 记录器开始/停止
    void startCsvLoggingSignal();
    void stopAndSaveCsvSignal();

    // [转发信号]
    void stopPollingSignal(); // 请求子线程停止定时器
    void writeCoilSignal(const QString& qmlKey, int address, bool value);
    void writeRegister16Signal(const QString& qmlKey, int address, qint16 value); // 转发 16位写入
    void writeRegister32Signal(const QString& qmlKey, int address, float value);

private slots:
    void handleInstantData(const QVariantMap& data);
    void updateLastWriteCoilResult(const QVariant& value);
    void updateConnectionStatus(bool connected); // 处理连接状态变更

private:
    // [私有] 构造函数
    explicit ThreadManager(QObject *parent = nullptr);
    ~ThreadManager();

    QThread* m_PLC_Thread = nullptr;
    ModbusControl* m_PLC = nullptr;

    // 🌟 新增 CSV 记录器和线程
    QThread* m_CSV_Thread = nullptr;
    ReadWriteCSV* m_CSV_Logger = nullptr;

    // 🌟 ADDED: 实验计时器
    QElapsedTimer m_experimentTimer;

    // 主线程维护的数据副本
    QVariantMap m_latestPlcData;
    QVariantList m_chartDataModel;
    QVariant m_lastWriteCoilResult;
    bool m_isConnected = false; // 连接状态

    const int MAX_CHART_POINTS = 500;
};

#endif // THREADMANAGER_H
