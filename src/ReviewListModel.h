#pragma once

#include <QAbstractListModel>

class ReviewListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int animeId READ animeId WRITE setAnimeId NOTIFY animeIdChanged)

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        AnimeIdRole,
        DateRole,
        TitleRole,
        ContentRole
    };

    explicit ReviewListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int animeId() const { return m_animeId; }
    void setAnimeId(int animeId);

    Q_INVOKABLE void refresh();
    Q_INVOKABLE QVariantMap get(int index) const;

signals:
    void animeIdChanged();

private:
    struct ReviewItem {
        int id = 0;
        int animeId = 0;
        QString date;
        QString title;
        QString content;
    };

    QVector<ReviewItem> m_items;
    int m_animeId = 0;
};
