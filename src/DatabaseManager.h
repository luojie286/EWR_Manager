#pragma once

#include <QObject>
#include <QSqlDatabase>
#include <QString>
#include <QStringList>
#include <QVariantMap>
#include <QVector>

struct AnimeRecord {
    int id = 0;
    QString title;
    double score = 0.0;
    QString status;
    QString description;
    QString coverPath;
    int bgmId = 0;
    QStringList tags;
};

struct ReviewRecord {
    int id = 0;
    int animeId = 0;
    QString date;
    QString title;
    QString content;
};

struct GameRecord {
    int id = 0;
    QString title;
    double score = 0.0;
    QString status;
    QString description;
    QString coverPath;
    int bgmId = 0;
    QStringList tags;
};

struct GameReviewRecord {
    int id = 0;
    int gameId = 0;
    QString date;
    QString title;
    QString content;
};

struct StatisticsRecord {
    int totalCount = 0;
    int finishedCount = 0;
    int watchingCount = 0;
    int plannedCount = 0;
    int droppedCount = 0;
    double averageScore = 0.0;
    QVariantList tagRanking;
};

class DatabaseManager : public QObject
{
    Q_OBJECT

public:
    static DatabaseManager &instance();

    bool initialize(const QString &dbPath);
    bool isReady() const { return m_ready; }
    QString databasePath() const { return m_db.databaseName(); }

    bool isAnimeSampleSeeded() const;
    bool isGameSampleSeeded() const;
    void setAnimeSampleSeeded();
    void setGameSampleSeeded();

    QVector<AnimeRecord> fetchAllAnime(const QString &searchText = {},
                                       const QString &statusFilter = {},
                                       const QString &tagFilter = {}) const;
    AnimeRecord fetchAnime(int id) const;
    int insertAnime(const AnimeRecord &anime);
    bool updateAnime(const AnimeRecord &anime);
    bool deleteAnime(int id);
    bool deleteAnimeBatch(const QVector<int> &ids);

    QVector<ReviewRecord> fetchReviews(int animeId) const;
    ReviewRecord fetchReview(int id) const;
    int insertReview(const ReviewRecord &review);
    bool updateReview(const ReviewRecord &review);
    bool deleteReview(int id);

    QStringList fetchAllTags() const;
    bool setAnimeTags(int animeId, const QStringList &tags);

    StatisticsRecord fetchStatistics() const;

    int findAnimeIdByTitle(const QString &title) const;
    bool setAnimeBgmId(int animeId, int bgmId);
    QVector<int> fetchAnimeIdsNeedingBangumiSync() const;

    QVector<GameRecord> fetchAllGames(const QString &searchText = {},
                                      const QString &statusFilter = {},
                                      const QString &tagFilter = {}) const;
    GameRecord fetchGame(int id) const;
    int insertGame(const GameRecord &game);
    bool updateGame(const GameRecord &game);
    bool deleteGame(int id);
    bool deleteGameBatch(const QVector<int> &ids);

    QVector<GameReviewRecord> fetchGameReviews(int gameId) const;
    GameReviewRecord fetchGameReview(int id) const;
    int insertGameReview(const GameReviewRecord &review);
    bool updateGameReview(const GameReviewRecord &review);
    bool deleteGameReview(int id);

    QStringList fetchAllGameTags() const;
    bool setGameTags(int gameId, const QStringList &tags);

    StatisticsRecord fetchGameStatistics() const;

    void cleanupOrphanRecords();

    int findGameIdByTitle(const QString &title) const;
    bool setGameBgmId(int gameId, int bgmId);
    QVector<int> fetchGameIdsNeedingBangumiSync() const;

private:
    explicit DatabaseManager(QObject *parent = nullptr);
    bool createTables();
    bool migrateSchema();
    bool ensureAppSettingsTable();
    bool appSettingFlag(const QString &key) const;
    void setAppSettingFlag(const QString &key);
    void migrateSampleSeedFlags();
    void enableForeignKeys();
    QStringList fetchTagsForAnime(int animeId) const;
    QStringList fetchTagsForGame(int gameId) const;
    int ensureTag(const QString &name) const;

    QSqlDatabase m_db;
    bool m_ready = false;
    bool m_existingDatabaseFile = false;
};
