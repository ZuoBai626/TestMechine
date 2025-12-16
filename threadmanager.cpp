#include "ThreadManager.h"
#include <QImage>
#include <QDir>
#include <QDateTime>

// 注册ChartPoint元类型（必须）
static bool typeRegistered = []() { ChartPoint::registerType(); return true; }();

ThreadManager* ThreadManager::getInstance()
{
    static ThreadManager instance;
    return &instance;
}

ThreadManager::ThreadManager(QObject *parent) : QObject(parent)
{
    // === 创建PLC线程和对象 ===
    m_PLC_Thread = new QThread(this);
    m_PLC = new ModbusControl();
    m_PLC->moveToThread(m_PLC_Thread);

    // === 创建CSV线程和对象 ===
    m_CSV_Thread = new QThread(this);
    m_CSV_Logger = new ReadWriteCSV();
    m_CSV_Logger->moveToThread(m_CSV_Thread);
    m_CSV_Thread->start();

    // === 数据转发：Modbus -> CSV ===
    connect(m_PLC, &ModbusControl::instantDataReady,
            m_CSV_Logger, &ReadWriteCSV::cacheInstantData, Qt::QueuedConnection);

    // === CSV控制信号 ===
    connect(this, &ThreadManager::startCsvLoggingSignal,
            m_CSV_Logger, &ReadWriteCSV::startLogging, Qt::QueuedConnection);
    connect(this, &ThreadManager::stopAndSaveCsvSignal,
            m_CSV_Logger, &ReadWriteCSV::stopAndSaveLog, Qt::QueuedConnection);

    // === 启动PLC线程并立即连接PLC ===
    m_PLC_Thread->start();
    QMetaObject::invokeMethod(m_PLC, "connectToPlc", Qt::QueuedConnection);

    // === 关键信号连接 ===
    connect(m_PLC, &ModbusControl::connectionStatusChanged, this, &ThreadManager::updateConnectionStatus);
    connect(m_PLC, &ModbusControl::instantDataReady, this, &ThreadManager::handleInstantData);
    connect(m_PLC, &ModbusControl::coilVerificationResultSignal, this, &ThreadManager::updateLastWriteCoilResult);

    // === 写入请求转发 ===
    connect(this, &ThreadManager::writeCoilSignal, m_PLC, &ModbusControl::Modbus_Coils_Write);
    connect(this, &ThreadManager::writeRegister16Signal, m_PLC, &ModbusControl::Modbus_HoldRegisters_16_Write);
    connect(this, &ThreadManager::writeRegister32Signal, m_PLC, &ModbusControl::Modbus_HoldRegisters_32_Write);
}

ThreadManager::~ThreadManager()
{
    // === 程序退出时安全清理 ===
    if (m_PLC) {
        QMetaObject::invokeMethod(m_PLC, "disconnectFromPlc", Qt::BlockingQueuedConnection);
        delete m_PLC;
        m_PLC = nullptr;
    }
    if (m_PLC_Thread && m_PLC_Thread->isRunning()) {
        m_PLC_Thread->quit();
        m_PLC_Thread->wait(1000);
    }

    // 最后保存一次CSV
    emit stopAndSaveCsvSignal();
    if (m_CSV_Thread && m_CSV_Thread->isRunning()) {
        m_CSV_Thread->quit();
        m_CSV_Thread->wait(1000);
    }
}

void ThreadManager::start_Experiment()
{
    QMetaObject::invokeMethod(m_PLC, "startPolling", Qt::QueuedConnection);
    emit startCsvLoggingSignal();
    qDebug() << "ThreadManager: 实验开始 —— 轮询与CSV记录已启动";
}

void ThreadManager::stop_Experiment()
{
    QMetaObject::invokeMethod(m_PLC, "stopPolling", Qt::QueuedConnection);
    emit stopAndSaveCsvSignal();

    // 清空图表数据
    if (!m_chartDataModel.isEmpty()) {
        m_chartDataModel.clear();
        emit chartDataModelChanged();
    }
    qDebug() << "ThreadManager: 实验停止 —— 轮询暂停，CSV已保存，图表已清空";
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
    m_latestPlcData = data;
    emit plcDataChanged();

    qreal timestampSeconds = data.value("timestampSeconds").toReal();

    if (data.contains("ExpForce1")) {
        ChartPoint p;
        p.timestampSeconds = timestampSeconds;
        p.force1 = data.value("ExpForce1").toFloat();
        p.force2 = data.value("ExpForce2").toFloat();
        p.force3 = data.value("ExpForce3").toFloat();
        p.disp1 = data.value("Displacement1").toFloat();
        p.disp2 = data.value("Displacement2").toFloat();
        p.disp3 = data.value("Displacement3").toFloat();

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

void ThreadManager::writeCoil(const QString& qmlKey, int address, bool value)
{
    emit writeCoilSignal(qmlKey, address, value);
}

void ThreadManager::writeRegister16(const QString& qmlKey, int address, qint16 value)
{
    emit writeRegister16Signal(qmlKey, address, value);
}

void ThreadManager::writeRegister32(const QString& qmlKey, int address, float value)
{
    emit writeRegister32Signal(qmlKey, address, value);
}

void ThreadManager::setQmlRootWindow(QQuickWindow *window)
{
    m_rootWindow = window;
}

QString ThreadManager::saveChartImage()
{
    if (!m_rootWindow) {
        qCritical() << "ThreadManager: QML根窗口未设置，无法截图";
        return QString();
    }

    QImage image = m_rootWindow->grabWindow();
    if (image.isNull()) {
        qCritical() << "ThreadManager: 截图失败";
        return QString();
    }

    QString timestampStr = QDateTime::currentDateTime().toString("yyyyMMdd_hhmmss");
    QString fileName = QString("实验数据_%1.png").arg(timestampStr);
    QString dirPath = QCoreApplication::applicationDirPath() + "/TestResultImages";

    QDir dir(dirPath);
    if (!dir.exists()) {
        dir.mkpath(".");
    }

    QString filePath = dirPath + "/" + fileName;
    if (image.save(filePath, "PNG")) {
        qDebug() << "ThreadManager: 图表图片保存成功:" << filePath;
        return filePath;
    } else {
        qCritical() << "ThreadManager: 图片保存失败";
        return QString();
    }
}
