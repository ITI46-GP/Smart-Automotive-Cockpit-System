#include "AssistantManager.h"

#include "LightsController.h"
#include "NavigationManager.h"
#include "ProfileManager.h"

AssistantManager::AssistantManager(QObject *parent)
    : QObject(parent)
{
}

AssistantManager::AssistantManager(ProfileManager *profileManager,
                                   NavigationManager *navigationManager,
                                   LightsController *lightsController,
                                   QObject *parent)
    : QObject(parent)
    , m_profileManager(profileManager)
    , m_navigationManager(navigationManager)
    , m_lightsController(lightsController)
{
}

bool AssistantManager::voiceEnabled() const
{
    return m_voiceEnabled;
}

bool AssistantManager::listening() const
{
    return m_listening;
}

QString AssistantManager::lastUserMessage() const
{
    return m_lastUserMessage;
}

QString AssistantManager::lastAssistantReply() const
{
    return m_lastAssistantReply;
}

void AssistantManager::setProfileManager(ProfileManager *profileManager)
{
    m_profileManager = profileManager;
}

void AssistantManager::setNavigationManager(NavigationManager *navigationManager)
{
    m_navigationManager = navigationManager;
}

void AssistantManager::setLightsController(LightsController *lightsController)
{
    m_lightsController = lightsController;
}

void AssistantManager::sendMessage(const QString &message)
{
    const QString trimmedMessage = message.trimmed();
    if (trimmedMessage.isEmpty()) {
        return;
    }

    if (m_lastUserMessage != trimmedMessage) {
        m_lastUserMessage = trimmedMessage;
        emit lastUserMessageChanged();
    }

    const QString lowerMessage = trimmedMessage.toLower();
    if (lowerMessage.contains("navigate home")) {
        if (m_navigationManager) {
            m_navigationManager->setRouteDestination("Home");
            setLastAssistantReply("Route set to Home. ETA 8 minutes, distance 4.2 km.");
        } else {
            setLastAssistantReply("Navigation is not connected yet.");
        }
    } else if (lowerMessage.contains("status")) {
        setLastAssistantReply(statusReply());
    } else if (lowerMessage.contains("profile")) {
        setLastAssistantReply(profileReply());
    } else if (lowerMessage.contains("lights")) {
        setLastAssistantReply(lightsReply());
    } else {
        setLastAssistantReply("I can help with status, profiles, lights, and navigation commands.");
    }
}

void AssistantManager::toggleVoiceEnabled()
{
    setVoiceEnabled(!m_voiceEnabled);
}

void AssistantManager::toggleListening()
{
    if (!m_voiceEnabled) {
        setListening(false);
        return;
    }

    setListening(!m_listening);
}

void AssistantManager::setVoiceEnabled(bool enabled)
{
    if (m_voiceEnabled == enabled) {
        return;
    }

    m_voiceEnabled = enabled;
    emit voiceEnabledChanged();

    if (!m_voiceEnabled) {
        setListening(false);
    }
}

void AssistantManager::setListening(bool listening)
{
    const bool newListening = m_voiceEnabled && listening;
    if (m_listening == newListening) {
        return;
    }

    m_listening = newListening;
    emit listeningChanged();
}

QString AssistantManager::statusReply() const
{
    QStringList parts;
    parts << "Vehicle ready";

    if (m_profileManager) {
        parts << QString("profile %1").arg(m_profileManager->activeProfileName());
    }

    if (m_lightsController) {
        parts << QString("headlights %1").arg(m_lightsController->headlightsOn() ? "on" : "off");
    }

    if (m_navigationManager && m_navigationManager->routeActive()) {
        parts << QString("route to %1, %2 min").arg(m_navigationManager->destination()).arg(m_navigationManager->etaMinutes());
    } else {
        parts << "no active route";
    }

    return parts.join(". ") + ".";
}

QString AssistantManager::profileReply() const
{
    if (!m_profileManager) {
        return "Profile manager is not connected yet.";
    }

    return QString("Active profile is %1.").arg(m_profileManager->activeProfileName());
}

QString AssistantManager::lightsReply() const
{
    if (!m_lightsController) {
        return "Lights controller is not connected yet.";
    }

    return QString("Headlights %1, fog lights %2, ambient %3 at %4%.")
        .arg(m_lightsController->headlightsOn() ? "on" : "off")
        .arg(m_lightsController->fogLightsOn() ? "on" : "off")
        .arg(m_lightsController->cabinAmbientOn() ? "on" : "off")
        .arg(m_lightsController->ambientLevel());
}

void AssistantManager::setLastAssistantReply(const QString &reply)
{
    if (m_lastAssistantReply == reply) {
        return;
    }

    m_lastAssistantReply = reply;
    emit lastAssistantReplyChanged();
}
