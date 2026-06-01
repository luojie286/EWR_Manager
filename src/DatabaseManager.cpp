#include "DatabaseManager.h"

#include <QDate>
#include <QDir>
#include <QFileInfo>
#include <QSqlError>
#include <QSqlQuery>
#include <QVariant>

DatabaseManager &DatabaseManager::instance()
{
    static DatabaseManager manager;
    return manager;
}

DatabaseManager::DatabaseManager(QObject *parent)
    : QObject(parent)
{
}

bool DatabaseManager::initialize(const QString &dbPath)
{
    if (QSqlDatabase::contains(QStringLiteral("anime_connection"))) {
        m_db = QSqlDatabase::database(QStringLiteral("anime_connection"));
    } else {
        m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"),
                                         QStringLiteral("anime_connection"));
    }

    QFileInfo fileInfo(dbPath);
    if (fileInfo.dir().exists() || fileInfo.dir().mkpath(QStringLiteral("."))) {
        m_db.setDatabaseName(dbPath);
    } else {
        return false;
    }

    if (!m_db.open()) {
        return false;
    }

    m_ready = createTables();
    return m_ready;
}

bool DatabaseManager::createTables()
{
    QSqlQuery query(m_db);

    const auto exec = [&](const QString &sql) -> bool {
        if (!query.exec(sql)) {
            return false;
        }
        return true;
    };

    if (!exec(QStringLiteral(
            "CREATE TABLE IF NOT EXISTS anime ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "title TEXT NOT NULL,"
            "score REAL DEFAULT 0,"
            "status TEXT DEFAULT '未看',"
            "description TEXT DEFAULT '',"
            "cover_path TEXT DEFAULT '',"
            "bgm_id INTEGER DEFAULT 0"
            ")"))) {
        return false;
    }

    if (!migrateSchema()) {
        return false;
    }

    if (!exec(QStringLiteral(
            "CREATE TABLE IF NOT EXISTS review ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "anime_id INTEGER NOT NULL,"
            "date TEXT NOT NULL,"
            "title TEXT DEFAULT '',"
            "content TEXT DEFAULT '',"
            "FOREIGN KEY (anime_id) REFERENCES anime(id) ON DELETE CASCADE"
            ")"))) {
        return false;
    }

    if (!exec(QStringLiteral(
            "CREATE TABLE IF NOT EXISTS tag ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "name TEXT NOT NULL UNIQUE"
            ")"))) {
        return false;
    }

    if (!exec(QStringLiteral(
            "CREATE TABLE IF NOT EXISTS anime_tag ("
            "anime_id INTEGER NOT NULL,"
            "tag_id INTEGER NOT NULL,"
            "PRIMARY KEY (anime_id, tag_id),"
            "FOREIGN KEY (anime_id) REFERENCES anime(id) ON DELETE CASCADE,"
            "FOREIGN KEY (tag_id) REFERENCES tag(id) ON DELETE CASCADE"
            ")"))) {
        return false;
    }

    return true;
}

bool DatabaseManager::migrateSchema()
{
    QSqlQuery query(m_db);
    if (!query.exec(QStringLiteral("PRAGMA table_info(anime)"))) {
        return false;
    }

    bool hasBgmId = false;
    while (query.next()) {
        if (query.value(1).toString() == QStringLiteral("bgm_id")) {
            hasBgmId = true;
            break;
        }
    }

    if (!hasBgmId) {
        if (!query.exec(QStringLiteral("ALTER TABLE anime ADD COLUMN bgm_id INTEGER DEFAULT 0"))) {
            return false;
        }
    }

    return true;
}

