#include "ThreadManager.h"
#include <QDebug>
#include <QCoreApplication>

// 静态注册 ChartPoint 类型
static bool typeRegistered = []() { ChartPoint::registerType(); return true; }();

// [单例] 静态方法获取单例实例
ThreadManager* ThreadManager::getInstance()
{
    static ThreadManager instance;
    return &instance;
}

// [私有] 构造函数
ThreadManager::ThreadManager(QObject *parent) : QObject(parent)
{
    m_PLC_Thread = new QThread(this);
    m_PLC = new ModbusControl();

    m_CSV_Thread = new QThread(this);

    // 🌟 1. CSV Logger 初始化和移动到独立线程
    m_CSV_Logger = new ReadWriteCSV();
    m_CSV_Logger->moveToThread(m_CSV_Thread);
    m_CSV_Thread->start(); // 启动 CSV 线程

    // 🌟 关键连接: ModbusControl 的数据信号 转发给 CSV Logger 槽函数
    connect(m_PLC, &ModbusControl::instantDataReady, m_CSV_Logger, &ReadWriteCSV::cacheInstantData, Qt::QueuedConnection);

    // 3. 连接 CSV 线程控制信号
    connect(this, &ThreadManager::startCsvLoggingSignal, m_CSV_Logger, &ReadWriteCSV::startLogging, Qt::QueuedConnection);
    connect(this, &ThreadManager::stopAndSaveCsvSignal, m_CSV_Logger, &ReadWriteCSV::stopAndSaveLog, Qt::QueuedConnection);


}

ThreadManager::~ThreadManager()
{
    // 在析构时安全停止线程
    stop_Experiment();

    // 线程对象会随着 this 销毁
    // ModbusControl 对象会在 stop_Experiment 中被安全处理
}

void ThreadManager::start_Experiment()
{
    if (m_PLC_Thread->isRunning()) return;

    if (!m_PLC) m_PLC = new ModbusControl();

    // 🌟 核心修改 1: 在启动实验时，归零计时器
    m_experimentTimer.start();
    qDebug() << "ThreadManager: 实验计时器已启动/归零。";

    m_PLC->moveToThread(m_PLC_Thread);

    // --- 信号连接 (确保线程安全和安全停止) ---

    // 1. 生命周期/安全停止
    connect(m_PLC_Thread, &QThread::started, m_PLC, &ModbusControl::connectAndInitialize, Qt::UniqueConnection);
    // connect(this, &ThreadManager::stopPollingSignal, m_PLC, &ModbusControl::stopPolling, Qt::UniqueConnection);
    connect(m_PLC, &ModbusControl::connectionStatusChanged, this, &ThreadManager::updateConnectionStatus, Qt::UniqueConnection);

    // 🌟 新增连接: 用于重置时间戳计数器
    connect(this, &ThreadManager::resetCycleCountSignal, m_PLC, &ModbusControl::resetCycleCount, Qt::UniqueConnection);

    // 2. 数据回传
    connect(m_PLC, &ModbusControl::instantDataReady, this, &ThreadManager::handleInstantData, Qt::UniqueConnection);
    connect(m_PLC, &ModbusControl::coilVerificationResultSignal, this, &ThreadManager::updateLastWriteCoilResult, Qt::UniqueConnection);

    // 2. 数据回传 - 🌟 确保连接签名匹配
    connect(m_PLC, static_cast<void (ModbusControl::*)(const QVariantMap&)>(&ModbusControl::instantDataReady),
            this, &ThreadManager::handleInstantData, Qt::UniqueConnection);

    // 3. 写入请求转发 (QML -> 主线程 -> 子线程)
    connect(this, &ThreadManager::writeCoilSignal, m_PLC, &ModbusControl::Modbus_Coils_Write, Qt::UniqueConnection);
    connect(this, &ThreadManager::writeRegister16Signal, m_PLC, &ModbusControl::Modbus_HoldRegisters_16_Write, Qt::UniqueConnection);
    connect(this, &ThreadManager::writeRegister32Signal, m_PLC, &ModbusControl::Modbus_HoldRegisters_32_Write, Qt::UniqueConnection);

    m_PLC_Thread->start();

    // 🌟 关键: 重置周期计数器
    emit resetCycleCountSignal(); // <-- 在实验开始时发送重置信号

    // 🌟 关键: 重置 Modbus 周期计数器和启动 CSV 记录
    emit resetCycleCountSignal();
    emit startCsvLoggingSignal(); // <-- 启动 CSV 记录

}

