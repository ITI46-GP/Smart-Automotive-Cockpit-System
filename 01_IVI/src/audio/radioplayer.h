#ifndef RADIOPLAYER_H
#define RADIOPLAYER_H

#include "audiosourcebase.h"
#include <QStringList>

class RadioPlayer : public AudioSourceBase
{
    Q_OBJECT

public:
    explicit RadioPlayer(QObject *parent = nullptr);
    ~RadioPlayer();

    void activate() override;
    void deactivate() override;
    void play() override;
    void pause() override;
    void stop() override;
    void next() override;
    void prev() override;
    void togglePlayPause() override;
    void seek(qint64 pos) override; //slider
    void setVolume(float level) override;
    void setMuted(bool muted) override;
    void setAudioOutput(QAudioOutput *output) override;

private:

    QStringList m_urls;
    int m_index;
};


#endif // RADIOPLAYER_H
