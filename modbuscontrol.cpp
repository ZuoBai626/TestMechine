#include "modbuscontrol.h"
#include <QCoreApplication>

// === 配置参数 ===
const QString PLC_IP = "192.168.1.130";     // PLC IP地址
const int PLC_PORT = 502;                 // Modbus TCP标准端口
const int SERVER_ID = 1;                  // 从站ID
const int POLL_INTERVAL_MS = 50;          // 轮询间隔：50ms -> 20Hz

// === 数据转换辅助函数 ===

double ModbusControl::parseUint16PairToFloat(quint16 low, quint16 high, RegisterOrder order)
{
    quint32 temp = (order == HIGH_WORD_FIRST)
    ? (static_cast<quint32>(high) << 16 | low)
    : (static_cast<quint32>(low) << 16 | high);
    float f;
    memcpy(&f, &temp, sizeof(f));
    return static_cast<double>(f);
}

QPair<quint16, quint16> ModbusControl::floatToUint16Pair(float value, RegisterOrder order)
{
    quint32 temp;
    memcpy(&temp, &value, sizeof(temp));
    quint16 low = temp & 0xFFFF;
    quint16 high = (temp >> 16) & 0xFFFF;
    return (order == HIGH_WORD_FIRST) ? qMakePair(high, low) : qMakePair(low, high);
}

QPair<quint16, quint16> ModbusControl::int32ToUint16Pair(qint32 value, RegisterOrder order)
{
    quint32 temp = static_cast<quint32>(value);
    quint16 low = temp & 0xFFFF;
    quint16 high = (temp >> 16) & 0xFFFF;
    return (order == HIGH_WORD_FIRST) ? qMakePair(high, low) : qMakePair(low, high);
}

qint16 ModbusControl::parseModbusInt16(const QModbusDataUnit& unit, int offset)
{
    return static_cast<qint16>(unit.value(offset));
}

void ModbusControl::handleInitialReply(QModbusReply *reply)
{
    if (reply->error() == QModbusDevice::NoError) {
        const QModbusDataUnit unit = reply->result();
        // 更新轮询变量（假设当前批次是轮询批次）
        for (int i = 0; i < unit.valueCount(); ++i) {
            // 简单遍历所有已注册项匹配更新（效率足够）
            for (const auto& queues : {m_requestQueue, m_initialReadQueue}) {
                for (const auto& batch : queues) {
                    for (const PlcItem& item : batch) {
                        int offset = item.address - unit.startAddress();
                        if (offset >= 0 && offset + item.length <= unit.valueCount()) {
                            QVariant val = parseModbusData(unit, item);
                            if (val.isValid()) {
                                m_plcData[item.qmlKey] = val;
                            }
                        }
                    }
                }
            }
        }
    } else if (reply->error() == QModbusDevice::ProtocolError) {
        // 输出具体异常码，帮助调试
        quint8 exceptionCode = reply->rawResult().exceptionCode();
        qWarning() << "ModbusControl: 初始读取协议异常，异常码:" << Qt::hex << exceptionCode
                   << "(常见: 0x02=非法数据地址, 0x03=非法数据值)";
    } else {
        qWarning() << "ModbusControl: 初始读取错误:" << reply->errorString();
    }

    reply->deleteLater();

    // 轮询批次读完后，继续读取非轮询变量
    readNonPollingItemsSequentially();
}

void ModbusControl::readNonPollingItemsSequentially()
{
    // 收集所有非轮询项
    static QVector<PlcItem> nonPollingItems;
    nonPollingItems.clear();

    // for (const auto& batch : m_initialReadQueue) {
    //     for (const PlcItem& item : batch) {
    //         if (!item.isPolling) {
    //             nonPollingItems.append(item);
    //         }
    //     }
    // }
    for (auto batchIt = m_initialReadQueue.cbegin(); batchIt != m_initialReadQueue.cend(); ++batchIt) {
        const auto& batch = *batchIt;
        // 内层遍历batch（const迭代器）
        for (auto itemIt = batch.cbegin(); itemIt != batch.cend(); ++itemIt) {
            const PlcItem& item = *itemIt;
            if (!item.isPolling) {
                nonPollingItems.append(item);
            }
        }
    }

    if (nonPollingItems.isEmpty()) {
        finishInitialRead();
        return;
    }

    // 递归依次读取
    readNextNonPollingItem(nonPollingItems, 0);
}

