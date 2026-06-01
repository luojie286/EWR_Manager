#include "AnimeListModel.h"

#include "DatabaseManager.h"

AnimeListModel::AnimeListModel(QObject *parent)
    : QAbstractListModel(parent)
{
    refresh();
}

int AnimeListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }
    return m_items.size();
}

QVariant AnimeListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size()) {
        return {};
    }

    const AnimeItem &item = m_items.at(index.row());
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

QHash<int, QByteArray> AnimeListModel::roleNames() const
{
    return {
        {IdRole, "animeId"},
        {TitleRole, "title"},
        {ScoreRole, "score"},
        {StatusRole, "status"},
        {DescriptionRole, "description"},
        {CoverPathRole, "coverPath"},
        {TagsRole, "tags"}
    };
}

void AnimeListModel::setSearchText(const QString &text)
{
    if (m_searchText == text) {
        return;
    }
    m_searchText = text;
    emit searchTextChanged();
    refresh();
}

void AnimeListModel::setStatusFilter(const QString &filter)
{
    if (m_statusFilter == filter) {
        return;
    }
    m_statusFilter = filter;
    emit statusFilterChanged();
    refresh();
}

void AnimeListModel::setTagFilter(const QString &filter)
{
    if (m_tagFilter == filter) {
        return;
    }
    m_tagFilter = filter;
    emit tagFilterChanged();
    refresh();
}

void AnimeListModel::refresh()
{
    beginResetModel();
    m_items.clear();

    const QVector<AnimeRecord> records =
        DatabaseManager::instance().fetchAllAnime(m_searchText, m_statusFilter, m_tagFilter);

    m_items.reserve(records.size());
    for (const AnimeRecord &record : records) {
        AnimeItem item;
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

QVariantMap AnimeListModel::get(int index) const
{
    QVariantMap map;
    if (index < 0 || index >= m_items.size()) {
        return map;
    }

    const AnimeItem &item = m_items.at(index);
    map.insert(QStringLiteral("animeId"), item.id);
    map.insert(QStringLiteral("title"), item.title);
    map.insert(QStringLiteral("score"), item.score);
    map.insert(QStringLiteral("status"), item.status);
    map.insert(QStringLiteral("description"), item.description);
    map.insert(QStringLiteral("coverPath"), item.coverPath);
    map.insert(QStringLiteral("tags"), item.tags);
    return map;
}
