#include <QGuiApplication>
#include <QIcon>
#include <QtQuickControls2/QQuickStyle>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "interfaces/esitreemodel.h"
#include "interfaces/simengine.h"

int main(int argc, char *argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    QGuiApplication app(argc, argv);

    app.setWindowIcon(QIcon(QStringLiteral(":/resources/MainApp/ethercat_icon.svg")));

    QQuickStyle::setStyle("Fusion");

    QQmlApplicationEngine engine;

    ESITreeModel* esiTreeModel = &ESITreeModel::getInstance();
    engine.rootContext()->setContextProperty("ESITreeModel", esiTreeModel);

    SimEngine* simEngine = &SimEngine::getInstance();
    engine.rootContext()->setContextProperty("SimEngine", simEngine);

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
