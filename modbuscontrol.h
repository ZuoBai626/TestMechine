#ifndef MODBUSCONTROL_H
#define MODBUSCONTROL_H

#include <QObject>
#include <QModbusTcpClient>
#include <QModbusDataUnit>
#include <QModbusReply>
#include <QVariantMap>
#include <QTimer>
#include <QDebug>

// 寄存器高低字顺序枚举：用于32位浮点数或整数的寄存器排列方式
enum RegisterOrder {
    LOW_WORD_FIRST,   // 低字在前（地址低 -> 低16位）
    HIGH_WORD_FIRST   // 高字在前（地址低 -> 高16位）
};

// 定义一个PLC变量项的结构体
struct PlcItem {
    QString qmlKey;                   // 在QML中使用的键名（如"ExpForce1"）
    QModbusDataUnit::RegisterType type; // 寄存器类型（HoldingRegisters、Coils等）
    int address;                      // Modbus地址（对于Holding Register已除以2，即VD10000 -> 5000）
    int length;                       // 占用寄存器数（1=16位，2=32位）
    RegisterOrder floatOrder;         // 32位数据的高低字顺序
    bool isPolling = false;           // 是否需要周期性轮询（true=实时采集，false=仅写入后回读）
};

class ModbusControl : public QObject
{
    Q_OBJECT

signals:
    // 每完成一轮所有实时数据采集后发出，携带完整数据Map（含时间戳）
    void instantDataReady(const QVariantMap& data);

    // 写入线圈后回读校验结果，用于QML临时显示验证是否成功
    void coilVerificationResultSignal(const QVariant& resultValue);

    // 任意数据发生变化（主要用于写入操作后的QML界面刷新）
    void plcDataChanged();

    // PLC连接状态变化（true=已连接，false=断开）
    void connectionStatusChanged(bool isConnected);

public:
    explicit ModbusControl(QObject *parent = nullptr);
    ~ModbusControl();

    // 获取当前缓存的PLC数据Map（只读引用）
    const QVariantMap& plcData() const { return m_plcData; }

public slots:
    // 【外部调用】启动周期性轮询（实验开始时调用）
    void startPolling();

    // 【外部调用】停止周期性轮询（实验停止时调用）
    void stopPolling();

    // 【外部调用】重置时间戳计数器（实验开始时归零时间）
    void resetCycleCount();

    // 【外部调用】连接PLC（程序启动后由ThreadManager立即调用）
    void connectToPlc();

    // 【外部调用】断开PLC连接（程序退出时由ThreadManager调用）
    void disconnectFromPlc();

    // 【写入接口】由ThreadManager转发QML请求
    void Modbus_Coils_Write(const QString& qmlKey, int address, bool value);
    void Modbus_HoldRegisters_16_Write(const QString& qmlKey, int address, qint16 value);
    void Modbus_HoldRegisters_32_Write(const QString& qmlKey, int address, float value);

private slots:
    // Modbus客户端状态变化处理（如连接成功、断开、重连等）
    void onModbusStateChanged(int state);

    // 定时器触发：开始新一轮所有实时参数读取
    void read_All_Parameters_Slots();

    // 处理单个读取批次的回复
    void handleModbusReply(QModbusReply* reply, const QVector<PlcItem>& itemsInBatch);

    // 发送读取队列中的下一个批次请求
    void sendNextRequest();

private:
    // 初始化所有需要监控的PLC变量（包括轮询和非轮询项）
    void initializeReadItems();

    // 写入成功后自动回读验证，并更新本地缓存
    void verifyWriteAndLog(const QString& qmlKey, QModbusDataUnit::RegisterType type,
                           int address, int length, RegisterOrder floatOrder);

    // 数据解析辅助函数
    QVariant parseModbusData(const QModbusDataUnit& unit, const PlcItem& item);
    double parseUint16PairToFloat(quint16 low, quint16 high, RegisterOrder order);
    QPair<quint16, quint16> floatToUint16Pair(float value, RegisterOrder order);
    QPair<quint16, quint16> int32ToUint16Pair(qint32 value, RegisterOrder order);
    qint16 parseModbusInt16(const QModbusDataUnit& unit, int offset);

    // --- 成员变量 ---
    QModbusTcpClient* m_PLC = nullptr;                    // Modbus TCP客户端实例
    QTimer* m_readTimer = nullptr;                        // 轮询定时器（默认50ms，即20Hz）
    QVector<QVector<PlcItem>> m_requestQueue;             // 读取批次队列（当前设计为1个批次）
    int m_currentRequestIndex = -1;                       // 当前正在处理的批次索引
    bool m_isReading = false;                             // 是否正在进行一轮读取（防止重入）
    QVariantMap m_plcData;                                // 子线程维护的最新PLC数据缓存
    qint64 m_cycleCount = 0;                              // 轮询周期计数器，用于生成相对时间戳
};

#endif // MODBUSCONTROL_H
