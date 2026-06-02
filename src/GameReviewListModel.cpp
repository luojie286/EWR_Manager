#include "GameReviewListModel.h"

#include "DatabaseManager.h"

GameReviewListModel::GameReviewListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int GameReviewListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }
    return m_items.size();
}

QVariant GameReviewListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size()) {
        return {};
    }

    const ReviewItem &item = m_items.at(index.row());
    switch (role) {
    case IdRole:
        return item.id;
    case GameIdRole:
        return item.gameId;
    case DateRole:
        return item.date;
    case TitleRole:
        return item.title;
    case ContentRole:
        return item.content;
    default:
        return {};
    }
}

QHash<int, QByteArray> GameReviewListModel::roleNames() const
{
    return {
        {IdRole, "reviewId"},
        {GameIdRole, "gameId"},
        {DateRole, "date"},
        {TitleRole, "title"},
        {ContentRole, "content"}
    };
}

void GameReviewListModel::setGameId(int gameId)
{
    if (m_gameId == gameId) {
        return;
    }
    m_gameId = gameId;
    emit gameIdChanged();
    refresh();
}

void GameReviewListModel::refresh()
{
    beginResetModel();
    m_items.clear();

    if (m_gameId > 0) {
        const QVector<GameReviewRecord> records =
            DatabaseManager::instance().fetchGameReviews(m_gameId);

        m_items.reserve(records.size());
        for (const GameReviewRecord &record : records) {
            ReviewItem item;
            item.id = record.id;
            item.gameId = record.gameId;
            item.date = record.date;
            item.title = record.title;
            item.content = record.content;
            m_items.append(item);
        }
    }

    endResetModel();
}

QVariantMap GameReviewListModel::get(int index) const
{
    QVariantMap map;
    if (index < 0 || index >= m_items.size()) {
        return map;
    }

    const ReviewItem &item = m_items.at(index);
    map.insert(QStringLiteral("reviewId"), item.id);
    map.insert(QStringLiteral("gameId"), item.gameId);
    map.insert(QStringLiteral("date"), item.date);
    map.insert(QStringLiteral("title"), item.title);
    map.insert(QStringLiteral("content"), item.content);
    return map;
}
