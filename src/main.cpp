#include "AnimeController.h"
#include "AnimeListModel.h"
#include "BangumiClient.h"
#include "DatabaseManager.h"
#include "GameController.h"
#include "GameListModel.h"
#include "GameReviewListModel.h"
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
    app.setApplicationName(QStringLiteral("EWR_Manager"));
    app.setOrganizationName(QStringLiteral("Personal"));
    app.setOrganizationDomain(QStringLiteral("local"));
    app.setWindowIcon(QIcon(QStringLiteral(":/icons/app-icon.svg")));

    QQuickStyle::setStyle(QStringLiteral("Basic"));

    const QString dataDir =
        QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    const QString dbPath = dataDir + QStringLiteral("/anime.db");
    const QString coversDir = dataDir + QStringLiteral("/covers");

    if (!DatabaseManager::instance().initialize(dbPath)) {
        return -1;
    }

    AnimeController animeController;
    animeController.seedSampleData();

    GameController gameController;
    gameController.seedSampleData();

    AnimeListModel animeModel;
    ReviewListModel reviewModel;
    GameListModel gameModel;
    GameReviewListModel gameReviewModel;

    BangumiClient bangumiClient(coversDir, 2);
    BangumiClient gameBangumiClient(coversDir, 4);

    QObject::connect(&bangumiClient, &BangumiClient::localSyncFinished, &animeController,
                     [&animeController, &animeModel](int localAnimeId, const QVariantMap &data) {
                         animeController.applyBangumiSync(localAnimeId, data);
                         animeModel.refresh();
                     });
    QObject::connect(&bangumiClient, &BangumiClient::localSyncBatchFinished, &animeModel,
                     [&animeModel]() { animeModel.refresh(); });

    QObject::connect(&gameBangumiClient, &BangumiClient::gameLocalSyncFinished, &gameController,
                     [&gameController, &gameModel](int localGameId, const QVariantMap &data) {
                         gameController.applyBangumiSync(localGameId, data);
                         gameModel.refresh();
                     });
    QObject::connect(&gameBangumiClient, &BangumiClient::gameLocalSyncBatchFinished, &gameModel,
                     [&gameModel]() { gameModel.refresh(); });

    animeController.syncPendingAnimeFromBangumi(&bangumiClient);
    gameController.syncPendingGamesFromBangumi(&gameBangumiClient);

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral("qrc:/qml"));
    engine.rootContext()->setContextProperty(QStringLiteral("animeController"), &animeController);
    engine.rootContext()->setContextProperty(QStringLiteral("gameController"), &gameController);
    engine.rootContext()->setContextProperty(QStringLiteral("animeModel"), &animeModel);
    engine.rootContext()->setContextProperty(QStringLiteral("gameModel"), &gameModel);
    engine.rootContext()->setContextProperty(QStringLiteral("reviewModel"), &reviewModel);
    engine.rootContext()->setContextProperty(QStringLiteral("gameReviewModel"), &gameReviewModel);
    engine.rootContext()->setContextProperty(QStringLiteral("bangumiClient"), &bangumiClient);
    engine.rootContext()->setContextProperty(QStringLiteral("gameBangumiClient"), &gameBangumiClient);

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
