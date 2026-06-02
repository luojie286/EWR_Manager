#include "BangumiClient.h"

#include "DatabaseManager.h"

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrl>

BangumiClient::BangumiClient(const QString &coversDir, int subjectType, QObject *parent)
    : QObject(parent)
    , m_coversDir(coversDir)
    , m_subjectType(subjectType)
{
    QDir().mkpath(m_coversDir);
}

void BangumiClient::setSubjectType(int subjectType)
{
    if (m_subjectType == subjectType) {
        return;
    }
    m_subjectType = subjectType;
    emit subjectTypeChanged();
}

void BangumiClient::setBusy(bool busy)
{
    if (m_busy == busy) {
        return;
    }
    m_busy = busy;
    emit busyChanged();
}

QNetworkRequest BangumiClient::createRequest(const QUrl &url, bool jsonBody) const
{
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::UserAgentHeader,
                      QStringLiteral("EWR_Manager/1.0 (personal anime manager)"));
    if (jsonBody) {
        request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    }
    return request;
}

QString BangumiClient::pickImageUrl(const QJsonObject &subject) const
{
    const QJsonObject images = subject.value(QStringLiteral("images")).toObject();
    const QStringList keys = {QStringLiteral("large"), QStringLiteral("common"),
                              QStringLiteral("medium"), QStringLiteral("grid"),
                              QStringLiteral("small")};
    for (const QString &key : keys) {
        const QString url = images.value(key).toString();
        if (!url.isEmpty()) {
            return url;
        }
    }
    return {};
}

QVariantList BangumiClient::parseSearchResults(const QJsonArray &data) const
{
    QVariantList results;
    results.reserve(data.size());

    for (const QJsonValue &value : data) {
        const QJsonObject obj = value.toObject();
        const QString nameCn = obj.value(QStringLiteral("name_cn")).toString();
        const QString name = obj.value(QStringLiteral("name")).toString();

        QVariantMap item;
        item.insert(QStringLiteral("subjectId"), obj.value(QStringLiteral("id")).toInt());
        item.insert(QStringLiteral("title"), nameCn.isEmpty() ? name : nameCn);
        item.insert(QStringLiteral("subtitle"), nameCn.isEmpty() ? QString() : name);
        item.insert(QStringLiteral("date"), obj.value(QStringLiteral("date")).toString());

        const QJsonObject rating = obj.value(QStringLiteral("rating")).toObject();
        item.insert(QStringLiteral("bangumiScore"), rating.value(QStringLiteral("score")).toDouble());

        const QJsonObject images = obj.value(QStringLiteral("images")).toObject();
        QString imageUrl = images.value(QStringLiteral("small")).toString();
        if (imageUrl.isEmpty()) {
            imageUrl = images.value(QStringLiteral("grid")).toString();
        }
        item.insert(QStringLiteral("imageUrl"), imageUrl);

        results.append(item);
    }

    return results;
}

QVariantMap BangumiClient::buildImportData(const QJsonObject &subject, const QString &coverPath,
                                           int localId) const
{
    const QString nameCn = subject.value(QStringLiteral("name_cn")).toString();
    const QString name = subject.value(QStringLiteral("name")).toString();

    QVariantMap data;
    data.insert(QStringLiteral("localAnimeId"), localId);
    data.insert(QStringLiteral("localGameId"), localId);
    data.insert(QStringLiteral("bgmId"), subject.value(QStringLiteral("id")).toInt());
    data.insert(QStringLiteral("title"), nameCn.isEmpty() ? name : nameCn);
    data.insert(QStringLiteral("description"), subject.value(QStringLiteral("summary")).toString());

    const QJsonObject rating = subject.value(QStringLiteral("rating")).toObject();
    data.insert(QStringLiteral("score"), rating.value(QStringLiteral("score")).toDouble());

    QStringList tags;
    const QJsonArray tagArray = subject.value(QStringLiteral("tags")).toArray();
    for (const QJsonValue &tagValue : tagArray) {
        const QString tagName = tagValue.toObject().value(QStringLiteral("name")).toString();
        if (!tagName.isEmpty()) {
            tags.append(tagName);
        }
    }
    data.insert(QStringLiteral("tags"), tags);
    data.insert(QStringLiteral("coverPath"), coverPath);
    return data;
}

void BangumiClient::search(const QString &keyword)
{
    const QString trimmed = keyword.trimmed();
    if (trimmed.isEmpty()) {
        emit errorOccurred(QStringLiteral("请输入搜索关键词"));
        return;
    }

    setBusy(true);

    QJsonObject filter;
    filter.insert(QStringLiteral("type"), QJsonArray{m_subjectType});

    QJsonObject body;
    body.insert(QStringLiteral("keyword"), trimmed);
    body.insert(QStringLiteral("filter"), filter);

    const QUrl url(QStringLiteral("https://api.bgm.tv/v0/search/subjects"));
    QNetworkReply *reply =
        m_network.post(createRequest(url, true), QJsonDocument(body).toJson(QJsonDocument::Compact));

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        setBusy(false);

        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            return;
        }

        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        const QJsonArray data = doc.object().value(QStringLiteral("data")).toArray();
        emit searchFinished(parseSearchResults(data));
    });
}