void ModbusControl::readNextNonPollingItem(const QVector<PlcItem> &items, int index)
{
    if (index >= items.size()) {
        finishInitialRead();
        return;
    }

    const PlcItem& item = items[index];
    QModbusDataUnit readUnit(item.type, item.address, item.length);

    if (auto* reply = m_PLC->sendReadRequest(readUnit, SERVER_ID)) {
        connect(reply, &QModbusReply::finished, this, [this, reply, items, index, item]() {
            if (reply->error() == QModbusDevice::NoError) {
                const QModbusDataUnit unit = reply->result();
                QVariant val = parseModbusData(unit, item);
                if (val.isValid()) {
                    m_plcData[item.qmlKey] = val;
                }
            } else {
                qWarning() << "ModbusControl: 初始读取非轮询项失败:" << item.qmlKey << reply->errorString();
            }
            reply->deleteLater();

            // 读取下一个
            readNextNonPollingItem(items, index + 1);
        });
    } else {
        qWarning() << "ModbusControl: 非轮询项请求发送失败:" << item.qmlKey;
        readNextNonPollingItem(items, index + 1);
    }
}

void ModbusControl::finishInitialRead()
{
    m_isReading = false;
    m_plcData["timestampSeconds"] = 0.0;

    emit plcDataChanged();          // 非轮询变量依赖此信号
    emit instantDataReady(m_plcData); // 轮询变量和图表依赖此信号

    qDebug() << "ModbusControl: 初始读取完成，所有变量已更新到QML";
}

QVariant ModbusControl::parseModbusData(const QModbusDataUnit& unit, const PlcItem& item)
{
    int offset = item.address - unit.startAddress();
    if (offset < 0 || offset + item.length > unit.valueCount()) return QVariant();

    if (item.type == QModbusDataUnit::Coils || item.type == QModbusDataUnit::DiscreteInputs) {
        return unit.value(offset);
    }
    if (item.length == 2) {
        quint16 regLow  = unit.value(offset + (item.floatOrder == HIGH_WORD_FIRST ? 1 : 0));
        quint16 regHigh = unit.value(offset + (item.floatOrder == HIGH_WORD_FIRST ? 0 : 1));
        return parseUint16PairToFloat(regLow, regHigh, item.floatOrder);
    }
    return parseModbusInt16(unit, offset);
}

// === 类实现 ===

ModbusControl::ModbusControl(QObject *parent) : QObject(parent)
{
    m_PLC = new QModbusTcpClient(this);
    m_readTimer = new QTimer(this);
    m_readTimer->setInterval(POLL_INTERVAL_MS);

    connect(m_readTimer, &QTimer::timeout, this, &ModbusControl::read_All_Parameters_Slots);

    initializeReadItems();  // 初始化变量列表和数据占位

    // 【关键新增】连接信号到槽，确保连接成功后自动触发初始读取
    connect(this, &ModbusControl::initialReadRequested,
            this, &ModbusControl::performInitialRead,
            Qt::QueuedConnection);  // 确保跨线程安全（虽然当前都在子线程，但更规范）

}

ModbusControl::~ModbusControl()
{
    // 析构时确保断开连接（安全保险）
    if (m_PLC && m_PLC->state() == QModbusDevice::ConnectedState) {
        m_PLC->disconnectDevice();
    }
}

void ModbusControl::connectToPlc()
{
    m_PLC->setConnectionParameter(QModbusDevice::NetworkAddressParameter, PLC_IP);
    m_PLC->setConnectionParameter(QModbusDevice::NetworkPortParameter, PLC_PORT);

    // 连接状态变化信号（只连接一次）
    connect(m_PLC, &QModbusClient::stateChanged, this, &ModbusControl::onModbusStateChanged, Qt::UniqueConnection);

    if (!m_PLC->connectDevice()) {
        qWarning() << "ModbusControl: 初始连接PLC失败:" << m_PLC->errorString();
    } else {
        qDebug() << "ModbusControl: 正在尝试连接PLC...";
    }
}

