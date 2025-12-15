// #include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QThread>
#include <QApplication>
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


    // QTimer::singleShot(0,threadmanager,&ThreadManager::start_Experiment);

    return app.exec();
}