QVector<AnimeRecord> DatabaseManager::fetchAllAnime(const QString &searchText,
                                                    const QString &statusFilter,
                                                    const QString &tagFilter) const
{
    QVector<AnimeRecord> result;
    if (!m_ready) {
        return result;
    }

    QString sql = QStringLiteral(
        "SELECT DISTINCT a.id, a.title, a.score, a.status, a.description, a.cover_path, a.bgm_id "
        "FROM anime a");

    QStringList conditions;
    if (!tagFilter.isEmpty()) {
        sql += QStringLiteral(
            " JOIN anime_tag at ON a.id = at.anime_id"
            " JOIN tag t ON at.tag_id = t.id");
        conditions << QStringLiteral("t.name = :tagFilter");
    }

    if (!searchText.isEmpty()) {
        conditions << QStringLiteral(
            "(a.title LIKE :search OR a.description LIKE :search)");
    }

    if (!statusFilter.isEmpty() && statusFilter != QStringLiteral("全部")) {
        conditions << QStringLiteral("a.status = :statusFilter");
    }

    if (!conditions.isEmpty()) {
        sql += QStringLiteral(" WHERE ") + conditions.join(QStringLiteral(" AND "));
    }

    sql += QStringLiteral(" ORDER BY a.title COLLATE NOCASE ASC");

    QSqlQuery query(m_db);
    query.prepare(sql);

    if (!searchText.isEmpty()) {
        query.bindValue(QStringLiteral(":search"),
                        QStringLiteral("%%1%").arg(searchText));
    }
    if (!statusFilter.isEmpty() && statusFilter != QStringLiteral("全部")) {
        query.bindValue(QStringLiteral(":statusFilter"), statusFilter);
    }
    if (!tagFilter.isEmpty()) {
        query.bindValue(QStringLiteral(":tagFilter"), tagFilter);
    }

    if (!query.exec()) {
        return result;
    }

    while (query.next()) {
        AnimeRecord anime;
        anime.id = query.value(0).toInt();
        anime.title = query.value(1).toString();
        anime.score = query.value(2).toDouble();
        anime.status = query.value(3).toString();
        anime.description = query.value(4).toString();
        anime.coverPath = query.value(5).toString();
        anime.bgmId = query.value(6).toInt();
        anime.tags = fetchTagsForAnime(anime.id);
        result.append(anime);
    }

    return result;
}

AnimeRecord DatabaseManager::fetchAnime(int id) const
{
    AnimeRecord anime;
    if (!m_ready || id <= 0) {
        return anime;
    }

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "SELECT id, title, score, status, description, cover_path, bgm_id "
        "FROM anime WHERE id = :id"));
    query.bindValue(QStringLiteral(":id"), id);

    if (query.exec() && query.next()) {
        anime.id = query.value(0).toInt();
        anime.title = query.value(1).toString();
        anime.score = query.value(2).toDouble();
        anime.status = query.value(3).toString();
        anime.description = query.value(4).toString();
        anime.coverPath = query.value(5).toString();
        anime.bgmId = query.value(6).toInt();
        anime.tags = fetchTagsForAnime(anime.id);
    }

    return anime;
}

int DatabaseManager::insertAnime(const AnimeRecord &anime)
{
    if (!m_ready) {
        return -1;
    }

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "INSERT INTO anime (title, score, status, description, cover_path, bgm_id) "
        "VALUES (:title, :score, :status, :description, :cover_path, :bgm_id)"));
    query.bindValue(QStringLiteral(":title"), anime.title);
    query.bindValue(QStringLiteral(":score"), anime.score);
    query.bindValue(QStringLiteral(":status"), anime.status);
    query.bindValue(QStringLiteral(":description"), anime.description);
    query.bindValue(QStringLiteral(":cover_path"), anime.coverPath);
    query.bindValue(QStringLiteral(":bgm_id"), anime.bgmId);

    if (!query.exec()) {
        return -1;
    }

    const int id = query.lastInsertId().toInt();
    setAnimeTags(id, anime.tags);
    return id;
}

bool DatabaseManager::updateAnime(const AnimeRecord &anime)
{
    if (!m_ready || anime.id <= 0) {
        return false;
    }

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "UPDATE anime SET title = :title, score = :score, status = :status, "
        "description = :description, cover_path = :cover_path, bgm_id = :bgm_id "
        "WHERE id = :id"));
    query.bindValue(QStringLiteral(":title"), anime.title);
    query.bindValue(QStringLiteral(":score"), anime.score);
    query.bindValue(QStringLiteral(":status"), anime.status);
    query.bindValue(QStringLiteral(":description"), anime.description);
    query.bindValue(QStringLiteral(":cover_path"), anime.coverPath);
    query.bindValue(QStringLiteral(":bgm_id"), anime.bgmId);
    query.bindValue(QStringLiteral(":id"), anime.id);

    if (!query.exec()) {
        return false;
    }

    return setAnimeTags(anime.id, anime.tags);
}

bool DatabaseManager::deleteAnime(int id)
{
    if (!m_ready || id <= 0) {
        return false;
    }

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral("DELETE FROM anime WHERE id = :id"));
    query.bindValue(QStringLiteral(":id"), id);
    return query.exec();
}

