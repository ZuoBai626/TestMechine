#ifndef READWRITECSV_H
#define READWRITECSV_H

#include <QObject>
#include <QVariantMap>
#include <QDateTime>
#include <QList>
#include <QMutex>

// 定义一个结构体来存储每行的数据，以便在写入前缓存
struct CsvDataRow {
    qreal timestampSeconds;
    float force1;
    float force2;
    float force3;
    float disp1;
    float disp2;
    float disp3;
};

class ReadWriteCSV : public QObject
{
    Q_OBJECT
public:
    explicit ReadWriteCSV(QObject *parent = nullptr);

public slots:
    // [槽] 接收来自 ThreadManager 的实时数据，缓存到 m_dataBuffer
    void cacheInstantData(const QVariantMap& data);

    // [槽] 实验开始，重置数据缓存并记录开始时间
    void startLogging();

    // [槽] 实验结束，触发将缓存数据写入 CSV 文件
    void stopAndSaveLog();

private:
    // 将缓存中的数据写入 CSV 文件
    bool writeDataToFile();

private:
    QList<CsvDataRow> m_dataBuffer; // 数据缓存
    QDateTime m_startTime;           // 实验开始时间
    QDateTime m_endTime;             // 实验结束时间
    QMutex m_mutex;                  // 用于保护 m_dataBuffer 的线程锁
};

#endif // READWRITECSV_H
