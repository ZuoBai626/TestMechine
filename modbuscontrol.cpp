#include "modbuscontrol.h"
#include <QCoreApplication>

// === 配置参数 ===
const QString PLC_IP = "192.168.1.10";     // PLC IP地址
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
    allItems.append({"ExpForce1",       QModbusDataUnit::HoldingRegisters, 10000/2, 2, order, true});
    allItems.append({"ExpForce2",       QModbusDataUnit::HoldingRegisters, 10004/2, 2, order, true});
    allItems.append({"ExpForce3",       QModbusDataUnit::HoldingRegisters, 10008/2, 2, order, true});
    allItems.append({"Displacement1",   QModbusDataUnit::HoldingRegisters, 10016/2, 2, order, true});
    allItems.append({"Displacement2",   QModbusDataUnit::HoldingRegisters, 10020/2, 2, order, true});
    allItems.append({"Displacement3",   QModbusDataUnit::HoldingRegisters, 10024/2, 2, order, true});

    // === 非轮询变量（仅在写入后回读）===
    allItems.append({"TestHold_1",      QModbusDataUnit::HoldingRegisters, 2000/2,  2, order, false});

    m_requestQueue.clear();
    QVector<PlcItem> pollingBatch;

    for (const auto& item : allItems) {
        // 为所有变量在m_plcData中预置初始值（QML绑定需要）
        if (item.type == QModbusDataUnit::Coils || item.type == QModbusDataUnit::DiscreteInputs) {
            m_plcData.insert(item.qmlKey, false);
        } else if (item.length == 2) {
            m_plcData.insert(item.qmlKey, 0.0);
        } else {
            m_plcData.insert(item.qmlKey, 0);
        }

        if (item.isPolling) {
            pollingBatch.append(item);
        }
    }

    if (!pollingBatch.isEmpty()) {
        m_requestQueue.append(pollingBatch);
    }

    m_plcData.insert("timestampSeconds", 0.0);  // 时间戳键
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
