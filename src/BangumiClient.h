#pragma once

#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QObject>
#include <QQueue>
#include <QVariantList>
#include <QVariantMap>
#include <QVector>

class BangumiClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)

public:
    explicit BangumiClient(const QString &coversDir, QObject *parent = nullptr);

    bool busy() const { return m_busy; }

    Q_INVOKABLE void search(const QString &keyword);
    Q_INVOKABLE void importSubject(int subjectId);
    Q_INVOKABLE void startLocalSync(const QVector<int> &localAnimeIds);

signals:
    void busyChanged();
    void searchFinished(const QVariantList &results);
    void importFinished(const QVariantMap &data);
    void localSyncFinished(int localAnimeId, const QVariantMap &data);
    void localSyncBatchFinished();
    void errorOccurred(const QString &message);

private:
    void setBusy(bool busy);
    void importSubjectForLocal(int subjectId, int localAnimeId);
    void processNextLocalSync();
    QNetworkRequest createRequest(const QUrl &url, bool jsonBody = false) const;
    QString pickImageUrl(const QJsonObject &subject) const;
    QVariantList parseSearchResults(const QJsonArray &data) const;
    QVariantMap buildImportData(const QJsonObject &subject, const QString &coverPath,
                                int localAnimeId = 0) const;
    void finishImport(const QJsonObject &subject, const QString &coverPath, int localAnimeId);
    void downloadCover(int subjectId, const QUrl &imageUrl, const QJsonObject &subject,
                       int localAnimeId);

    QNetworkAccessManager m_network;
    QString m_coversDir;
    bool m_busy = false;
    QQueue<int> m_localSyncQueue;
    int m_activeLocalSyncId = 0;
};
