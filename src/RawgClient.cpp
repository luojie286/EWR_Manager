#include "RawgClient.h"

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QRegularExpression>
#include <QUrlQuery>

#include <functional>
#include <memory>

namespace {

constexpr int kTranslateChunkSize = 450;

bool containsChinese(const QString &text)
{
    for (const QChar &ch : text) {
        const ushort code = ch.unicode();
        if (code >= 0x4E00 && code <= 0x9FFF) {
            return true;
        }
    }
    return false;
}

QString stripHtml(const QString &html)
{
    QString text = html;
    text.replace(QRegularExpression(QStringLiteral("<[^>]+>")), QStringLiteral(" "));
    text.replace(QRegularExpression(QStringLiteral("\\s+")), QStringLiteral(" "));
    return text.trimmed();
}

} // namespace

RawgClient::RawgClient(const QString &coversDir, QObject *parent)
    : QObject(parent)
    , m_coversDir(coversDir)
{
    QDir().mkpath(m_coversDir);
    loadApiKey();
}

void RawgClient::loadApiKey()
{
    const QSettings settings;
    m_apiKey = settings.value(QStringLiteral("rawg/apiKey")).toString().trimmed();
    if (m_apiKey.isEmpty()) {
        m_apiKey = QString::fromUtf8(qgetenv("RAWG_API_KEY")).trimmed();
    }
}

void RawgClient::setApiKey(const QString &key)
{
    const QString trimmed = key.trimmed();
    if (m_apiKey == trimmed) {
        return;
    }

    m_apiKey = trimmed;
    QSettings settings;
    if (m_apiKey.isEmpty()) {
        settings.remove(QStringLiteral("rawg/apiKey"));
    } else {
        settings.setValue(QStringLiteral("rawg/apiKey"), m_apiKey);
    }
    emit apiKeyChanged();
}

void RawgClient::clearApiKey()
{
    if (m_apiKey.isEmpty()) {
        return;
    }

    m_apiKey.clear();
    QSettings settings;
    settings.remove(QStringLiteral("rawg/apiKey"));
    emit apiKeyChanged();
}

void RawgClient::setBusy(bool busy)
{
    if (m_busy == busy) {
        return;
    }
    m_busy = busy;
    emit busyChanged();
}

QString RawgClient::effectiveApiKey() const
{
    return m_apiKey;
}