void ModbusControl::disconnectFromPlc()
{
    stopPolling();  // 先停止轮询

    if (m_PLC && m_PLC->state() == QModbusDevice::ConnectedState) {
        m_PLC->disconnectDevice();
        qDebug() << "ModbusControl: PLC连接已主动断开（程序退出）。";
    }
}

void ModbusControl::performInitialRead()
{
    if (m_isReading || m_PLC->state() != QModbusDevice::ConnectedState) {
        qWarning() << "ModbusControl: 初始读取失败 - 正在读取或未连接";
        return;
    }

    qDebug() << "ModbusControl: 开始执行初始读取（分批次，避免地址间隙异常）";

    m_isReading = true;

    // 步骤1: 先读取轮询批次（与正常轮询相同）
    if (!m_requestQueue.isEmpty()) {
        const QVector<PlcItem>& pollingBatch = m_requestQueue[0];

        int startAddr = pollingBatch.first().address;
        int count = pollingBatch.last().address + pollingBatch.last().length - startAddr;

        QModbusDataUnit readUnit(pollingBatch.first().type, startAddr, count);

        if (auto* reply = m_PLC->sendReadRequest(readUnit, SERVER_ID)) {
            connect(reply, &QModbusReply::finished, this, [this, reply]() {
                handleInitialReply(reply);
            });
        } else {
            qWarning() << "ModbusControl: 初始读取轮询批次请求发送失败";
            m_isReading = false;
        }
    } else {
        // 如果没有轮询批次，直接处理非轮询变量
        readNonPollingItemsSequentially();
    }
}

void ModbusControl::startPolling()
{
    if (m_readTimer->isActive()) return;

    resetCycleCount();  // 开始轮询时归零时间戳
    m_readTimer->start();
    qDebug() << "ModbusControl: 开始20Hz周期性轮询。";
}

void ModbusControl::stopPolling()
{
    if (m_readTimer->isActive()) {
        m_readTimer->stop();
        qDebug() << "ModbusControl: 轮询定时器已停止。";
    }
}

void ModbusControl::resetCycleCount()
{
    m_cycleCount = 0;
    qDebug() << "ModbusControl: 时间戳计数器已重置为0。";
}

void ModbusControl::onModbusStateChanged(int state)
{
    bool connected = (state == QModbusDevice::ConnectedState);
    emit connectionStatusChanged(connected);

    if (connected) {
        qDebug() << "ModbusControl: PLC已成功连接。";
        emit initialReadRequested();  // 触发初始读取（包含所有变量）
    } else {
        qDebug() << "ModbusControl: PLC连接断开。";
        stopPolling();  // 连接断开时自动停止轮询
    }
}

