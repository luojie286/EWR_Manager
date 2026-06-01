#include "AnimeController.h"

#include "BangumiClient.h"
#include "DatabaseManager.h"

#include <QDate>
#include <QMetaType>
#include <QRegularExpression>

AnimeController::AnimeController(QObject *parent)
    : QObject(parent)
{
}

QVariantMap AnimeController::getAnime(int id) const
{
    return animeToMap(DatabaseManager::instance().fetchAnime(id));
}

int AnimeController::addAnime(const QVariantMap &data)
{
    return DatabaseManager::instance().insertAnime(mapToAnime(data));
}

bool AnimeController::updateAnime(const QVariantMap &data)
{
    return DatabaseManager::instance().updateAnime(mapToAnime(data));
}

bool AnimeController::deleteAnime(int id)
{
    return DatabaseManager::instance().deleteAnime(id);
}

QVariantMap AnimeController::getReview(int id) const
{
    return reviewToMap(DatabaseManager::instance().fetchReview(id));
}

int AnimeController::addReview(const QVariantMap &data)
{
    return DatabaseManager::instance().insertReview(mapToReview(data));
}

bool AnimeController::updateReview(const QVariantMap &data)
{
    return DatabaseManager::instance().updateReview(mapToReview(data));
}

bool AnimeController::deleteReview(int id)
{
    return DatabaseManager::instance().deleteReview(id);
}

QStringList AnimeController::allTags() const
{
    return DatabaseManager::instance().fetchAllTags();
}

