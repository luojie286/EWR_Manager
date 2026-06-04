#include "AnimeController.h"
#include "AnimeListModel.h"
#include "BangumiClient.h"
#include "DatabaseManager.h"
#include "GameController.h"
#include "GameListModel.h"
#include "GameReviewListModel.h"
#include "MusicController.h"
#include "RawgClient.h"
#include "ReviewListModel.h"

#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QSqlDatabase>
#include <QStandardPaths>

#ifdef Q_OS_WIN
#include <windows.h>
#endif

namespace {

void showStartupError(const QString &message)
{
    qCritical().noquote() << message;
#ifdef Q_OS_WIN
    MessageBoxW(nullptr, message.toStdWString().c_str(), L"EWR_Manager",
                MB_OK | MB_ICONERROR);
#else
    fprintf(stderr, "%s\n", qPrintable(message));
#endif
}

QString startupFailureHint()
{
    return QStringLiteral(
        "\n\n若从 build 目录双击 exe 无界面，请先运行：\n"
        "  powershell -ExecutionPolicy Bypass -File scripts\\deploy.ps1\n"
        "或在 Qt Creator 中重新构建（会自动部署 Qt 运行时）。");
}

} // namespace

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
    const QString musicDir = dataDir + QStringLiteral("/music");

    if (!QSqlDatabase::isDriverAvailable(QStringLiteral("QSQLITE"))) {
        showStartupError(
            QStringLiteral("SQLite 驱动不可用。请确认 exe 同目录存在 sqldrivers\\qsqlite.dll")
            + startupFailureHint());
        return -1;
    }

    if (!DatabaseManager::instance().initialize(dbPath)) {
        showStartupError(QStringLiteral("无法打开数据库：\n%1").arg(dbPath));
        return -1;
    }

    qInfo() << "Database:" << DatabaseManager::instance().databasePath();

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
    RawgClient rawgClient(coversDir);
    MusicController musicController(musicDir);

    QObject::connect(&bangumiClient, &BangumiClient::localSyncFinished, &animeController,
                     [&animeController, &animeModel](int localAnimeId, const QVariantMap &data) {
                         animeController.applyBangumiSync(localAnimeId, data);
                         animeModel.refresh();
                     });
    QObject::connect(&bangumiClient, &BangumiClient::localSyncBatchFinished, &animeModel,
                     [&animeModel]() { animeModel.refresh(); });

    animeController.syncPendingAnimeFromBangumi(&bangumiClient);

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
    engine.rootContext()->setContextProperty(QStringLiteral("rawgClient"), &rawgClient);
    engine.rootContext()->setContextProperty(QStringLiteral("musicController"), &musicController);

    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
        []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);

    engine.load(url);
    if (engine.rootObjects().isEmpty()) {
        showStartupError(QStringLiteral("界面加载失败。请检查 Qt Quick 运行时是否已部署。")
                        + startupFailureHint());
        return -1;
    }

    return app.exec();
}