void ModbusControl::initializeReadItems()
{
    RegisterOrder order = HIGH_WORD_FIRST;
    QVector<PlcItem> allItems;

    // === 实时轮询变量（实验核心数据）===
    allItems.append({"ExpForce1", QModbusDataUnit::HoldingRegisters, 10000/2, 2, order, true});
    allItems.append({"ExpForce2", QModbusDataUnit::HoldingRegisters, 10004/2, 2, order, true});
    allItems.append({"ExpForce3", QModbusDataUnit::HoldingRegisters, 10008/2, 2, order, true});
    allItems.append({"Displacement1", QModbusDataUnit::HoldingRegisters, 10016/2, 2, order, true});
    allItems.append({"Displacement2", QModbusDataUnit::HoldingRegisters, 10020/2, 2, order, true});
    allItems.append({"Displacement3", QModbusDataUnit::HoldingRegisters, 10024/2, 2, order, true});

    // // === 非轮询变量（仅在写入后回读）===
    // // 线圈起始位置 9000
    allItems.append({"M1.0_端肋1_位置设零", QModbusDataUnit::Coils, 9008, 1, order, false});
    allItems.append({"M1.1_中肋1_位置设零", QModbusDataUnit::Coils, 9009, 1, order, false});
    allItems.append({"M1.2_端肋2_位置设零", QModbusDataUnit::Coils, 9010, 1, order, false});
    // allItems.append({"M1.3_伺服_位置设零", QModbusDataUnit::Coils, 9011, 1, order, false});

    allItems.append({"M1.4_端肋1_压力设零", QModbusDataUnit::Coils, 9012, 1, order, false});
    allItems.append({"M1.5_中肋1_压力设零", QModbusDataUnit::Coils, 9013, 1, order, false});
    allItems.append({"M1.6_端肋2_压力设零", QModbusDataUnit::Coils, 9014, 1, order, false});
    // allItems.append({"M1.7_伺服_压力设零", QModbusDataUnit::Coils, 9015, 1, order, false});

    allItems.append({"M2.0_端肋1_速度启动", QModbusDataUnit::Coils, 9016, 1, order, false});
    allItems.append({"M2.1_中肋1_速度启动", QModbusDataUnit::Coils, 9017, 1, order, false});
    allItems.append({"M2.2_端肋2_速度启动", QModbusDataUnit::Coils, 9018, 1, order, false});
    // allItems.append({"M2.3_伺服_速度启动", QModbusDataUnit::Coils, 9019, 1, order, false});

    allItems.append({"M2.4_端肋1_位置启动", QModbusDataUnit::Coils, 9020, 1, order, false});
    allItems.append({"M2.5_中肋1_位置启动", QModbusDataUnit::Coils, 9021, 1, order, false});
    allItems.append({"M2.6_端肋2_位置启动", QModbusDataUnit::Coils, 9022, 1, order, false});
    // allItems.append({"M2.7_伺服_位置启动", QModbusDataUnit::Coils, 9023 , 1, order, false});

    allItems.append({"M3.0_端肋1_停止", QModbusDataUnit::Coils, 9024, 1, order, false});
    allItems.append({"M3.1_中肋1_停止", QModbusDataUnit::Coils, 9025, 1, order, false});
    allItems.append({"M3.2_端肋2_停止", QModbusDataUnit::Coils, 9026, 1, order, false});
    // allItems.append({"M3.3_伺服_停止", QModbusDataUnit::Coils, 9027, 1, order, false});

    allItems.append({"M3.4_三端_停止", QModbusDataUnit::Coils, 9028, 1, order, false});
    allItems.append({"M3.5_三端_启动", QModbusDataUnit::Coils, 9029, 1, order, false});
    allItems.append({"M3.6_三端_模式", QModbusDataUnit::Coils, 9030, 1, order, false});
    // allItems.append({"M3.6_三端_模式", QModbusDataUnit::Coils, 9031, 1, order, false});

    allItems.append({"M4.0_端肋1_回零启动", QModbusDataUnit::Coils, 9032, 1, order, false});
    allItems.append({"M4.1_中肋1_回零启动", QModbusDataUnit::Coils, 9033, 1, order, false});
    allItems.append({"M4.2_端肋2_回零启动", QModbusDataUnit::Coils, 9034, 1, order, false});
    // allItems.append({"M4.3_伺服_回零启动", QModbusDataUnit::Coils, 9035, 1, order, false});

    allItems.append({"M4.4_端肋1_方向", QModbusDataUnit::Coils, 9036, 1, order, false});
    allItems.append({"M4.5_中肋1_方向", QModbusDataUnit::Coils, 9037, 1, order, false});
    allItems.append({"M4.6_端肋2_方向", QModbusDataUnit::Coils, 9038, 1, order, false});
    // allItems.append({"M4.7_伺服_方向", QModbusDataUnit::Coils, 9039, 1, order, false});

    allItems.append({"M5.0_端肋1_标定1", QModbusDataUnit::Coils, 9040, 1, order, false});
    allItems.append({"M5.1_中肋1_标定1", QModbusDataUnit::Coils, 9041, 1, order, false});
    allItems.append({"M5.2_端肋2_标定1", QModbusDataUnit::Coils, 9042, 1, order, false});
    // allItems.append({"M5.3_伺服_标定1", QModbusDataUnit::Coils, 9043, 1, order, false});

    allItems.append({"M5.4_端肋1_标定2", QModbusDataUnit::Coils, 9044, 1, order, false});
    allItems.append({"M5.5_中肋1_标定2", QModbusDataUnit::Coils, 9045, 1, order, false});
    allItems.append({"M5.6_端肋2_标定2", QModbusDataUnit::Coils, 9046, 1, order, false});
    // allItems.append({"M5.7_伺服_标定2", QModbusDataUnit::Coils, 9047, 1, order, false});

    allItems.append({"M6.0_端肋1_标定3", QModbusDataUnit::Coils, 9048, 1, order, false});
    allItems.append({"M6.1_中肋1_标定3", QModbusDataUnit::Coils, 9049, 1, order, false});
    allItems.append({"M6.2_端肋2_标定3", QModbusDataUnit::Coils, 9050, 1, order, false});
    // allItems.append({"M6.3_伺服_标定3", QModbusDataUnit::Coils, 9051, 1, order, false});

    allItems.append({"M6.4_端肋1_标定4", QModbusDataUnit::Coils, 9052, 1, order, false});
    allItems.append({"M6.5_中肋1_标定4", QModbusDataUnit::Coils, 9053, 1, order, false});
    allItems.append({"M6.6_端肋2_标定4", QModbusDataUnit::Coils, 9054, 1, order, false});
    // allItems.append({"M6.7_伺服_标定4", QModbusDataUnit::Coils, 9055, 1, order, false});

    allItems.append({"M7.0_端肋1_标定5", QModbusDataUnit::Coils, 9056, 1, order, false});
    allItems.append({"M7.1_中肋1_标定5", QModbusDataUnit::Coils, 9057, 1, order, false});
    allItems.append({"M7.2_端肋2_标定5", QModbusDataUnit::Coils, 9058, 1, order, false});
    // allItems.append({"M7.3_伺服_标定5", QModbusDataUnit::Coils, 9059, 1, order, false});

    allItems.append({"M8.0_端肋1_校准", QModbusDataUnit::Coils, 9064, 1, order, false});
    allItems.append({"M8.1_中肋1_校准", QModbusDataUnit::Coils, 9065, 1, order, false});
    allItems.append({"M8.2_端肋2_校准", QModbusDataUnit::Coils, 9066, 1, order, false});
    // allItems.append({"M8.3_伺服_校准", QModbusDataUnit::Coils, 9067, 1, order, false});



    allItems.append({"Real_端肋力1_U", QModbusDataUnit::HoldingRegisters, 2000/2, 2, order, false});
    allItems.append({"Real_中肋力1_U", QModbusDataUnit::HoldingRegisters, 2004/2, 2, order, false});
    allItems.append({"Real_端肋力2_U", QModbusDataUnit::HoldingRegisters, 2008/2, 2, order, false});
    // allItems.append({"Real_伺服力1_U", QModbusDataUnit::HoldingRegisters, 2012/2, 2, order, false});

    allItems.append({"Real_端肋力1_L", QModbusDataUnit::HoldingRegisters, 2100/2, 2, order, false});
    allItems.append({"Real_中肋力1_L", QModbusDataUnit::HoldingRegisters, 2104/2, 2, order, false});
    allItems.append({"Real_端肋力2_L", QModbusDataUnit::HoldingRegisters, 2108/2, 2, order, false});
    // allItems.append({"Real_伺服力1_L", QModbusDataUnit::HoldingRegisters, 2112/2, 2, order, false});

    allItems.append({"Real_端肋设定力1_I", QModbusDataUnit::HoldingRegisters, 2500/2, 2, order, false});
    allItems.append({"Real_中肋设定力1_I", QModbusDataUnit::HoldingRegisters, 2504/2, 2, order, false});
    allItems.append({"Real_端肋设定力2_I", QModbusDataUnit::HoldingRegisters, 2508/2, 2, order, false});
    // allItems.append({"Real_伺服设定力1_I", QModbusDataUnit::HoldingRegisters, 2512/2, 2, order, false});

    allItems.append({"Real_端肋设定位置1_I", QModbusDataUnit::HoldingRegisters, 5300/2, 2, order, false});
    allItems.append({"Real_中肋设定位置1_I", QModbusDataUnit::HoldingRegisters, 5304/2, 2, order, false});
    allItems.append({"Real_端肋设定位置2_I", QModbusDataUnit::HoldingRegisters, 5308/2, 2, order, false});
    // allItems.append({"Real_伺服设定位置1_I", QModbusDataUnit::HoldingRegisters, 5312/2, 2, order, false});

    allItems.append({"Real_端肋速度1_I", QModbusDataUnit::HoldingRegisters, 7000/2, 2, order, false});
    allItems.append({"Real_中肋速度1_I", QModbusDataUnit::HoldingRegisters, 7004/2, 2, order, false});
    allItems.append({"Real_端肋速度2_I", QModbusDataUnit::HoldingRegisters, 7008/2, 2, order, false});
    allItems.append({"Real_伺服速度1_I", QModbusDataUnit::HoldingRegisters, 7012/2, 2, order, false});
    allItems.append({"Real_三缸速度1_I", QModbusDataUnit::HoldingRegisters, 7016/2, 2, order, false});

    // 未绑定
    allItems.append({"Dint_端肋加减时间1_I", QModbusDataUnit::HoldingRegisters, 4200/2, 2, order, false});
    allItems.append({"Dint_中肋加减时间1_I", QModbusDataUnit::HoldingRegisters, 4204/2, 2, order, false});
    allItems.append({"Dint_端肋加减时间2_I", QModbusDataUnit::HoldingRegisters, 4208/2, 2, order, false});
    // allItems.append({"Dint_伺服加减时间1_I", QModbusDataUnit::HoldingRegisters, 4212/2, 2, order, false});

    // 标定相关内容
    allItems.append({"Real_端肋标定位移1_I", QModbusDataUnit::HoldingRegisters, 4300/2, 2, order, false});
    allItems.append({"Real_中肋标定位移1_I", QModbusDataUnit::HoldingRegisters, 4304/2, 2, order, false});
    allItems.append({"Real_端肋标定位移2_I", QModbusDataUnit::HoldingRegisters, 4308/2, 2, order, false});
    // allItems.append({"Real_伺服标定位移1_I", QModbusDataUnit::HoldingRegisters, 4312/2, 2, order, false});

    allItems.append({"Real_端肋一标力1_I", QModbusDataUnit::HoldingRegisters, 8100/2, 2, order, false});
    allItems.append({"Real_中肋一标力1_I", QModbusDataUnit::HoldingRegisters, 8104/2, 2, order, false});
    allItems.append({"Real_端肋一标力2_I", QModbusDataUnit::HoldingRegisters, 8108/2, 2, order, false});
    allItems.append({"Real_伺服一标力1_I", QModbusDataUnit::HoldingRegisters, 8112/2, 2, order, false});

    allItems.append({"Real_端肋二标力1_I", QModbusDataUnit::HoldingRegisters, 8120/2, 2, order, false});
    allItems.append({"Real_中肋二标力1_I", QModbusDataUnit::HoldingRegisters, 8124/2, 2, order, false});
    allItems.append({"Real_端肋二标力2_I", QModbusDataUnit::HoldingRegisters, 8128/2, 2, order, false});
    allItems.append({"Real_伺服二标力1_I", QModbusDataUnit::HoldingRegisters, 8132/2, 2, order, false});

    allItems.append({"Real_端肋三标力1_I", QModbusDataUnit::HoldingRegisters, 8140/2, 2, order, false});
    allItems.append({"Real_中肋三标力1_I", QModbusDataUnit::HoldingRegisters, 8144/2, 2, order, false});
    allItems.append({"Real_端肋三标力2_I", QModbusDataUnit::HoldingRegisters, 8148/2, 2, order, false});
    allItems.append({"Real_伺服三标力1_I", QModbusDataUnit::HoldingRegisters, 8152/2, 2, order, false});

    allItems.append({"Real_端肋四标力1_I", QModbusDataUnit::HoldingRegisters, 8160/2, 2, order, false});
    allItems.append({"Real_中肋四标力1_I", QModbusDataUnit::HoldingRegisters, 8164/2, 2, order, false});
    allItems.append({"Real_端肋四标力2_I", QModbusDataUnit::HoldingRegisters, 8168/2, 2, order, false});
    allItems.append({"Real_伺服四标力1_I", QModbusDataUnit::HoldingRegisters, 8172/2, 2, order, false});

    allItems.append({"Real_端肋五标力1_I", QModbusDataUnit::HoldingRegisters, 8180/2, 2, order, false});
    allItems.append({"Real_中肋五标力1_I", QModbusDataUnit::HoldingRegisters, 8184/2, 2, order, false});
    allItems.append({"Real_端肋五标力2_I", QModbusDataUnit::HoldingRegisters, 8188/2, 2, order, false});
    allItems.append({"Real_伺服五标力1_I", QModbusDataUnit::HoldingRegisters, 8192/2, 2, order, false});













    // 清空队列
    m_requestQueue.clear();          // 轮询批次
    m_initialReadQueue.clear();      // 初始读取批次

    QVector<PlcItem> pollingBatch;   // 轮询专用
    QVector<PlcItem> initialBatch;   // 初始读取专用（包含所有）

    for (const auto& item : allItems) {
        // 为所有变量预置初始值（QML绑定需要）
        if (item.type == QModbusDataUnit::Coils || item.type == QModbusDataUnit::DiscreteInputs) {
            m_plcData.insert(item.qmlKey, false);
        } else if (item.length == 2) {
            m_plcData.insert(item.qmlKey, 0.0);
        } else {
            m_plcData.insert(item.qmlKey, 0);
        }

        // 加入初始读取批次（所有变量）
        initialBatch.append(item);

        // 仅轮询变量加入轮询批次
        if (item.isPolling) {
            pollingBatch.append(item);
        }
    }

    // 构建队列
    if (!pollingBatch.isEmpty()) {
        m_requestQueue.append(pollingBatch);
    }
    if (!initialBatch.isEmpty()) {
        m_initialReadQueue.append(initialBatch);  // 包含所有变量
    }

    m_plcData.insert("timestampSeconds", 0.0);
}