QNetworkRequest RawgClient::createRequest(const QUrl &url) const
{
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::UserAgentHeader,
                      QStringLiteral("EWR_Manager/1.0 (personal game library)"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    return request;
}

QUrl RawgClient::buildUrl(const QString &path, const QUrlQuery &query) const
{
    QUrl url(QStringLiteral("https://api.rawg.io/api/") + path);
    QUrlQuery finalQuery = query;
    finalQuery.addQueryItem(QStringLiteral("key"), effectiveApiKey());
    url.setQuery(finalQuery);
    return url;
}

bool RawgClient::containsChinese(const QString &text)
{
    return ::containsChinese(text);
}

QStringList RawgClient::parseGenreNames(const QJsonArray &genres)
{
    QStringList names;
    for (const QJsonValue &value : genres) {
        const QString name = value.toObject().value(QStringLiteral("name")).toString().trimmed();
        if (!name.isEmpty() && !names.contains(name)) {
            names.append(name);
        }
    }
    return names;
}

double RawgClient::parseScore(const QJsonObject &game)
{
    const int metacritic = game.value(QStringLiteral("metacritic")).toInt();
    if (metacritic > 0) {
        return metacritic / 10.0;
    }

    const double rating = game.value(QStringLiteral("rating")).toDouble();
    if (rating > 0.0) {
        return rating * 2.0;
    }

    return 0.0;
}

RawgClient::ParsedGame RawgClient::parseGameDetail(const QJsonObject &game)
{
    ParsedGame parsed;
    parsed.id = game.value(QStringLiteral("id")).toInt();
    parsed.title = game.value(QStringLiteral("name")).toString().trimmed();

    QString description = game.value(QStringLiteral("description_raw")).toString().trimmed();
    if (description.isEmpty()) {
        description = stripHtml(game.value(QStringLiteral("description")).toString());
    }
    parsed.description = description.left(1200);
    parsed.score = parseScore(game);
    parsed.imageUrl = game.value(QStringLiteral("background_image")).toString().trimmed();
    parsed.tags = parseGenreNames(game.value(QStringLiteral("genres")).toArray());
    return parsed;
}

QVariantList RawgClient::parseSearchResults(const QJsonArray &results)
{
    QVariantList list;
    list.reserve(results.size());

    for (const QJsonValue &value : results) {
        const QJsonObject game = value.toObject();
        const int id = game.value(QStringLiteral("id")).toInt();
        if (id <= 0) {
            continue;
        }

        QVariantMap item;
        item.insert(QStringLiteral("gameId"), id);
        item.insert(QStringLiteral("title"), game.value(QStringLiteral("name")).toString());
        item.insert(QStringLiteral("released"), game.value(QStringLiteral("released")).toString());
        item.insert(QStringLiteral("imageUrl"), game.value(QStringLiteral("background_image")).toString());

        const int metacritic = game.value(QStringLiteral("metacritic")).toInt();
        const double rating = game.value(QStringLiteral("rating")).toDouble();
        item.insert(QStringLiteral("metacritic"), metacritic);
        item.insert(QStringLiteral("rating"), rating);

        const QStringList genres = parseGenreNames(game.value(QStringLiteral("genres")).toArray());
        item.insert(QStringLiteral("genres"), genres.join(QStringLiteral(", ")));

        list.append(item);
    }

    return list;
}

void RawgClient::search(const QString &keyword)
{
    const QString trimmed = keyword.trimmed();
    if (trimmed.isEmpty()) {
        emit errorOccurred(QStringLiteral("请输入搜索关键词"));
        return;
    }

    if (effectiveApiKey().isEmpty()) {
        emit errorOccurred(QStringLiteral("请先填写 RAWG API Key（在 rawg.io 免费注册获取）"));
        return;
    }

    setBusy(true);

    const auto performSearch = [this](const QString &query) {
        QUrlQuery urlQuery;
        urlQuery.addQueryItem(QStringLiteral("search"), query);
        urlQuery.addQueryItem(QStringLiteral("page_size"), QStringLiteral("20"));

        const QUrl url = buildUrl(QStringLiteral("games"), urlQuery);
        QNetworkReply *reply = m_network.get(createRequest(url));

        connect(reply, &QNetworkReply::finished, this, [this, reply]() {
            reply->deleteLater();
            setBusy(false);

            if (reply->error() != QNetworkReply::NoError) {
                emit errorOccurred(reply->errorString());
                return;
            }

            const QJsonObject root = QJsonDocument::fromJson(reply->readAll()).object();
            const QVariantList results =
                parseSearchResults(root.value(QStringLiteral("results")).toArray());
            if (results.isEmpty()) {
                emit errorOccurred(QStringLiteral("未找到匹配的游戏"));
                return;
            }

            emit searchFinished(results);
        });
    };

    if (containsChinese(trimmed)) {
        translateTexts({trimmed}, QStringLiteral("zh-CN|en"), [this, performSearch](const QStringList &translated) {
            const QString englishQuery =
                translated.isEmpty() ? QString() : translated.first().trimmed();
            if (englishQuery.isEmpty()) {
                setBusy(false);
                emit errorOccurred(QStringLiteral("无法翻译搜索关键词，请尝试英文游戏名"));
                return;
            }
            setBusy(true);
            performSearch(englishQuery);
        });
        return;
    }

    performSearch(trimmed);
}

void RawgClient::importGame(int gameId)
{
    if (gameId <= 0) {
        emit errorOccurred(QStringLiteral("无效的游戏 ID"));
        return;
    }

    if (effectiveApiKey().isEmpty()) {
        emit errorOccurred(QStringLiteral("请先填写 RAWG API Key"));
        return;
    }

    setBusy(true);

    const QUrl url = buildUrl(QStringLiteral("games/") + QString::number(gameId));
    QNetworkReply *reply = m_network.get(createRequest(url));

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            setBusy(false);
            emit errorOccurred(reply->errorString());
            return;
        }

        const ParsedGame game =
            parseGameDetail(QJsonDocument::fromJson(reply->readAll()).object());
        if (game.id <= 0 || game.title.isEmpty()) {
            setBusy(false);
            emit errorOccurred(QStringLiteral("无法解析游戏详情"));
            return;
        }

        QStringList toTranslate;
        toTranslate << game.title;
        if (!game.description.isEmpty() && !containsChinese(game.description)) {
            toTranslate << game.description.left(kTranslateChunkSize);
        }
        for (const QString &tag : game.tags) {
            if (!containsChinese(tag)) {
                toTranslate << tag;
            }
        }

        translateTexts(toTranslate, QStringLiteral("en|zh-CN"), [this, game](const QStringList &translated) {
            ParsedGame localized = game;
            int index = 0;
            if (!translated.isEmpty()) {
                localized.title = translated.at(index++);
            }
            if (!game.description.isEmpty() && !containsChinese(game.description)
                && index < translated.size()) {
                localized.description = translated.at(index++);
            }

            localized.tags.clear();
            for (const QString &tag : game.tags) {
                if (containsChinese(tag)) {
                    localized.tags.append(tag);
                } else if (index < translated.size()) {
                    localized.tags.append(translated.at(index++));
                } else {
                    localized.tags.append(tag);
                }
            }

            if (localized.imageUrl.isEmpty()) {
                finishImport(localized, {});
                return;
            }

            downloadCover(localized.id, QUrl(localized.imageUrl), localized);
        });
    });
}