void BangumiClient::importSubject(int subjectId)
{
    const SyncKind kind = m_subjectType == 4 ? SyncKind::Game : SyncKind::Anime;
    importSubjectForLocal(subjectId, 0, kind);
}

void BangumiClient::startLocalSync(const QVector<int> &localAnimeIds)
{
    m_localSyncQueue.clear();
    for (int id : localAnimeIds) {
        m_localSyncQueue.enqueue(id);
    }
    processNextLocalSync();
}

void BangumiClient::startGameLocalSync(const QVector<int> &localGameIds)
{
    m_gameLocalSyncQueue.clear();
    for (int id : localGameIds) {
        m_gameLocalSyncQueue.enqueue(id);
    }
    processNextGameLocalSync();
}

void BangumiClient::processNextLocalSync()
{
    if (m_busy || m_localSyncQueue.isEmpty()) {
        if (!m_busy && m_localSyncQueue.isEmpty() && m_activeLocalSyncId == 0) {
            emit localSyncBatchFinished();
        }
        return;
    }

    m_activeLocalSyncId = m_localSyncQueue.dequeue();
    const AnimeRecord anime = DatabaseManager::instance().fetchAnime(m_activeLocalSyncId);
    if (anime.bgmId <= 0) {
        m_activeLocalSyncId = 0;
        processNextLocalSync();
        return;
    }

    importSubjectForLocal(anime.bgmId, m_activeLocalSyncId, SyncKind::Anime);
}

void BangumiClient::processNextGameLocalSync()
{
    if (m_busy || m_gameLocalSyncQueue.isEmpty()) {
        if (!m_busy && m_gameLocalSyncQueue.isEmpty() && m_activeGameLocalSyncId == 0) {
            emit gameLocalSyncBatchFinished();
        }
        return;
    }

    m_activeGameLocalSyncId = m_gameLocalSyncQueue.dequeue();
    const GameRecord game = DatabaseManager::instance().fetchGame(m_activeGameLocalSyncId);
    if (game.bgmId <= 0) {
        m_activeGameLocalSyncId = 0;
        processNextGameLocalSync();
        return;
    }

    importSubjectForLocal(game.bgmId, m_activeGameLocalSyncId, SyncKind::Game);
}

void BangumiClient::importSubjectForLocal(int subjectId, int localId, SyncKind kind)
{
    if (subjectId <= 0) {
        emit errorOccurred(QStringLiteral("无效的 Bangumi 条目 ID"));
        return;
    }

    setBusy(true);

    const QUrl url(QStringLiteral("https://api.bgm.tv/v0/subjects/%1").arg(subjectId));
    QNetworkReply *reply = m_network.get(createRequest(url));

    connect(reply, &QNetworkReply::finished, this, [this, reply, localId, kind]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            setBusy(false);
            if (localId > 0) {
                if (kind == SyncKind::Game) {
                    m_activeGameLocalSyncId = 0;
                    processNextGameLocalSync();
                } else {
                    m_activeLocalSyncId = 0;
                    processNextLocalSync();
                }
            } else {
                emit errorOccurred(reply->errorString());
            }
            return;
        }

        const QJsonObject subject = QJsonDocument::fromJson(reply->readAll()).object();
        const QString imageUrl = pickImageUrl(subject);
        if (imageUrl.isEmpty()) {
            finishImport(subject, {}, localId, kind);
            return;
        }

        downloadCover(subject.value(QStringLiteral("id")).toInt(), QUrl(imageUrl), subject,
                      localId, kind);
    });
}

void BangumiClient::downloadCover(int subjectId, const QUrl &imageUrl, const QJsonObject &subject,
                                  int localId, SyncKind kind)
{
    const QString coverPath =
        m_coversDir + QDir::separator() + QString::number(subjectId) + QStringLiteral(".jpg");

    if (QFile::exists(coverPath)) {
        finishImport(subject, coverPath, localId, kind);
        return;
    }

    QNetworkReply *reply = m_network.get(createRequest(imageUrl));
    connect(reply, &QNetworkReply::finished, this,
            [this, reply, subject, coverPath, localId, kind]() {
                reply->deleteLater();

                QString savedPath;
                if (reply->error() == QNetworkReply::NoError) {
                    QFile file(coverPath);
                    if (file.open(QIODevice::WriteOnly)) {
                        file.write(reply->readAll());
                        file.close();
                        savedPath = coverPath;
                    }
                }

                finishImport(subject, savedPath, localId, kind);
            });
}

void BangumiClient::finishImport(const QJsonObject &subject, const QString &coverPath,
                                 int localId, SyncKind kind)
{
    const QVariantMap data = buildImportData(subject, coverPath, localId);
    setBusy(false);

    if (localId > 0) {
        if (kind == SyncKind::Game) {
            emit gameLocalSyncFinished(localId, data);
            m_activeGameLocalSyncId = 0;
            processNextGameLocalSync();
        } else {
            emit localSyncFinished(localId, data);
            m_activeLocalSyncId = 0;
            processNextLocalSync();
        }
    } else {
        emit importFinished(data);
    }
}
