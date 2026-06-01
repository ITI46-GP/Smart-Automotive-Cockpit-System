#ifndef ASSISTANTMANAGER_H
#define ASSISTANTMANAGER_H

#include <QObject>
#include <QString>

class LightsController;
class NavigationManager;
class ProfileManager;

class AssistantManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool voiceEnabled READ voiceEnabled WRITE setVoiceEnabled NOTIFY voiceEnabledChanged)
    Q_PROPERTY(bool listening READ listening WRITE setListening NOTIFY listeningChanged)
    Q_PROPERTY(QString lastUserMessage READ lastUserMessage NOTIFY lastUserMessageChanged)
    Q_PROPERTY(QString lastAssistantReply READ lastAssistantReply NOTIFY lastAssistantReplyChanged)

public:
    explicit AssistantManager(QObject *parent = nullptr);
    AssistantManager(ProfileManager *profileManager,
                     NavigationManager *navigationManager,
                     LightsController *lightsController,
                     QObject *parent = nullptr);

    bool voiceEnabled() const;
    bool listening() const;
    QString lastUserMessage() const;
    QString lastAssistantReply() const;

    void setProfileManager(ProfileManager *profileManager);
    void setNavigationManager(NavigationManager *navigationManager);
    void setLightsController(LightsController *lightsController);

    Q_INVOKABLE void sendMessage(const QString &message);
    Q_INVOKABLE void toggleVoiceEnabled();
    Q_INVOKABLE void toggleListening();

public slots:
    void setVoiceEnabled(bool enabled);
    void setListening(bool listening);

signals:
    void voiceEnabledChanged();
    void listeningChanged();
    void lastUserMessageChanged();
    void lastAssistantReplyChanged();

private:
    QString statusReply() const;
    QString profileReply() const;
    QString lightsReply() const;
    void setLastAssistantReply(const QString &reply);

    bool m_voiceEnabled = true;
    bool m_listening = false;
    QString m_lastUserMessage = "Check vehicle status.";
    QString m_lastAssistantReply = "Battery healthy. Cabin ready. No critical warnings.";
    ProfileManager *m_profileManager = nullptr;
    NavigationManager *m_navigationManager = nullptr;
    LightsController *m_lightsController = nullptr;
};

#endif // ASSISTANTMANAGER_H
