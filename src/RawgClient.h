#pragma once

#include <QJsonArray>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QObject>
#include <QSettings>
#include <QUrl>
#include <QUrlQuery>
#include <QVariantList>
#include <QVariantMap>

#include <functional>

class RawgClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(bool hasApiKey READ hasApiKey NOTIFY apiKeyChanged)

public:
    explicit RawgClient(const QString &coversDir, QObject *parent = nullptr);

    bool busy() const { return m_busy; }
    bool hasApiKey() const { return !m_apiKey.isEmpty(); }

    Q_INVOKABLE void setApiKey(const QString &key);
    Q_INVOKABLE void clearApiKey();
    Q_INVOKABLE void search(const QString &keyword);
    Q_INVOKABLE void importGame(int gameId);

signals:
    void busyChanged();
    void apiKeyChanged();
    void searchFinished(const QVariantList &results);
    void importFinished(const QVariantMap &data);
    void errorOccurred(const QString &message);

private:
    struct ParsedGame {
        int id = 0;
        QString title;
        QString description;
        double score = 0.0;
        QString imageUrl;
        QStringList tags;
    };

    void setBusy(bool busy);
    void loadApiKey();
    QString effectiveApiKey() const;
    QNetworkRequest createRequest(const QUrl &url) const;
    QUrl buildUrl(const QString &path, const QUrlQuery &query = {}) const;

    static bool containsChinese(const QString &text);
    static QStringList parseGenreNames(const QJsonArray &genres);
    static double parseScore(const QJsonObject &game);
    static ParsedGame parseGameDetail(const QJsonObject &game);
    static QVariantList parseSearchResults(const QJsonArray &results);

    void translateTexts(const QStringList &texts, const QString &langPair,
                        const std::function<void(const QStringList &)> &onFinished);
    void downloadCover(int gameId, const QUrl &imageUrl, const ParsedGame &game);
    void finishImport(const ParsedGame &game, const QString &coverPath);

    QNetworkAccessManager m_network;
    QString m_coversDir;
    QString m_apiKey;
    bool m_busy = false;
};
