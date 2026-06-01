#include "AnimeController.h"
#include "AnimeListModel.h"
#include "DatabaseManager.h"
#include "ReviewListModel.h"

#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QStandardPaths>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("AnimeManager"));
    app.setOrganizationName(QStringLiteral("Personal"));
    app.setOrganizationDomain(QStringLiteral("local"));

    QQuickStyle::setStyle(QStringLiteral("Basic"));

    const QString dataDir =
        QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    const QString dbPath = dataDir + QStringLiteral("/anime.db");

    if (!DatabaseManager::instance().initialize(dbPath)) {
        return -1;
    }

    AnimeController controller;
    controller.seedSampleData();

    AnimeListModel animeModel;
    ReviewListModel reviewModel;

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral("qrc:/qml"));
    engine.rootContext()->setContextProperty(QStringLiteral("animeController"), &controller);
    engine.rootContext()->setContextProperty(QStringLiteral("animeModel"), &animeModel);
    engine.rootContext()->setContextProperty(QStringLiteral("reviewModel"), &reviewModel);

    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
        []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);

    engine.load(url);
    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
