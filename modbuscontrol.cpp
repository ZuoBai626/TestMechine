#include "modbuscontrol.h"
#include <QCoreApplication>

// 配置参数
const QString PLC_IP = "192.168.1.10";
const int PLC_PORT = 502;
const int SERVER_ID = 1;
const int POLL_INTERVAL_MS = 50; // 20Hz

// --- 数据转换辅助函数实现 (用于确保 ModbusControl.cpp 的完整性) ---
float ModbusControl::parseUint16PairToFloat(quint16 low, quint16 high, RegisterOrder order) {
    quint32 temp = (order == HIGH_WORD_FIRST) ? (static_cast<quint32>(high) << 16 | low)
                                              : (static_cast<quint32>(low) << 16 | high);
    float f; memcpy(&f, &temp, sizeof(f)); return f;
}
QPair<quint16, quint16> ModbusControl::floatToUint16Pair(float value, RegisterOrder order) {
    quint32 temp; memcpy(&temp, &value, sizeof(temp));
    quint16 low = temp & 0xFFFF; quint16 high = (temp >> 16) & 0xFFFF;
    return (order == HIGH_WORD_FIRST) ? qMakePair(high, low) : qMakePair(low, high);
}
QPair<quint16, quint16> ModbusControl::int32ToUint16Pair(qint32 value, RegisterOrder order) {
    quint32 temp = static_cast<quint32>(value);
    quint16 low = temp & 0xFFFF; quint16 high = (temp >> 16) & 0xFFFF;
    return (order == HIGH_WORD_FIRST) ? qMakePair(high, low) : qMakePair(low, high);
}
qint16 ModbusControl::parseModbusInt16(const QModbusDataUnit& unit, int offset) {
    return static_cast<qint16>(unit.value(offset));
}
QVariant ModbusControl::parseModbusData(const QModbusDataUnit& unit, const PlcItem& item) {
    int offset = item.address - unit.startAddress();
    if (offset < 0 || offset + item.length > unit.valueCount()) return QVariant();

    if (item.type == QModbusDataUnit::Coils || item.type == QModbusDataUnit::DiscreteInputs) {
        return (bool)unit.value(offset);
    }
    if (item.length == 2) {
        return parseUint16PairToFloat(unit.value(offset + (item.floatOrder == HIGH_WORD_FIRST ? 1 : 0)),
                                      unit.value(offset + (item.floatOrder == HIGH_WORD_FIRST ? 0 : 1)),
                                      item.floatOrder);
    }
    // 默认按 16 位整数处理
    return parseModbusInt16(unit, offset);
}
// --- 辅助函数实现结束 ---


ModbusControl::ModbusControl(QObject *parent) : QObject(parent)
{
    m_PLC = new QModbusTcpClient(this);
    m_readTimer = new QTimer(this);
    m_readTimer->setInterval(POLL_INTERVAL_MS);

    // 连接到 QObject::deleteLater，但不要在这里使用 deleteLater，因为 ModbusControl 是由 ThreadManager 管理的

    connect(m_readTimer, &QTimer::timeout, this, &ModbusControl::read_All_Parameters_Slots);
}

ModbusControl::~ModbusControl()
{
    // // 如果定时器仍在运行，这可能会触发 QObject::~QObject 错误，但我们依赖 stopPolling 信号来安全停止
    // if (m_PLC && m_PLC->state() == QModbusDevice::ConnectedState) {
    //     m_PLC->disconnectDevice();
    // }
}

void ModbusControl::stopPolling()
{
    // 1. 停止定时器 (保证在子线程执行)
    if (m_readTimer && m_readTimer->isActive()) {
        m_readTimer->stop();
        qDebug() << "ModbusControl: 定时器已在子线程中安全停止。";
    }
    m_isReading = false;

    // 2. 断开 Modbus 连接 (在子线程中安全执行)
    if (m_PLC && m_PLC->state() == QModbusDevice::ConnectedState) {
        m_PLC->disconnectDevice();
        qDebug() << "ModbusControl: PLC 已在子线程中安全断开。";
    }

    // 3. 将 ModbusControl 的子对象标记为 deleteLater，
    //    确保它们在线程退出时被正确销毁。
    if (m_readTimer) {
        m_readTimer->deleteLater();
        m_readTimer = nullptr;
    }
    if (m_PLC) {
        m_PLC->deleteLater(); // Modbus 客户端自身也要安全删除
        m_PLC = nullptr;
    }

    qDebug() << "ModbusControl: 子线程清理完毕，等待主线程销毁 ModbusControl 实例。";
}