void ModbusControl::read_All_Parameters_Slots()
{
    if (m_isReading || m_PLC->state() != QModbusDevice::ConnectedState) return;

    m_isReading = true;
    m_currentRequestIndex = 0;
    sendNextRequest();
}

void ModbusControl::sendNextRequest()
{
    if (m_currentRequestIndex >= m_requestQueue.size()) {
        // 一轮读取完成
        m_isReading = false;

        qreal timestampSeconds = static_cast<qreal>(m_cycleCount * POLL_INTERVAL_MS) / 1000.0;
        m_plcData["timestampSeconds"] = timestampSeconds;

        emit instantDataReady(m_plcData);  // 发送给主线程和CSV记录器
        m_cycleCount++;
        return;
    }

    const QVector<PlcItem>& batch = m_requestQueue[m_currentRequestIndex];
    if (batch.isEmpty()) {
        m_currentRequestIndex++;
        sendNextRequest();
        return;
    }

    int startAddr = batch.first().address;
    int count = batch.last().address + batch.last().length - startAddr;

    QModbusDataUnit readUnit(batch.first().type, startAddr, count);

    if (auto* reply = m_PLC->sendReadRequest(readUnit, SERVER_ID)) {
        if (!reply->isFinished()) {
            connect(reply, &QModbusReply::finished, this, [this, reply, batch]() {
                handleModbusReply(reply, batch);
            });
        } else {
            reply->deleteLater();
            m_currentRequestIndex++;
            sendNextRequest();
        }
    } else {
        qWarning() << "ModbusControl: 发送读取请求失败";
        m_currentRequestIndex++;
        sendNextRequest();
    }
}