QVariantMap AnimeController::statistics() const
{
    const StatisticsRecord stats = DatabaseManager::instance().fetchStatistics();
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

QStringList AnimeController::statusOptions() const
{
    return {QStringLiteral("全部"),
            QStringLiteral("未看"),
            QStringLiteral("在看"),
            QStringLiteral("看完"),
            QStringLiteral("弃坑")};
}

void AnimeController::seedSampleData()
{
    if (DatabaseManager::instance().fetchAllAnime().size() > 0) {
        return;
    }

    struct SampleAnime {
        QString title;
        double score;
        QString status;
        QString description;
        QStringList tags;
    };

    const QVector<SampleAnime> samples = {
        {QStringLiteral("葬送的芙莉莲"),
         9.5,
         QStringLiteral("看完"),
         QStringLiteral("打倒魔王后的世界里，精灵魔法使芙莉莲踏上理解人类与回忆的旅程。"),
         {QStringLiteral("治愈"), QStringLiteral("奇幻"), QStringLiteral("公路片")}},
        {QStringLiteral("CLANNAD"),
         9.3,
         QStringLiteral("看完"),
         QStringLiteral("校园与家庭交织的催泪物语，讲述朋也与古河渚的人生选择。"),
         {QStringLiteral("校园"), QStringLiteral("恋爱"), QStringLiteral("催泪")}},
        {QStringLiteral("命运石之门"),
         9.6,
         QStringLiteral("看完"),
         QStringLiteral("中二科学家偶然发明时间跳跃装置，卷入世界线变动的悬疑故事。"),
         {QStringLiteral("科幻"), QStringLiteral("悬疑"), QStringLiteral("神作")}},
        {QStringLiteral("机动战士高达"),
         8.8,
         QStringLiteral("在看"),
         QStringLiteral("人类移居宇宙后，少年阿姆罗与高达卷入一年战争的经典机战作品。"),
         {QStringLiteral("机战"), QStringLiteral("科幻")}},
        {QStringLiteral("四月是你的谎言"),
         9.0,
         QStringLiteral("看完"),
         QStringLiteral("天才小提琴手与钢琴少年在青春与音乐中相遇的感人故事。"),
         {QStringLiteral("校园"), QStringLiteral("音乐"), QStringLiteral("催泪")}},
        {QStringLiteral("Angel Beats!"),
         8.5,
         QStringLiteral("看完"),
         QStringLiteral("死后世界里的少年少女们对抗命运，寻找归宿的奇幻校园剧。"),
         {QStringLiteral("校园"), QStringLiteral("催泪"), QStringLiteral("奇幻")}}
    };

    for (const SampleAnime &sample : samples) {
        AnimeRecord anime;
        anime.title = sample.title;
        anime.score = sample.score;
        anime.status = sample.status;
        anime.description = sample.description;
        anime.tags = sample.tags;
        const int id = DatabaseManager::instance().insertAnime(anime);

        if (id > 0 && sample.title == QStringLiteral("葬送的芙莉莲")) {
            ReviewRecord r1;
            r1.animeId = id;
            r1.date = QStringLiteral("2025-01-01");
            r1.title = QStringLiteral("神作");
            r1.content = QStringLiteral("第一次看就被节奏和情感表达震撼到了。");
            DatabaseManager::instance().insertReview(r1);

            ReviewRecord r2;
            r2.animeId = id;
            r2.date = QStringLiteral("2025-06-01");
            r2.title = QStringLiteral("二刷");
            r2.content = QStringLiteral("二刷发现伏笔真多，细节拉满。");
            DatabaseManager::instance().insertReview(r2);

            ReviewRecord r3;
            r3.animeId = id;
            r3.date = QStringLiteral("2026-02-01");
            r3.title = QStringLiteral("漫画补完");
            r3.content = QStringLiteral("补完漫画后对角色理解更深了。");
            DatabaseManager::instance().insertReview(r3);
        }
    }
}

void AnimeController::linkSampleBangumiIds()
{
    const struct {
        const char *title;
        int bgmId;
    } mappings[] = {
        {"葬送的芙莉莲", 378862},
        {"CLANNAD", 25961},
        {"命运石之门", 29983},
        {"机动战士高达", 975},
        {"四月是你的谎言", 120835},
        {"Angel Beats!", 25990},
    };

    for (const auto &mapping : mappings) {
        const int animeId =
            DatabaseManager::instance().findAnimeIdByTitle(QString::fromUtf8(mapping.title));
        if (animeId <= 0) {
            continue;
        }

        const AnimeRecord anime = DatabaseManager::instance().fetchAnime(animeId);
        if (anime.bgmId <= 0) {
            DatabaseManager::instance().setAnimeBgmId(animeId, mapping.bgmId);
        }
    }
}

bool AnimeController::applyBangumiSync(int localAnimeId, const QVariantMap &data)
{
    if (localAnimeId <= 0) {
        return false;
    }

    AnimeRecord anime = DatabaseManager::instance().fetchAnime(localAnimeId);
    if (anime.id <= 0) {
        return false;
    }

    const QString title = data.value(QStringLiteral("title")).toString();
    if (!title.isEmpty()) {
        anime.title = title;
    }

    const QString description = data.value(QStringLiteral("description")).toString();
    if (!description.isEmpty()) {
        anime.description = description;
    }

    const QString coverPath = data.value(QStringLiteral("coverPath")).toString();
    if (!coverPath.isEmpty()) {
        anime.coverPath = coverPath;
    }

    const int bgmId = data.value(QStringLiteral("bgmId")).toInt();
    if (bgmId > 0) {
        anime.bgmId = bgmId;
    }

    const QStringList tags = parseTags(data.value(QStringLiteral("tags")));
    if (!tags.isEmpty()) {
        anime.tags = tags;
    }

    return DatabaseManager::instance().updateAnime(anime);
}

void AnimeController::syncPendingAnimeFromBangumi(BangumiClient *client)
{
    if (!client) {
        return;
    }

    linkSampleBangumiIds();

    const QVector<int> ids = DatabaseManager::instance().fetchAnimeIdsNeedingBangumiSync();
    if (ids.isEmpty()) {
        emit bangumiSyncCompleted();
        return;
    }

    client->startLocalSync(ids);
}

AnimeRecord AnimeController::mapToAnime(const QVariantMap &data) const
{
    AnimeRecord anime;
    anime.id = data.value(QStringLiteral("animeId"), data.value(QStringLiteral("id"))).toInt();
    anime.title = data.value(QStringLiteral("title")).toString().trimmed();
    anime.score = data.value(QStringLiteral("score")).toDouble();
    anime.status = data.value(QStringLiteral("status"), QStringLiteral("未看")).toString();
    anime.description = data.value(QStringLiteral("description")).toString();
    anime.coverPath = data.value(QStringLiteral("coverPath")).toString();
    anime.bgmId = data.value(QStringLiteral("bgmId")).toInt();
    anime.tags = parseTags(data.value(QStringLiteral("tags")));
    return anime;
}

ReviewRecord AnimeController::mapToReview(const QVariantMap &data) const
{
    ReviewRecord review;
    review.id = data.value(QStringLiteral("reviewId"), data.value(QStringLiteral("id"))).toInt();
    review.animeId = data.value(QStringLiteral("animeId")).toInt();
    review.date = data.value(QStringLiteral("date"), QDate::currentDate().toString(Qt::ISODate))
                      .toString();
    review.title = data.value(QStringLiteral("title")).toString();
    review.content = data.value(QStringLiteral("content")).toString();
    return review;
}

QVariantMap AnimeController::animeToMap(const AnimeRecord &anime) const
{
    QVariantMap map;
    map.insert(QStringLiteral("animeId"), anime.id);
    map.insert(QStringLiteral("title"), anime.title);
    map.insert(QStringLiteral("score"), anime.score);
    map.insert(QStringLiteral("status"), anime.status);
    map.insert(QStringLiteral("description"), anime.description);
    map.insert(QStringLiteral("coverPath"), anime.coverPath);
    map.insert(QStringLiteral("bgmId"), anime.bgmId);
    map.insert(QStringLiteral("tags"), anime.tags);
    return map;
}

QVariantMap AnimeController::reviewToMap(const ReviewRecord &review) const
{
    QVariantMap map;
    map.insert(QStringLiteral("reviewId"), review.id);
    map.insert(QStringLiteral("animeId"), review.animeId);
    map.insert(QStringLiteral("date"), review.date);
    map.insert(QStringLiteral("title"), review.title);
    map.insert(QStringLiteral("content"), review.content);
    return map;
}

QStringList AnimeController::parseTags(const QVariant &value) const
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
