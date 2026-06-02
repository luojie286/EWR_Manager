#pragma once

#include <QAbstractListModel>

class GameReviewListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int gameId READ gameId WRITE setGameId NOTIFY gameIdChanged)

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        GameIdRole,
        DateRole,
        TitleRole,
        ContentRole
    };

    explicit GameReviewListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int gameId() const { return m_gameId; }
    void setGameId(int gameId);

    Q_INVOKABLE void refresh();
    Q_INVOKABLE QVariantMap get(int index) const;

signals:
    void gameIdChanged();

private:
    struct ReviewItem {
        int id = 0;
        int gameId = 0;
        QString date;
        QString title;
        QString content;
    };

    QVector<ReviewItem> m_items;
    int m_gameId = 0;
};
