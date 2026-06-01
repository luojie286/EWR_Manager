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

BangumiClient::BangumiClient(const QString &coversDir, QObject *parent)
    : QObject(parent)
    , m_coversDir(coversDir)
{
    QDir().mkpath(m_coversDir);
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
                                           int localAnimeId) const
{
    const QString nameCn = subject.value(QStringLiteral("name_cn")).toString();
    const QString name = subject.value(QStringLiteral("name")).toString();

    QVariantMap data;
    data.insert(QStringLiteral("localAnimeId"), localAnimeId);
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
    filter.insert(QStringLiteral("type"), QJsonArray{2});

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
    importSubjectForLocal(subjectId, 0);
}

void BangumiClient::startLocalSync(const QVector<int> &localAnimeIds)
{
    m_localSyncQueue.clear();
    for (int id : localAnimeIds) {
        m_localSyncQueue.enqueue(id);
    }
    processNextLocalSync();
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

    importSubjectForLocal(anime.bgmId, m_activeLocalSyncId);
}

void BangumiClient::importSubjectForLocal(int subjectId, int localAnimeId)
{
    if (subjectId <= 0) {
        emit errorOccurred(QStringLiteral("无效的 Bangumi 条目 ID"));
        return;
    }

    setBusy(true);

    const QUrl url(QStringLiteral("https://api.bgm.tv/v0/subjects/%1").arg(subjectId));
    QNetworkReply *reply = m_network.get(createRequest(url));

    connect(reply, &QNetworkReply::finished, this, [this, reply, localAnimeId]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            setBusy(false);
            if (localAnimeId > 0) {
                m_activeLocalSyncId = 0;
                processNextLocalSync();
            } else {
                emit errorOccurred(reply->errorString());
            }
            return;
        }

        const QJsonObject subject = QJsonDocument::fromJson(reply->readAll()).object();
        const QString imageUrl = pickImageUrl(subject);
        if (imageUrl.isEmpty()) {
            finishImport(subject, {}, localAnimeId);
            return;
        }

        downloadCover(subject.value(QStringLiteral("id")).toInt(), QUrl(imageUrl), subject,
                      localAnimeId);
    });
}

void BangumiClient::downloadCover(int subjectId, const QUrl &imageUrl, const QJsonObject &subject,
                                  int localAnimeId)
{
    const QString coverPath =
        m_coversDir + QDir::separator() + QString::number(subjectId) + QStringLiteral(".jpg");

    if (QFile::exists(coverPath)) {
        finishImport(subject, coverPath, localAnimeId);
        return;
    }

    QNetworkReply *reply = m_network.get(createRequest(imageUrl));
    connect(reply, &QNetworkReply::finished, this,
            [this, reply, subject, coverPath, localAnimeId]() {
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

                finishImport(subject, savedPath, localAnimeId);
            });
}

void BangumiClient::finishImport(const QJsonObject &subject, const QString &coverPath,
                                 int localAnimeId)
{
    const QVariantMap data = buildImportData(subject, coverPath, localAnimeId);
    setBusy(false);

    if (localAnimeId > 0) {
        emit localSyncFinished(localAnimeId, data);
        m_activeLocalSyncId = 0;
        processNextLocalSync();
    } else {
        emit importFinished(data);
    }
}