QVector<ReviewRecord> DatabaseManager::fetchReviews(int animeId) const
{
    QVector<ReviewRecord> result;
    if (!m_ready || animeId <= 0) {
        return result;
    }

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "SELECT id, anime_id, date, title, content FROM review "
        "WHERE anime_id = :anime_id ORDER BY date DESC, id DESC"));
    query.bindValue(QStringLiteral(":anime_id"), animeId);

    if (!query.exec()) {
        return result;
    }

    while (query.next()) {
        ReviewRecord review;
        review.id = query.value(0).toInt();
        review.animeId = query.value(1).toInt();
        review.date = query.value(2).toString();
        review.title = query.value(3).toString();
        review.content = query.value(4).toString();
        result.append(review);
    }

    return result;
}

ReviewRecord DatabaseManager::fetchReview(int id) const
{
    ReviewRecord review;
    if (!m_ready || id <= 0) {
        return review;
    }

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "SELECT id, anime_id, date, title, content FROM review WHERE id = :id"));
    query.bindValue(QStringLiteral(":id"), id);

    if (query.exec() && query.next()) {
        review.id = query.value(0).toInt();
        review.animeId = query.value(1).toInt();
        review.date = query.value(2).toString();
        review.title = query.value(3).toString();
        review.content = query.value(4).toString();
    }

    return review;
}

int DatabaseManager::insertReview(const ReviewRecord &review)
{
    if (!m_ready || review.animeId <= 0) {
        return -1;
    }

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "INSERT INTO review (anime_id, date, title, content) "
        "VALUES (:anime_id, :date, :title, :content)"));
    query.bindValue(QStringLiteral(":anime_id"), review.animeId);
    query.bindValue(QStringLiteral(":date"),
                    review.date.isEmpty()
                        ? QDate::currentDate().toString(Qt::ISODate)
                        : review.date);
    query.bindValue(QStringLiteral(":title"), review.title);
    query.bindValue(QStringLiteral(":content"), review.content);

    if (!query.exec()) {
        return -1;
    }

    return query.lastInsertId().toInt();
}

bool DatabaseManager::updateReview(const ReviewRecord &review)
{
    if (!m_ready || review.id <= 0) {
        return false;
    }

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "UPDATE review SET date = :date, title = :title, content = :content "
        "WHERE id = :id"));
    query.bindValue(QStringLiteral(":date"), review.date);
    query.bindValue(QStringLiteral(":title"), review.title);
    query.bindValue(QStringLiteral(":content"), review.content);
    query.bindValue(QStringLiteral(":id"), review.id);

    return query.exec();
}

bool DatabaseManager::deleteReview(int id)
{
    if (!m_ready || id <= 0) {
        return false;
    }

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral("DELETE FROM review WHERE id = :id"));
    query.bindValue(QStringLiteral(":id"), id);
    return query.exec();
}

QStringList DatabaseManager::fetchAllTags() const
{
    QStringList tags;
    if (!m_ready) {
        return tags;
    }

    QSqlQuery query(m_db);
    if (!query.exec(QStringLiteral("SELECT name FROM tag ORDER BY name COLLATE NOCASE ASC"))) {
        return tags;
    }

    while (query.next()) {
        tags.append(query.value(0).toString());
    }

    return tags;
}

bool DatabaseManager::setAnimeTags(int animeId, const QStringList &tags)
{
    if (!m_ready || animeId <= 0) {
        return false;
    }

    QSqlQuery deleteQuery(m_db);
    deleteQuery.prepare(QStringLiteral("DELETE FROM anime_tag WHERE anime_id = :anime_id"));
    deleteQuery.bindValue(QStringLiteral(":anime_id"), animeId);
    if (!deleteQuery.exec()) {
        return false;
    }

    for (const QString &tagName : tags) {
        const QString trimmed = tagName.trimmed();
        if (trimmed.isEmpty()) {
            continue;
        }

        const int tagId = ensureTag(trimmed);
        if (tagId <= 0) {
            continue;
        }

        QSqlQuery insertQuery(m_db);
        insertQuery.prepare(QStringLiteral(
            "INSERT OR IGNORE INTO anime_tag (anime_id, tag_id) VALUES (:anime_id, :tag_id)"));
        insertQuery.bindValue(QStringLiteral(":anime_id"), animeId);
        insertQuery.bindValue(QStringLiteral(":tag_id"), tagId);
        if (!insertQuery.exec()) {
            return false;
        }
    }

    return true;
}