void ModbusControl::handleModbusReply(QModbusReply* reply, const QVector<PlcItem>& itemsInBatch)
{
    if (reply->error() == QModbusDevice::NoError) {
        const QModbusDataUnit unit = reply->result();
        for (const PlcItem& item : itemsInBatch) {
            QVariant val = parseModbusData(unit, item);
            if (val.isValid() && m_plcData.value(item.qmlKey) != val) {
                m_plcData[item.qmlKey] = val;
            }
        }
    } else {
        qWarning() << "ModbusControl: 读取错误:" << reply->errorString();
    }

    reply->deleteLater();
    m_currentRequestIndex++;
    sendNextRequest();
}

// === 写入接口实现（完整保留原逻辑）===

void ModbusControl::Modbus_Coils_Write(const QString& qmlKey, int address, bool value)
{
    QModbusDataUnit writeUnit(QModbusDataUnit::Coils, address, 1);
    writeUnit.setValue(0, value);

    if (auto* reply = m_PLC->sendWriteRequest(writeUnit, SERVER_ID)) {
        connect(reply, &QModbusReply::finished, this, [this, reply, qmlKey, address]() {
            if (reply->error() == QModbusDevice::NoError) {
                qDebug() << "ModbusControl: 线圈写入成功，开始回读校验:" << qmlKey;
                verifyWriteAndLog(qmlKey, QModbusDataUnit::Coils, address, 1, LOW_WORD_FIRST);
            } else {
                qWarning() << "ModbusControl: 线圈写入失败:" << reply->errorString();
                emit coilVerificationResultSignal(QVariant());
            }
            reply->deleteLater();
        });
    }
}