void RawgClient::translateTexts(const QStringList &texts, const QString &langPair,
                                const std::function<void(const QStringList &)> &onFinished)
{
    if (texts.isEmpty()) {
        onFinished({});
        return;
    }

    struct TranslateState : std::enable_shared_from_this<TranslateState> {
        RawgClient *client = nullptr;
        QString langPair;
        QStringList sources;
        QStringList translated;
        std::function<void(const QStringList &)> onFinished;
        int index = 0;

        void advance()
        {
            while (index < sources.size()) {
                const QString source = sources.at(index);
                if (source.trimmed().isEmpty() || containsChinese(source)) {
                    translated.append(source);
                    ++index;
                    continue;
                }

                QUrl url(QStringLiteral("https://api.mymemory.translated.net/get"));
                QUrlQuery query;
                query.addQueryItem(QStringLiteral("q"), source);
                query.addQueryItem(QStringLiteral("langpair"), langPair);
                url.setQuery(query);

                const std::shared_ptr<TranslateState> self = shared_from_this();
                QNetworkReply *reply = client->m_network.get(QNetworkRequest(url));
                QObject::connect(reply, &QNetworkReply::finished, client,
                                 [self, reply, source]() {
                                     reply->deleteLater();

                                     QString result = source;
                                     if (reply->error() == QNetworkReply::NoError) {
                                         const QJsonObject response =
                                             QJsonDocument::fromJson(reply->readAll()).object();
                                         const QString translatedText =
                                             response.value(QStringLiteral("responseData"))
                                                 .toObject()
                                                 .value(QStringLiteral("translatedText"))
                                                 .toString()
                                                 .trimmed();
                                         if (!translatedText.isEmpty()) {
                                             result = translatedText;
                                         }
                                     }

                                     self->translated.append(result);
                                     ++self->index;
                                     self->advance();
                                 });
                return;
            }

            onFinished(translated);
        }
    };

    const auto state = std::make_shared<TranslateState>();
    state->client = this;
    state->langPair = langPair;
    state->sources = texts;
    state->onFinished = onFinished;
    state->advance();
}

void RawgClient::downloadCover(int gameId, const QUrl &imageUrl, const ParsedGame &game)
{
    const QString coverPath = m_coversDir + QDir::separator() + QStringLiteral("rawg_")
                              + QString::number(gameId) + QStringLiteral(".jpg");

    if (QFile::exists(coverPath)) {
        finishImport(game, coverPath);
        return;
    }

    QNetworkReply *reply = m_network.get(QNetworkRequest(imageUrl));
    connect(reply, &QNetworkReply::finished, this, [this, reply, game, coverPath]() {
        reply->deleteLater();

        QString savedPath;
        if (reply->error() == QNetworkReply::NoError) {
            const QByteArray data = reply->readAll();
            if (!data.isEmpty()) {
                QFile file(coverPath);
                if (file.open(QIODevice::WriteOnly)) {
                    file.write(data);
                    file.close();
                    savedPath = coverPath;
                }
            }
        }

        finishImport(game, savedPath);
    });
}

void RawgClient::finishImport(const ParsedGame &game, const QString &coverPath)
{
    QVariantMap data;
    data.insert(QStringLiteral("title"), game.title);
    data.insert(QStringLiteral("description"), game.description);
    data.insert(QStringLiteral("score"), game.score);
    data.insert(QStringLiteral("tags"), game.tags);
    data.insert(QStringLiteral("coverPath"), coverPath);
    data.insert(QStringLiteral("bgmId"), game.id);

    setBusy(false);
    emit importFinished(data);
}