void ThreadManager::stop_Experiment()
{
    if (m_PLC_Thread->isRunning() && m_PLC) {

        // 🌟 核心修改 1: 使用 BlockingQueuedConnection 强制在子线程中同步执行 stopPolling
        bool success = QMetaObject::invokeMethod(m_PLC, "stopPolling",
                                                 Qt::BlockingQueuedConnection);

        if (!success) {
            qWarning() << "ThreadManager: 警告！无法同步执行 stopPolling 槽函数。";
        }

        // 2. 退出线程事件循环 (现在可以安全退出)
        m_PLC_Thread->quit();

        // 3. 安全等待线程退出
        if (!m_PLC_Thread->wait(1000)) { // 增加等待时间，确保完成
            m_PLC_Thread->terminate();
            m_PLC_Thread->wait();
            qWarning() << "ThreadManager: PLC 线程被强制终止。";
        }

        // 4. 清理 ModbusControl (线程已退出，主线程可以安全删除)
        delete m_PLC;
        m_PLC = nullptr;
    }

    // 5. 清空图表数据
    if (!m_chartDataModel.isEmpty()) {
        m_chartDataModel.clear();
        emit chartDataModelChanged();
    }

    // 触发 CSV 文件写入操作，这将在 m_CSV_Thread 中执行
    emit stopAndSaveCsvSignal(); // <-- 停止并保存 CSV

}

void ThreadManager::updateConnectionStatus(bool connected)
{
    if (m_isConnected != connected) {
        m_isConnected = connected;
        emit isConnectedChanged();
    }
}

void ThreadManager::handleInstantData(const QVariantMap& data)
{

    // // 🌟 核心：在主线程接收到数据时，立即计算相对时间
    // qreal timestampSeconds = m_experimentTimer.elapsed() / 1000.0;

    // 1. 更新主线程缓存并通知 QML
    m_latestPlcData = data;
    emit plcDataChanged();

    // 2. 更新图表模型
    // 🌟 关键提取: 从数据 Map 中提取时间戳
    qreal timestampSeconds = data.value("timestampSeconds").toReal();

    // 2. 更新图表模型
    if (data.contains("ExpForce1")) {
        ChartPoint p;
        p.timestampSeconds = timestampSeconds;
        p.force1 = data.value("ExpForce1").toFloat();
        p.force2 = data.value("ExpForce2").toFloat();
        p.force3 = data.value("ExpForce3").toFloat();
        p.disp1 = data.value("Displacement1").toFloat();
        p.disp2 = data.value("Displacement2").toFloat();
        p.disp3 = data.value("Displacement3").toFloat();

        // qDebug() << "Chart Data - Time:" << timestampSeconds << " ExpForce1:" << p.force1; // 🌟 打印此行
        // qDebug() << "Chart Data - Time:" << timestampSeconds << " ExpForce2:" << p.force2; // 🌟 打印此行
        // qDebug() << "Chart Data - Time:" << timestampSeconds << " ExpForce3:" << p.force3; // 🌟 打印此行
        // qDebug() << "Chart Data - Time:" << timestampSeconds << " Displacement1:" << p.disp1; // 🌟 打印此行
        // qDebug() << "Chart Data - Time:" << timestampSeconds << " Displacement2:" << p.disp2; // 🌟 打印此行
        // qDebug() << "Chart Data - Time:" << timestampSeconds << " Displacement3:" << p.disp3; // 🌟 打印此行

        m_chartDataModel.append(QVariant::fromValue(p));

        if (m_chartDataModel.size() > MAX_CHART_POINTS) {
            m_chartDataModel.removeFirst();
        }

        emit chartDataModelChanged();
    }
}

void ThreadManager::updateLastWriteCoilResult(const QVariant& value)
{
    m_lastWriteCoilResult = value;
    emit lastWriteCoilResultChanged();
}

// Q_INVOKABLE 转发函数
void ThreadManager::writeCoil(const QString& qmlKey, int address, bool value) {
    emit writeCoilSignal(qmlKey, address, value);
}
void ThreadManager::writeRegister16(const QString& qmlKey, int address, qint16 value) {
    emit writeRegister16Signal(qmlKey, address, value);
}
void ThreadManager::writeRegister32(const QString& qmlKey, int address, float value) {
    emit writeRegister32Signal(qmlKey, address, value);
}