void ModbusControl::Modbus_HoldRegisters_16_Write(const QString& qmlKey, int address, qint16 value)
{
    QModbusDataUnit writeUnit(QModbusDataUnit::HoldingRegisters, address, 1);
    writeUnit.setValue(0, static_cast<quint16>(value));

    if (auto* reply = m_PLC->sendWriteRequest(writeUnit, SERVER_ID)) {
        connect(reply, &QModbusReply::finished, this, [this, reply, qmlKey, address]() {
            if (reply->error() == QModbusDevice::NoError) {
                qDebug() << "ModbusControl: 16位寄存器写入成功，开始回读校验:" << qmlKey;
                verifyWriteAndLog(qmlKey, QModbusDataUnit::HoldingRegisters, address, 1, LOW_WORD_FIRST);
            } else {
                qWarning() << "ModbusControl: 16位寄存器写入失败:" << reply->errorString();
            }
            reply->deleteLater();
        });
    }
}

void ModbusControl::Modbus_HoldRegisters_32_Write(const QString& qmlKey, int address, float value)
{
    RegisterOrder order = HIGH_WORD_FIRST;
    auto regs = floatToUint16Pair(value, order);
    QModbusDataUnit writeUnit(QModbusDataUnit::HoldingRegisters, address, 2);
    writeUnit.setValue(0, regs.first);
    writeUnit.setValue(1, regs.second);

    if (auto* reply = m_PLC->sendWriteRequest(writeUnit, SERVER_ID)) {
        connect(reply, &QModbusReply::finished, this, [this, reply, qmlKey, address, order]() {
            if (reply->error() == QModbusDevice::NoError) {
                qDebug() << "ModbusControl: 32位寄存器写入成功，开始回读校验:" << qmlKey;
                verifyWriteAndLog(qmlKey, QModbusDataUnit::HoldingRegisters, address, 2, order);
            } else {
                qWarning() << "ModbusControl: 32位寄存器写入失败:" << reply->errorString();
            }
            reply->deleteLater();
        });
    }
}

