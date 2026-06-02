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
    Q_PROPERTY(int subjectType READ subjectType WRITE setSubjectType NOTIFY subjectTypeChanged)

public:
    explicit BangumiClient(const QString &coversDir, int subjectType = 2, QObject *parent = nullptr);

    bool busy() const { return m_busy; }
    int subjectType() const { return m_subjectType; }
    void setSubjectType(int subjectType);

    Q_INVOKABLE void search(const QString &keyword);
    Q_INVOKABLE void importSubject(int subjectId);
    Q_INVOKABLE void startLocalSync(const QVector<int> &localAnimeIds);
    Q_INVOKABLE void startGameLocalSync(const QVector<int> &localGameIds);

signals:
    void busyChanged();
    void subjectTypeChanged();
    void searchFinished(const QVariantList &results);
    void importFinished(const QVariantMap &data);
    void localSyncFinished(int localAnimeId, const QVariantMap &data);
    void gameLocalSyncFinished(int localGameId, const QVariantMap &data);
    void localSyncBatchFinished();
    void gameLocalSyncBatchFinished();
    void errorOccurred(const QString &message);

private:
    enum class SyncKind { Anime, Game };

    void setBusy(bool busy);
    void importSubjectForLocal(int subjectId, int localId, SyncKind kind);
    void processNextLocalSync();
    void processNextGameLocalSync();
    QNetworkRequest createRequest(const QUrl &url, bool jsonBody = false) const;
    QString pickImageUrl(const QJsonObject &subject) const;
    QVariantList parseSearchResults(const QJsonArray &data) const;
    QVariantMap buildImportData(const QJsonObject &subject, const QString &coverPath,
                                int localId = 0) const;
    void finishImport(const QJsonObject &subject, const QString &coverPath, int localId,
                      SyncKind kind);
    void downloadCover(int subjectId, const QUrl &imageUrl, const QJsonObject &subject, int localId,
                       SyncKind kind);

    QNetworkAccessManager m_network;
    QString m_coversDir;
    int m_subjectType = 2;
    bool m_busy = false;
    QQueue<int> m_localSyncQueue;
    QQueue<int> m_gameLocalSyncQueue;
    int m_activeLocalSyncId = 0;
    int m_activeGameLocalSyncId = 0;
};
