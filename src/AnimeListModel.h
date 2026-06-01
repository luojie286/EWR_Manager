#pragma once

#include <QAbstractListModel>
#include <QString>

class AnimeListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QString searchText READ searchText WRITE setSearchText NOTIFY searchTextChanged)
    Q_PROPERTY(QString statusFilter READ statusFilter WRITE setStatusFilter NOTIFY statusFilterChanged)
    Q_PROPERTY(QString tagFilter READ tagFilter WRITE setTagFilter NOTIFY tagFilterChanged)

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        TitleRole,
        ScoreRole,
        StatusRole,
        DescriptionRole,
        CoverPathRole,
        TagsRole
    };

    explicit AnimeListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString searchText() const { return m_searchText; }
    QString statusFilter() const { return m_statusFilter; }
    QString tagFilter() const { return m_tagFilter; }

    void setSearchText(const QString &text);
    void setStatusFilter(const QString &filter);
    void setTagFilter(const QString &filter);

    Q_INVOKABLE void refresh();
    Q_INVOKABLE QVariantMap get(int index) const;

signals:
    void searchTextChanged();
    void statusFilterChanged();
    void tagFilterChanged();

private:
    struct AnimeItem {
        int id = 0;
        QString title;
        double score = 0.0;
        QString status;
        QString description;
        QString coverPath;
        QStringList tags;
    };

    QVector<AnimeItem> m_items;
    QString m_searchText;
    QString m_statusFilter;
    QString m_tagFilter;
};