void ModbusControl::verifyWriteAndLog(const QString& qmlKey, QModbusDataUnit::RegisterType type,
                                      int address, int length, RegisterOrder floatOrder)
{
    QModbusDataUnit readUnit(type, address, length);
    if (auto* reply = m_PLC->sendReadRequest(readUnit, SERVER_ID)) {
        connect(reply, &QModbusReply::finished, this, [this, reply, qmlKey, type, floatOrder, length]() {
            QVariant verifiedValue;
            if (reply->error() == QModbusDevice::NoError) {
                const auto& res = reply->result();
                if (type == QModbusDataUnit::Coils) {
                    verifiedValue = res.value(0);
                    emit coilVerificationResultSignal(verifiedValue);
                } else if (length == 2) {
                    quint16 reg1 = res.value(0);
                    quint16 reg2 = res.value(1);
                    verifiedValue = (floatOrder == HIGH_WORD_FIRST)
                                        ? parseUint16PairToFloat(reg2, reg1, floatOrder)
                                        : parseUint16PairToFloat(reg1, reg2, floatOrder);
                } else if (length == 1) {
                    verifiedValue = parseModbusInt16(res, 0);
                }

                if (verifiedValue.isValid()) {
                    m_plcData[qmlKey] = verifiedValue;
                    emit plcDataChanged();
                    qDebug() << "ModbusControl: 回读校验成功:" << qmlKey << "=" << verifiedValue;
                }
            } else {
                qWarning() << "ModbusControl: 回读校验失败:" << reply->errorString();
                if (type == QModbusDataUnit::Coils) emit coilVerificationResultSignal(QVariant());
            }
            reply->deleteLater();
        });
    }
}
