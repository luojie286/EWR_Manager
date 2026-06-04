#pragma once

#include <QAudioOutput>
#include <QMediaPlayer>
#include <QObject>
#include <QStringList>

class MusicController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(bool autoplay READ autoplay WRITE setAutoplay NOTIFY autoplayChanged)
    Q_PROPERTY(bool muted READ muted WRITE setMuted NOTIFY mutedChanged)
    Q_PROPERTY(QString currentTrackName READ currentTrackName NOTIFY currentTrackChanged)
    Q_PROPERTY(QString currentCoverPath READ currentCoverPath NOTIFY currentCoverChanged)
    Q_PROPERTY(int trackCount READ trackCount NOTIFY tracksChanged)
    Q_PROPERTY(QString musicDir READ musicDir CONSTANT)

public:
    explicit MusicController(const QString &musicDir, QObject *parent = nullptr);

    bool playing() const;
    bool enabled() const { return m_enabled; }
    bool autoplay() const { return m_autoplay; }
    bool muted() const { return m_muted; }
    QString currentTrackName() const { return m_currentTrackName; }
    QString currentCoverPath() const { return m_currentCoverPath; }
    int trackCount() const { return m_tracks.size(); }
    QString musicDir() const { return m_musicDir; }

    Q_INVOKABLE void togglePlay();
    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void skipNext();
    Q_INVOKABLE void setEnabled(bool enabled);
    Q_INVOKABLE void setAutoplay(bool autoplay);
    Q_INVOKABLE void toggleMute();
    Q_INVOKABLE void setMuted(bool muted);
    Q_INVOKABLE void scanMusicDirectory();
    Q_INVOKABLE void addTrackPaths(const QStringList &paths);
    Q_INVOKABLE void addTrackUrls(const QStringList &urls);
    Q_INVOKABLE void removeTrackAt(int index);
    Q_INVOKABLE void clearTracks();
    Q_INVOKABLE void openMusicFolder();
    Q_INVOKABLE QStringList trackPaths() const { return m_tracks; }
    Q_INVOKABLE QString trackNameAt(int index) const;

signals:
    void playingChanged();
    void enabledChanged();
    void autoplayChanged();
    void mutedChanged();
    void currentTrackChanged();
    void currentCoverChanged();
    void tracksChanged();

private:
    static bool isAudioFile(const QString &path);
    static QStringList filterExistingTracks(const QStringList &paths);

    void loadSettings();
    void saveSettings();
    void setPlaying(bool playing);
    void playTrackAt(int index);
    void playRandomNext();
    void mergeTracks(const QStringList &paths);
    void updateCoverFromMetadata();
    QString coverCachePath(const QString &trackPath) const;
    void setCurrentCoverPath(const QString &path);

    QMediaPlayer m_player;
    QAudioOutput m_audio;
    QString m_musicDir;
    QString m_coverCacheDir;
    QStringList m_tracks;
    QString m_currentTrackName;
    QString m_currentCoverPath;
    int m_currentIndex = -1;
    bool m_muted = false;
    bool m_enabled = true;
    bool m_autoplay = true;
    bool m_playing = false;
};
