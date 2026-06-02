#include "GameListModel.h"

#include "DatabaseManager.h"

GameListModel::GameListModel(QObject *parent)
    : QAbstractListModel(parent)
{
    refresh();
}

int GameListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }
    return m_items.size();
}

QVariant GameListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size()) {
        return {};
    }

    const GameItem &item = m_items.at(index.row());
    switch (role) {
    case IdRole:
        return item.id;
    case TitleRole:
        return item.title;
    case ScoreRole:
        return item.score;
    case StatusRole:
        return item.status;
    case DescriptionRole:
        return item.description;
    case CoverPathRole:
        return item.coverPath;
    case TagsRole:
        return item.tags;
    default:
        return {};
    }
}

QHash<int, QByteArray> GameListModel::roleNames() const
{
    return {
        {IdRole, "gameId"},
        {TitleRole, "title"},
        {ScoreRole, "score"},
        {StatusRole, "status"},
        {DescriptionRole, "description"},
        {CoverPathRole, "coverPath"},
        {TagsRole, "tags"}
    };
}

void GameListModel::setSearchText(const QString &text)
{
    if (m_searchText == text) {
        return;
    }
    m_searchText = text;
    emit searchTextChanged();
    refresh();
}

void GameListModel::setStatusFilter(const QString &filter)
{
    if (m_statusFilter == filter) {
        return;
    }
    m_statusFilter = filter;
    emit statusFilterChanged();
    refresh();
}

void GameListModel::setTagFilter(const QString &filter)
{
    if (m_tagFilter == filter) {
        return;
    }
    m_tagFilter = filter;
    emit tagFilterChanged();
    refresh();
}

void GameListModel::refresh()
{
    beginResetModel();
    m_items.clear();

    const QVector<GameRecord> records =
        DatabaseManager::instance().fetchAllGames(m_searchText, m_statusFilter, m_tagFilter);

    m_items.reserve(records.size());
    for (const GameRecord &record : records) {
        GameItem item;
        item.id = record.id;
        item.title = record.title;
        item.score = record.score;
        item.status = record.status;
        item.description = record.description;
        item.coverPath = record.coverPath;
        item.tags = record.tags;
        m_items.append(item);
    }

    endResetModel();
}

QVariantMap GameListModel::get(int index) const
{
    QVariantMap map;
    if (index < 0 || index >= m_items.size()) {
        return map;
    }

    const GameItem &item = m_items.at(index);
    map.insert(QStringLiteral("gameId"), item.id);
    map.insert(QStringLiteral("title"), item.title);
    map.insert(QStringLiteral("score"), item.score);
    map.insert(QStringLiteral("status"), item.status);
    map.insert(QStringLiteral("description"), item.description);
    map.insert(QStringLiteral("coverPath"), item.coverPath);
    map.insert(QStringLiteral("tags"), item.tags);
    return map;
}
