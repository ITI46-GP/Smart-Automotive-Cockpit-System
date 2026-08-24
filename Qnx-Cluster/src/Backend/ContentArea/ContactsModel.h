// Ported verbatim from 02-Digital-Cluster/Backend/ContentArea/ContactsModel.h.
#pragma once

#include <QAbstractListModel>
#include <QList>
#include <QString>

struct Contact {
    QString name;
    QString number;
};

class ContactsModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum ContactRoles {
        NameRole = Qt::UserRole + 1,
        NumberRole
    };

    explicit ContactsModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void addContact(const QString &name, const QString &number);
    void clearContacts();
    void loadMockData();

private:
    QList<Contact> m_contacts;
};
