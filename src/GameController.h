#pragma once

#include "DatabaseManager.h"

#include <QObject>
#include <QStringList>
#include <QVariantMap>

class BangumiClient;

class GameController : public QObject
{
    Q_OBJECT

public:
    explicit GameController(QObject *parent = nullptr);

    Q_INVOKABLE QVariantMap getGame(int id) const;
    Q_INVOKABLE int addGame(const QVariantMap &data);
    Q_INVOKABLE bool updateGame(const QVariantMap &data);
    Q_INVOKABLE bool deleteGame(int id);

    Q_INVOKABLE QVariantMap getReview(int id) const;
    Q_INVOKABLE int addReview(const QVariantMap &data);
    Q_INVOKABLE bool updateReview(const QVariantMap &data);
    Q_INVOKABLE bool deleteReview(int id);

    Q_INVOKABLE QStringList allTags() const;
    Q_INVOKABLE QVariantMap statistics() const;
    Q_INVOKABLE QStringList statusOptions() const;
    Q_INVOKABLE void seedSampleData();

    void linkSampleBangumiIds();
    bool applyBangumiSync(int localGameId, const QVariantMap &data);
    void syncPendingGamesFromBangumi(BangumiClient *client);

signals:
    void bangumiSyncCompleted();

private:
    GameRecord mapToGame(const QVariantMap &data) const;
    GameReviewRecord mapToReview(const QVariantMap &data) const;
    QVariantMap gameToMap(const GameRecord &game) const;
    QVariantMap reviewToMap(const GameReviewRecord &review) const;
    QStringList parseTags(const QVariant &value) const;
};
