#pragma once

#include "DatabaseManager.h"

#include <QObject>
#include <QStringList>
#include <QVariantMap>

class BangumiClient;

class AnimeController : public QObject
{
    Q_OBJECT

public:
    explicit AnimeController(QObject *parent = nullptr);

    Q_INVOKABLE QVariantMap getAnime(int id) const;
    Q_INVOKABLE int addAnime(const QVariantMap &data);
    Q_INVOKABLE bool updateAnime(const QVariantMap &data);
    Q_INVOKABLE bool deleteAnime(int id);
    Q_INVOKABLE bool deleteAnimeBatch(const QVariantList &ids);

    Q_INVOKABLE QVariantMap getReview(int id) const;
    Q_INVOKABLE int addReview(const QVariantMap &data);
    Q_INVOKABLE bool updateReview(const QVariantMap &data);
    Q_INVOKABLE bool deleteReview(int id);

    Q_INVOKABLE QStringList allTags() const;
    Q_INVOKABLE QVariantMap statistics() const;
    Q_INVOKABLE QStringList statusOptions() const;
    Q_INVOKABLE void seedSampleData();
    Q_INVOKABLE void cleanupDatabase() const;

    void linkSampleBangumiIds();
    bool applyBangumiSync(int localAnimeId, const QVariantMap &data);
    void syncPendingAnimeFromBangumi(BangumiClient *client);

signals:
    void bangumiSyncCompleted();

private:
    AnimeRecord mapToAnime(const QVariantMap &data) const;
    ReviewRecord mapToReview(const QVariantMap &data) const;
    QVariantMap animeToMap(const AnimeRecord &anime) const;
    QVariantMap reviewToMap(const ReviewRecord &review) const;
    QStringList parseTags(const QVariant &value) const;
};
