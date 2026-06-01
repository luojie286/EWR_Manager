#include "ReviewListModel.h"

#include "DatabaseManager.h"

ReviewListModel::ReviewListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int ReviewListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }
    return m_items.size();
}

QVariant ReviewListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size()) {
        return {};
    }

    const ReviewItem &item = m_items.at(index.row());
    switch (role) {
    case IdRole:
        return item.id;
    case AnimeIdRole:
        return item.animeId;
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

QHash<int, QByteArray> ReviewListModel::roleNames() const
{
    return {
        {IdRole, "reviewId"},
        {AnimeIdRole, "animeId"},
        {DateRole, "date"},
        {TitleRole, "title"},
        {ContentRole, "content"}
    };
}

void ReviewListModel::setAnimeId(int animeId)
{
    if (m_animeId == animeId) {
        return;
    }
    m_animeId = animeId;
    emit animeIdChanged();
    refresh();
}

void ReviewListModel::refresh()
{
    beginResetModel();
    m_items.clear();

    if (m_animeId > 0) {
        const QVector<ReviewRecord> records =
            DatabaseManager::instance().fetchReviews(m_animeId);

        m_items.reserve(records.size());
        for (const ReviewRecord &record : records) {
            ReviewItem item;
            item.id = record.id;
            item.animeId = record.animeId;
            item.date = record.date;
            item.title = record.title;
            item.content = record.content;
            m_items.append(item);
        }
    }

    endResetModel();
}

QVariantMap ReviewListModel::get(int index) const
{
    QVariantMap map;
    if (index < 0 || index >= m_items.size()) {
        return map;
    }

    const ReviewItem &item = m_items.at(index);
    map.insert(QStringLiteral("reviewId"), item.id);
    map.insert(QStringLiteral("animeId"), item.animeId);
    map.insert(QStringLiteral("date"), item.date);
    map.insert(QStringLiteral("title"), item.title);
    map.insert(QStringLiteral("content"), item.content);
    return map;
}
