// #include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QThread>
#include <QApplication>
#include <QQuickWindow> // 🌟 包含 QQuickWindow 头文件
#include "ThreadManager.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    QQmlApplicationEngine engine;

    ThreadManager* threadmanager = ThreadManager::getInstance();
    threadmanager->setParent(&engine);

    engine.rootContext()->setContextProperty("Cpp_ThreadManager",threadmanager);


    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("Test_Mechine", "Main");


    // 🌟 关键修正：确保在加载完成后设置根窗口
    QObject *rootObject = engine.rootObjects().constFirst();
    if (rootObject) {
        if (QQuickWindow* window = qobject_cast<QQuickWindow*>(rootObject)) {
            // 使用 DirectConnection 在 main 线程立即设置 QQuickWindow 指针
            threadmanager->setQmlRootWindow(window);
            qDebug() << "main.cpp: QML root window set immediately after load.";
        } else {
            qWarning() << "main.cpp: QML root object is not a QQuickWindow.";
        }
    } else {
        qCritical() << "main.cpp: 无法获取 QML 根对象，请检查 engine.loadFromModule() 调用。";
    }

    return app.exec();
}