StatisticsRecord DatabaseManager::fetchStatistics() const
{
    StatisticsRecord stats;
    if (!m_ready) {
        return stats;
    }

    QSqlQuery query(m_db);
    if (query.exec(QStringLiteral("SELECT COUNT(*) FROM anime")) && query.next()) {
        stats.totalCount = query.value(0).toInt();
    }

    if (query.exec(QStringLiteral("SELECT COUNT(*) FROM anime WHERE status = '看完'"))
        && query.next()) {
        stats.finishedCount = query.value(0).toInt();
    }

    if (query.exec(QStringLiteral("SELECT COUNT(*) FROM anime WHERE status = '在看'"))
        && query.next()) {
        stats.watchingCount = query.value(0).toInt();
    }

    if (query.exec(QStringLiteral("SELECT COUNT(*) FROM anime WHERE status = '未看'"))
        && query.next()) {
        stats.plannedCount = query.value(0).toInt();
    }

    if (query.exec(QStringLiteral("SELECT COUNT(*) FROM anime WHERE status = '弃坑'"))
        && query.next()) {
        stats.droppedCount = query.value(0).toInt();
    }

    if (query.exec(QStringLiteral("SELECT AVG(score) FROM anime WHERE score > 0"))
        && query.next()) {
        stats.averageScore = query.value(0).toDouble();
    }

    if (query.exec(QStringLiteral(
            "SELECT t.name, COUNT(*) AS cnt FROM tag t "
            "JOIN anime_tag at ON t.id = at.tag_id "
            "GROUP BY t.id ORDER BY cnt DESC, t.name COLLATE NOCASE ASC LIMIT 20"))) {
        while (query.next()) {
            QVariantMap item;
            item.insert(QStringLiteral("name"), query.value(0).toString());
            item.insert(QStringLiteral("count"), query.value(1).toInt());
            stats.tagRanking.append(item);
        }
    }

    return stats;
}

QStringList DatabaseManager::fetchTagsForAnime(int animeId) const
{
    QStringList tags;
    if (!m_ready || animeId <= 0) {
        return tags;
    }

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "SELECT t.name FROM tag t "
        "JOIN anime_tag at ON t.id = at.tag_id "
        "WHERE at.anime_id = :anime_id ORDER BY t.name COLLATE NOCASE ASC"));
    query.bindValue(QStringLiteral(":anime_id"), animeId);

    if (!query.exec()) {
        return tags;
    }

    while (query.next()) {
        tags.append(query.value(0).toString());
    }

    return tags;
}

int DatabaseManager::ensureTag(const QString &name) const
{
    QSqlQuery findQuery(m_db);
    findQuery.prepare(QStringLiteral("SELECT id FROM tag WHERE name = :name"));
    findQuery.bindValue(QStringLiteral(":name"), name);
    if (findQuery.exec() && findQuery.next()) {
        return findQuery.value(0).toInt();
    }

    QSqlQuery insertQuery(m_db);
    insertQuery.prepare(QStringLiteral("INSERT INTO tag (name) VALUES (:name)"));
    insertQuery.bindValue(QStringLiteral(":name"), name);
    if (!insertQuery.exec()) {
        return -1;
    }

    return insertQuery.lastInsertId().toInt();
}

int DatabaseManager::findAnimeIdByTitle(const QString &title) const
{
    if (!m_ready || title.isEmpty()) {
        return 0;
    }

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral("SELECT id FROM anime WHERE title = :title LIMIT 1"));
    query.bindValue(QStringLiteral(":title"), title);
    if (query.exec() && query.next()) {
        return query.value(0).toInt();
    }
    return 0;
}

bool DatabaseManager::setAnimeBgmId(int animeId, int bgmId)
{
    if (!m_ready || animeId <= 0 || bgmId <= 0) {
        return false;
    }

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral("UPDATE anime SET bgm_id = :bgm_id WHERE id = :id"));
    query.bindValue(QStringLiteral(":bgm_id"), bgmId);
    query.bindValue(QStringLiteral(":id"), animeId);
    return query.exec();
}

QVector<int> DatabaseManager::fetchAnimeIdsNeedingBangumiSync() const
{
    QVector<int> ids;
    if (!m_ready) {
        return ids;
    }

    QSqlQuery query(m_db);
    if (!query.exec(QStringLiteral(
            "SELECT id FROM anime WHERE bgm_id > 0 AND (cover_path IS NULL OR cover_path = '') "
            "ORDER BY id ASC"))) {
        return ids;
    }

    while (query.next()) {
        ids.append(query.value(0).toInt());
    }
    return ids;
}
