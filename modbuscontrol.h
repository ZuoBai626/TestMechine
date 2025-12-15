#ifndef MODBUSCONTROL_H
#define MODBUSCONTROL_H

#include <QObject>
#include <QModbusTcpClient>
#include <QModbusDataUnit>
#include <QModbusReply>
#include <QVariantMap>
#include <QElapsedTimer>
#include <QTimer>
#include <QDebug>
#include <QThread>

// 寄存器高低位顺序枚举
enum RegisterOrder {
    LOW_WORD_FIRST,
    HIGH_WORD_FIRST
};

// 定义单个PLC读取项
struct PlcItem {
    QString qmlKey;
    QModbusDataUnit::RegisterType type;
    int address;
    int length;
    RegisterOrder floatOrder; // 浮点数解析顺序
    bool isPolling = false; // 🌟 关键新增: 是否需要周期性轮询，默认为 true
};

class ModbusControl : public QObject
{
    Q_OBJECT

signals:
    // [信号] 采集周期结束，发送所有数据和时间戳给主线程
    void instantDataReady(const QVariantMap& data);

    // [信号] 临时写入操作的回读校验结果
    void coilVerificationResultSignal(const QVariant& resultValue);

    // [信号] 通用的数据变更通知 (主要用于写入校验后的 QML 绑定刷新)
    void plcDataChanged();

    // [信号] 连接状态变更
    void connectionStatusChanged(bool isConnected);

    // [信号] 内部使用：通知 ModbusControl 安全停止定时器
    void stopPollingSignal();

public:
    explicit ModbusControl(QObject *parent = nullptr);
    ~ModbusControl();

    const QVariantMap& plcData() const { return m_plcData; }

public slots:
    // [槽] 初始化并连接PLC
    void connectAndInitialize();

    // [槽] 定时器触发，开始新一轮采集
    void read_All_Parameters_Slots();

    // [槽] 线程安全停止定时器 (在子线程中执行)
    void stopPolling();

    // 🌟 新增: 外部调用重置周期计数器，用于开始实验
    void resetCycleCount(); // <-- 新增槽函数

    // [槽] 写入接口 (由 ThreadManager 转发 QML 请求)
    void Modbus_Coils_Write(const QString& qmlKey, int address, bool value);
    void Modbus_HoldRegisters_16_Write(const QString& qmlKey, int address, qint16 value);
    void Modbus_HoldRegisters_32_Write(const QString& qmlKey, int address, float value);

private slots:
    void onModbusStateChanged(int state);
    void handleModbusReply(QModbusReply* reply, const QVector<PlcItem>& itemsInBatch);
    void sendNextRequest();

private:
    void initializeReadItems();

    // 写入后的回读验证逻辑
    void verifyWriteAndLog(const QString& qmlKey, QModbusDataUnit::RegisterType type,
                           int address, int length, RegisterOrder floatOrder);

    // 数据转换辅助函数
    QVariant parseModbusData(const QModbusDataUnit& unit, const PlcItem& item);
    float parseUint16PairToFloat(quint16 low, quint16 high, RegisterOrder order);
    QPair<quint16, quint16> floatToUint16Pair(float value, RegisterOrder order);
    QPair<quint16, quint16> int32ToUint16Pair(qint32 value, RegisterOrder order); // 新增 i32 转换
    qint16 parseModbusInt16(const QModbusDataUnit& unit, int offset); // 新增 i16 解析

    // --- 成员变量 ---
    QModbusTcpClient* m_PLC = nullptr;
    QTimer* m_readTimer = nullptr;
    QVector<QVector<PlcItem>> m_requestQueue;
    int m_currentRequestIndex = -1;
    bool m_isReading = false;
    QVariantMap m_plcData; // 子线程维护的数据 Map
    // QElapsedTimer m_elapsedTimer;
    // 🌟 替换为周期计数器
    qint64 m_cycleCount = 0; // <-- 新增周期计数器
};

#endif // MODBUSCONTROL_H
