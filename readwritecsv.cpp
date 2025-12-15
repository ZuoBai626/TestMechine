#include "readwritecsv.h"
#include <QDebug>
#include <QFile>
#include <QDir>
#include <QTextStream>
#include <QCoreApplication>

ReadWriteCSV::ReadWriteCSV(QObject *parent) : QObject(parent)
{
}

void ReadWriteCSV::cacheInstantData(const QVariantMap& data)
{
    QMutexLocker locker(&m_mutex);

    // 从 QVariantMap 中提取数据，并检查键是否存在
    if (data.contains("timestampSeconds") && data.contains("ExpForce1")) {
        CsvDataRow row;
        row.timestampSeconds = data.value("timestampSeconds").toReal();

        // 注意：这里假设您的 PLC 数据键名与 ThreadManager 中的一致
        row.force1 = data.value("ExpForce1").toFloat();
        row.force2 = data.value("ExpForce2").toFloat();
        row.force3 = data.value("ExpForce3").toFloat();
        row.disp1 = data.value("Displacement1").toFloat();
        row.disp2 = data.value("Displacement2").toFloat();
        row.disp3 = data.value("Displacement3").toFloat();

        m_dataBuffer.append(row);
    }
}

void ReadWriteCSV::startLogging()
{
    QMutexLocker locker(&m_mutex);
    m_dataBuffer.clear(); // 清空上次实验数据
    m_startTime = QDateTime::currentDateTime();
    qDebug() << "ReadWriteCSV: 可是记录 : " << m_startTime.toString("yyyy-MM-dd hh:mm:ss");
}

void ReadWriteCSV::stopAndSaveLog()
{
    QMutexLocker locker(&m_mutex);
    m_endTime = QDateTime::currentDateTime();
    qDebug() << "ReadWriteCSV: 记录完成，总数据:" << m_dataBuffer.size();

    // 在子线程中执行文件写入操作
    if (writeDataToFile()) {
        qDebug() << "ReadWriteCSV: 数据保存成功";
    } else {
        qCritical() << "ReadWriteCSV: 数据保存失败";
    }
    m_dataBuffer.clear(); // 写入完成后清空缓存
}

bool ReadWriteCSV::writeDataToFile()
{
    if (m_dataBuffer.isEmpty()) {
        qDebug() << "ReadWriteCSV: 数据为空，无需保存";
        return true;
    }

    // 1. 设置文件路径和名称
    // 文件名格式: 实验_YYYYMMDD_hhmmss.csv
    QString timestampStr = m_startTime.toString("yyyyMMdd_hhmmss");
    QString fileName = QString("实验记录_%1.csv").arg(timestampStr);
    QString dirPath = QCoreApplication::applicationDirPath() + "/TestResult";

    QDir dir(dirPath);
    if (!dir.exists()) {
        if (!dir.mkpath(".")) {
            qCritical() << "ReadWriteCSV: 创建路径失败:" << dirPath;
            return false;
        }
    }

    QString filePath = dirPath + "/" + fileName;
    QFile file(filePath);

    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        qCritical() << "ReadWriteCSV: 无法打开路径 :" << filePath;
        return false;
    }

    QTextStream out(&file);

    // 2. 写入头部信息 (开始/结束时间)
    out << "实验开始时间: " << m_startTime.toString("yyyy-MM-dd hh:mm:ss.zzz") << "\n";
    out << "实验结束时间: " << m_endTime.toString("yyyy-MM-dd hh:mm:ss.zzz") << "\n";

    // 3. 写入 CSV 头部
    out << "实验时间(s),端肋-压力1(N),中肋-压力(N),端肋-压力2(N),端肋-位移量1(mm),中肋-位移量1(mm),端肋-位移量2(mm)\n";

    // 4. 写入数据行
    for (const auto& row : m_dataBuffer) {
        out << QString::number(row.timestampSeconds, 'f', 3) << ","
            << QString::number(row.force1, 'f', 3) << ","
            << QString::number(row.force2, 'f', 3) << ","
            << QString::number(row.force3, 'f', 3) << ","
            << QString::number(row.disp1, 'f', 3) << ","
            << QString::number(row.disp2, 'f', 3) << ","
            << QString::number(row.disp3, 'f', 3) << "\n";
    }

    file.close();
    return true;
}
