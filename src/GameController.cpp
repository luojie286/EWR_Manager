#include "GameController.h"

#include "BangumiClient.h"
#include "DatabaseManager.h"

#include <QDate>
#include <QMetaType>
#include <QRegularExpression>

GameController::GameController(QObject *parent)
    : QObject(parent)
{
}

QVariantMap GameController::getGame(int id) const
{
    return gameToMap(DatabaseManager::instance().fetchGame(id));
}

int GameController::addGame(const QVariantMap &data)
{
    return DatabaseManager::instance().insertGame(mapToGame(data));
}

bool GameController::updateGame(const QVariantMap &data)
{
    return DatabaseManager::instance().updateGame(mapToGame(data));
}

bool GameController::deleteGame(int id)
{
    return DatabaseManager::instance().deleteGame(id);
}

bool GameController::deleteGameBatch(const QVariantList &ids)
{
    QVector<int> batch;
    batch.reserve(ids.size());
    for (const QVariant &value : ids) {
        bool ok = false;
        const int id = value.toInt(&ok);
        if (ok && id > 0) {
            batch.append(id);
        }
    }
    return DatabaseManager::instance().deleteGameBatch(batch);
}

QVariantMap GameController::getReview(int id) const
{
    return reviewToMap(DatabaseManager::instance().fetchGameReview(id));
}

int GameController::addReview(const QVariantMap &data)
{
    return DatabaseManager::instance().insertGameReview(mapToReview(data));
}

bool GameController::updateReview(const QVariantMap &data)
{
    return DatabaseManager::instance().updateGameReview(mapToReview(data));
}

bool GameController::deleteReview(int id)
{
    return DatabaseManager::instance().deleteGameReview(id);
}

QStringList GameController::allTags() const
{
    return DatabaseManager::instance().fetchAllGameTags();
}

QVariantMap GameController::statistics() const
{
    const StatisticsRecord stats = DatabaseManager::instance().fetchGameStatistics();
    QVariantMap map;
    map.insert(QStringLiteral("totalCount"), stats.totalCount);
    map.insert(QStringLiteral("finishedCount"), stats.finishedCount);
    map.insert(QStringLiteral("watchingCount"), stats.watchingCount);
    map.insert(QStringLiteral("plannedCount"), stats.plannedCount);
    map.insert(QStringLiteral("droppedCount"), stats.droppedCount);
    map.insert(QStringLiteral("averageScore"),
               QString::number(stats.averageScore, 'f', 1));
    map.insert(QStringLiteral("tagRanking"), stats.tagRanking);
    return map;
}

QStringList GameController::statusOptions() const
{
    return {QStringLiteral("全部"),
            QStringLiteral("未玩"),
            QStringLiteral("在玩"),
            QStringLiteral("玩完"),
            QStringLiteral("弃坑")};
}

void GameController::seedSampleData()
{
    if (DatabaseManager::instance().isGameSampleSeeded()) {
        return;
    }

    struct SampleGame {
        QString title;
        double score;
        QString status;
        QString description;
        QStringList tags;
    };

    const QVector<SampleGame> samples = {
        {QStringLiteral("塞尔达传说：旷野之息"),
         9.7,
         QStringLiteral("玩完"),
         QStringLiteral("开放世界探索与解谜的标杆之作，海拉鲁的冒险至今难忘。"),
         {QStringLiteral("开放世界"), QStringLiteral("冒险"), QStringLiteral("神作")}},
        {QStringLiteral("艾尔登法环"),
         9.4,
         QStringLiteral("玩完"),
         QStringLiteral("FromSoftware 集大成的开放世界魂系，探索与战斗节奏出色。"),
         {QStringLiteral("魂系"), QStringLiteral("开放世界"), QStringLiteral("动作")}},
        {QStringLiteral("女神异闻录5"),
         9.2,
         QStringLiteral("玩完"),
         QStringLiteral("白天校园、夜晚怪盗的双重生活，风格与音乐都极具魅力。"),
         {QStringLiteral("JRPG"), QStringLiteral("回合制"), QStringLiteral("剧情")}},
        {QStringLiteral("空洞骑士"),
         9.0,
         QStringLiteral("在玩"),
         QStringLiteral("类银河战士恶魔城代表作，地图探索与战斗手感都很优秀。"),
         {QStringLiteral("独立"), QStringLiteral("类银河城")}},
        {QStringLiteral("极乐迪斯科"),
         9.5,
         QStringLiteral("玩完"),
         QStringLiteral("文字与选择驱动的 RPG，哲学气质与叙事深度独树一帜。"),
         {QStringLiteral("RPG"), QStringLiteral("叙事"), QStringLiteral("独立")}}};

    for (const SampleGame &sample : samples) {
        GameRecord game;
        game.title = sample.title;
        game.score = sample.score;
        game.status = sample.status;
        game.description = sample.description;
        game.tags = sample.tags;
        const int id = DatabaseManager::instance().insertGame(game);

        if (id > 0 && sample.title == QStringLiteral("塞尔达传说：旷野之息")) {
            GameReviewRecord r1;
            r1.gameId = id;
            r1.date = QStringLiteral("2025-03-15");
            r1.title = QStringLiteral("初通关");
            r1.content = QStringLiteral("自由度和探索感太强了，打完还想继续逛地图。");
            DatabaseManager::instance().insertGameReview(r1);
        }
    }

    DatabaseManager::instance().setGameSampleSeeded();
}

