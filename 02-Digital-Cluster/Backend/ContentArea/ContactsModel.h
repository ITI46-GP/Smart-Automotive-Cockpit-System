#ifndef CONTACTSMODEL_H
#define CONTACTSMODEL_H

#include <QAbstractListModel>
#include <QList>
#include <QString>

/**
 * @brief Represents a single contact entry.
 */
struct Contact {
    QString name;   ///< The name of the contact.
    QString number; ///< The phone number of the contact.
};

/**
 * @brief ContactsModel provides a list of contacts to the QML UI.
 * 
 * This class inherits from QAbstractListModel, which is the most efficient and native
 * way to expose dynamic lists (like a phonebook) from C++ to a QML Repeater or ListView.
 * It abstracts away the data source. When the SOME/IP stack receives contact data
 * from the external IVI system, it will update this model, and the QML UI will
 * automatically reflect the changes without any UI-side logic.
 */
class ContactsModel : public QAbstractListModel
{
    Q_OBJECT

public:
    /**
     * @brief Roles exposed to QML to access specific data fields of a Contact.
     */
    enum ContactRoles {
        NameRole = Qt::UserRole + 1, ///< Maps to the contact's name
        NumberRole                   ///< Maps to the contact's phone number
    };

    explicit ContactsModel(QObject *parent = nullptr);

    // --- QAbstractListModel Required Overrides ---
    
    /** @brief Returns the number of contacts currently in the list. */
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    
    /** @brief Retrieves the data for a specific role at a specific index. Used by QML. */
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    
    /** @brief Maps the C++ enum roles (e.g. NameRole) to string names accessible in QML. */
    QHash<int, QByteArray> roleNames() const override;

    // --- Data Manipulation API ---
    // These methods act as the interface for the future CommonAPI/SOME/IP IPC layer.

    /**
     * @brief Adds a new contact to the end of the list.
     * @param name The contact's name.
     * @param number The contact's phone number.
     * 
     * Calling this automatically signals the QML UI to render the new row.
     */
    void addContact(const QString &name, const QString &number);

    /**
     * @brief Clears all contacts from the list.
     * 
     * Calling this automatically signals the QML UI to empty the view.
     */
    void clearContacts();

    /**
     * @brief Preloads the model with mock data for testing UI integration.
     */
    void loadMockData();

private:
    QList<Contact> m_contacts;
};

#endif // CONTACTSMODEL_H
