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

    QVector<AnimeRecord> fetchAllAnime(const QString &searchText = {},
                                       const QString &statusFilter = {},
                                       const QString &tagFilter = {}) const;
    AnimeRecord fetchAnime(int id) const;
    int insertAnime(const AnimeRecord &anime);
    bool updateAnime(const AnimeRecord &anime);
    bool deleteAnime(int id);

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

private:
    explicit DatabaseManager(QObject *parent = nullptr);
    bool createTables();
    bool migrateSchema();
    QStringList fetchTagsForAnime(int animeId) const;
    int ensureTag(const QString &name) const;

    QSqlDatabase m_db;
    bool m_ready = false;
};