void GameController::linkSampleBangumiIds()
{
    const struct {
        const char *title;
        int bgmId;
    } mappings[] = {
        {"塞尔达传说：旷野之息", 190931},
        {"艾尔登法环", 318238},
        {"女神异闻录5", 145935},
        {"空洞骑士", 143093},
        {"极乐迪斯科", 263023},
    };

    for (const auto &mapping : mappings) {
        const int gameId =
            DatabaseManager::instance().findGameIdByTitle(QString::fromUtf8(mapping.title));
        if (gameId <= 0) {
            continue;
        }

        const GameRecord game = DatabaseManager::instance().fetchGame(gameId);
        if (game.bgmId <= 0) {
            DatabaseManager::instance().setGameBgmId(gameId, mapping.bgmId);
        }
    }
}

bool GameController::applyBangumiSync(int localGameId, const QVariantMap &data)
{
    if (localGameId <= 0) {
        return false;
    }

    GameRecord game = DatabaseManager::instance().fetchGame(localGameId);
    if (game.id <= 0) {
        return false;
    }

    const QString title = data.value(QStringLiteral("title")).toString();
    if (!title.isEmpty()) {
        game.title = title;
    }

    const QString description = data.value(QStringLiteral("description")).toString();
    if (!description.isEmpty()) {
        game.description = description;
    }

    const QString coverPath = data.value(QStringLiteral("coverPath")).toString();
    if (!coverPath.isEmpty()) {
        game.coverPath = coverPath;
    }

    const int bgmId = data.value(QStringLiteral("bgmId")).toInt();
    if (bgmId > 0) {
        game.bgmId = bgmId;
    }

    const QStringList tags = parseTags(data.value(QStringLiteral("tags")));
    if (!tags.isEmpty()) {
        game.tags = tags;
    }

    return DatabaseManager::instance().updateGame(game);
}

void GameController::syncPendingGamesFromBangumi(BangumiClient *client)
{
    if (!client) {
        return;
    }

    linkSampleBangumiIds();

    const QVector<int> ids = DatabaseManager::instance().fetchGameIdsNeedingBangumiSync();
    if (ids.isEmpty()) {
        emit bangumiSyncCompleted();
        return;
    }

    client->startGameLocalSync(ids);
}

GameRecord GameController::mapToGame(const QVariantMap &data) const
{
    GameRecord game;
    game.id = data.value(QStringLiteral("gameId"), data.value(QStringLiteral("id"))).toInt();
    game.title = data.value(QStringLiteral("title")).toString().trimmed();
    game.score = data.value(QStringLiteral("score")).toDouble();
    game.status = data.value(QStringLiteral("status"), QStringLiteral("未玩")).toString();
    game.description = data.value(QStringLiteral("description")).toString();
    game.coverPath = data.value(QStringLiteral("coverPath")).toString();
    game.bgmId = data.value(QStringLiteral("bgmId")).toInt();
    game.tags = parseTags(data.value(QStringLiteral("tags")));
    return game;
}

GameReviewRecord GameController::mapToReview(const QVariantMap &data) const
{
    GameReviewRecord review;
    review.id = data.value(QStringLiteral("reviewId"), data.value(QStringLiteral("id"))).toInt();
    review.gameId = data.value(QStringLiteral("gameId")).toInt();
    review.date = data.value(QStringLiteral("date"), QDate::currentDate().toString(Qt::ISODate))
                      .toString();
    review.title = data.value(QStringLiteral("title")).toString();
    review.content = data.value(QStringLiteral("content")).toString();
    return review;
}

QVariantMap GameController::gameToMap(const GameRecord &game) const
{
    QVariantMap map;
    map.insert(QStringLiteral("gameId"), game.id);
    map.insert(QStringLiteral("title"), game.title);
    map.insert(QStringLiteral("score"), game.score);
    map.insert(QStringLiteral("status"), game.status);
    map.insert(QStringLiteral("description"), game.description);
    map.insert(QStringLiteral("coverPath"), game.coverPath);
    map.insert(QStringLiteral("bgmId"), game.bgmId);
    map.insert(QStringLiteral("tags"), game.tags);
    return map;
}

QVariantMap GameController::reviewToMap(const GameReviewRecord &review) const
{
    QVariantMap map;
    map.insert(QStringLiteral("reviewId"), review.id);
    map.insert(QStringLiteral("gameId"), review.gameId);
    map.insert(QStringLiteral("date"), review.date);
    map.insert(QStringLiteral("title"), review.title);
    map.insert(QStringLiteral("content"), review.content);
    return map;
}

QStringList GameController::parseTags(const QVariant &value) const
{
    if (value.typeId() == QMetaType::QStringList) {
        return value.toStringList();
    }

    const QString text = value.toString();
    if (text.isEmpty()) {
        return {};
    }

    QStringList tags = text.split(QRegularExpression(QStringLiteral("[,，\\s]+")),
                                  Qt::SkipEmptyParts);
    for (QString &tag : tags) {
        tag = tag.trimmed();
    }
    tags.removeAll(QString());
    return tags;
}