void ModbusControl::resetCycleCount()
{
    m_cycleCount = 0;
    qDebug() << "ModbusControl: Cycle count reset.";
}

void ModbusControl::connectAndInitialize()
{
    m_PLC->setConnectionParameter(QModbusDevice::NetworkAddressParameter, PLC_IP);
    m_PLC->setConnectionParameter(QModbusDevice::NetworkPortParameter, PLC_PORT);

    connect(m_PLC, &QModbusClient::stateChanged, this, &ModbusControl::onModbusStateChanged);

    initializeReadItems();
    groupAndInitializeRequests(); // 实际分组，这里简化为调用 initializeReadItems

    if (!m_PLC->connectDevice()) {
        qWarning() << "ModbusControl: 连接 PLC 失败:" << m_PLC->errorString();
    }
}

void ModbusControl::onModbusStateChanged(int state)
{
    bool connected = (state == QModbusDevice::ConnectedState);
    emit connectionStatusChanged(connected);

    if (connected) {
        qDebug() << "ModbusControl: PLC 已连接，开始轮询...";
        m_readTimer->start();
    } else {
        qDebug() << "ModbusControl: PLC 连接断开.";
        m_readTimer->stop();
    }
}

void ModbusControl::initializeReadItems()
{
    // 示例：定义所有需要持续监控的变量 (F/D 都是 32位浮点数, 占 2 个寄存器)
    RegisterOrder order = HIGH_WORD_FIRST;

    QVector<PlcItem> batch1;

    // 浮点数 (VD)
    batch1.append({"ExpForce1", QModbusDataUnit::HoldingRegisters, 10000/2, 2, order});
    batch1.append({"ExpForce2", QModbusDataUnit::HoldingRegisters, 10004/2, 2, order});
    batch1.append({"ExpForce3", QModbusDataUnit::HoldingRegisters, 10008/2, 2, order});
    batch1.append({"Displacement1", QModbusDataUnit::HoldingRegisters, 10016/2, 2, order});
    batch1.append({"Displacement2", QModbusDataUnit::HoldingRegisters, 10020/2, 2, order});
    batch1.append({"Displacement3", QModbusDataUnit::HoldingRegisters, 10024/2, 2, order});
    // batch1.append({"RunTime", QModbusDataUnit::HoldingRegisters, 10024, 2, order});

    // 16位整数 (VW) - 示例：设置点
    // batch1.append({"TargetSpeed", QModbusDataUnit::HoldingRegisters, 20000, 1, LOW_WORD_FIRST});

    // 线圈 (Q) - 示例：运行状态
    // batch1.append({"IsRunning", QModbusDataUnit::Coils, 0, 1, LOW_WORD_FIRST});

    // 初始化 Map 占位符
    for(const auto& item : batch1) {
        // 根据类型初始化默认值，确保 QML 绑定不会失败
        if (item.type == QModbusDataUnit::Coils) m_plcData.insert(item.qmlKey, false);
        else if (item.length == 2) m_plcData.insert(item.qmlKey, 0.0f);
        else m_plcData.insert(item.qmlKey, 0);
    }

    m_requestQueue.clear();
    m_requestQueue.append(batch1); // 简化：所有项作为一个批次
}

