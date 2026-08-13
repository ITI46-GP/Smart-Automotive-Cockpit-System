#include "ContactsModel.h"

ContactsModel::ContactsModel(QObject *parent)
    : QAbstractListModel(parent)
{
    loadMockData();
}

int ContactsModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_contacts.count();
}

QVariant ContactsModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_contacts.count())
        return QVariant();

    const Contact &contact = m_contacts[index.row()];

    if (role == NameRole)
        return contact.name;
    else if (role == NumberRole)
        return contact.number;

    return QVariant();
}

QHash<int, QByteArray> ContactsModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[NameRole] = "contactNameRole";
    roles[NumberRole] = "contactNumberRole";
    return roles;
}

void ContactsModel::addContact(const QString &name, const QString &number)
{
    beginInsertRows(QModelIndex(), m_contacts.count(), m_contacts.count());
    m_contacts.append({name, number});
    endInsertRows();
}

void ContactsModel::clearContacts()
{
    beginResetModel();
    m_contacts.clear();
    endResetModel();
}

void ContactsModel::loadMockData()
{
    clearContacts();
    addContact("John Doe", "+1 555 0101");
    addContact("Jane Smith", "+1 555 0202");
    addContact("Mike Johnson", "+1 555 0303");
    addContact("Sarah Connor", "+1 555 0404");
    addContact("Tony Stark", "+1 555 0505");
    addContact("Bruce Wayne", "+1 555 0606");
    addContact("Peter Parker", "+1 555 0707");
    addContact("Clark Kent", "+1 555 0808");
}