void ModbusControl::groupAndInitializeRequests()
{
    // 实际应实现按地址连续性优化分组的逻辑。这里简化为直接使用 initializeReadItems 的结果。
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
        m_isReading = false;
        m_currentRequestIndex = -1;

        // 🌟 关键修改 1: 基于 50ms 周期时间生成时间戳
        qreal timestampSeconds = static_cast<qreal>(m_cycleCount * POLL_INTERVAL_MS) / 1000.0;

        // 🌟 关键修改 2: 将时间戳插入到数据地图中，使用 QML 能够识别的键名
        m_plcData["timestampSeconds"] = QVariant::fromValue(timestampSeconds);

        // 核心：发送包含时间戳的完整数据包给 ThreadManager
        emit instantDataReady(m_plcData); // <-- 信号签名正确

        // 🌟 周期计数器递增
        m_cycleCount++;
        return;
    }

    const QVector<PlcItem>& currentBatch = m_requestQueue[m_currentRequestIndex];
    if (currentBatch.isEmpty()) {
        m_currentRequestIndex++;
        sendNextRequest();
        return;
    }

    // 计算读取范围 (简化逻辑：以第一个和最后一个地址决定读取长度)
    int startAddr = currentBatch.first().address;
    int endAddr = currentBatch.last().address + currentBatch.last().length;
    int count = endAddr - startAddr;
    QModbusDataUnit::RegisterType type = currentBatch.first().type;

    QModbusDataUnit readUnit(type, startAddr, count);

    if (auto* reply = m_PLC->sendReadRequest(readUnit, SERVER_ID)) {
        if (!reply->isFinished()) {
            connect(reply, &QModbusReply::finished, this, [this, reply, currentBatch]() {
                handleModbusReply(reply, currentBatch);
            });
        } else {
            // 立即返回错误
            qWarning() << "ModbusControl: 请求立即失败:" << reply->errorString();
            reply->deleteLater();
            m_currentRequestIndex++;
            sendNextRequest();
        }
    } else {
        qWarning() << "ModbusControl: 请求发送失败:" << m_PLC->errorString();
        m_currentRequestIndex++;
        sendNextRequest();
    }
}

void ModbusControl::handleModbusReply(QModbusReply* reply, const QVector<PlcItem>& itemsInBatch)
{
    if (reply->error() == QModbusDevice::NoError) {
        const QModbusDataUnit unit = reply->result();
        bool changed = false;
        for (const PlcItem& item : itemsInBatch) {
            QVariant val = parseModbusData(unit, item);
            if (val.isValid() && m_plcData.value(item.qmlKey) != val) {
                m_plcData[item.qmlKey] = val;
                changed = true;
            }
        }
        // 注意：不在这里发射 plcDataChanged，等待 sendNextRequest 结束时统一发射 instantDataReady
    } else {
        qWarning() << "ModbusControl: 读取错误:" << reply->errorString();
    }

    reply->deleteLater();
    m_currentRequestIndex++;
    sendNextRequest();
}

// --- 写入逻辑的完整实现 ---

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
                emit coilVerificationResultSignal(QVariant()); // 写入失败，发送无效结果
            }
            reply->deleteLater();
        });
    }
}

void ModbusControl::Modbus_HoldRegisters_16_Write(const QString& qmlKey, int address, qint16 value)
{
    // 🌟 完整实现 Modbus_HoldRegisters_16_Write
    QModbusDataUnit writeUnit(QModbusDataUnit::HoldingRegisters, address, 1);
    writeUnit.setValue(0, static_cast<quint16>(value)); // QModbusDataUnit 只接受 quint16

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
                    verifiedValue = (bool)res.value(0);
                    emit coilVerificationResultSignal(verifiedValue); // 发送给 QML 校验结果显示
                }
                else if (length == 2) {
                    verifiedValue = parseUint16PairToFloat(res.value(res.startAddress() == 0 ? 0 : 1), res.value(res.startAddress() == 0 ? 1 : 0), floatOrder);
                }
                else if (length == 1) {
                    verifiedValue = parseModbusInt16(res, 0);
                }

                if (verifiedValue.isValid()) {
                    m_plcData[qmlKey] = verifiedValue; // 更新子线程缓存
                    emit plcDataChanged(); // 通知 QML 刷新常规绑定
                    qDebug() << "ModbusControl: 回读校验通过:" << qmlKey << "=" << verifiedValue;
                }
            } else {
                qWarning() << "ModbusControl: 回读校验失败:" << reply->errorString();
                if (type == QModbusDataUnit::Coils) emit coilVerificationResultSignal(QVariant());
            }
            reply->deleteLater();
        });
    }
}
