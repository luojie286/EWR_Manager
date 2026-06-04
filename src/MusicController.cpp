#include "MusicController.h"

#include <QDesktopServices>
#include <QDir>
#include <QFileInfo>
#include <QImage>
#include <QMediaMetaData>
#include <QRandomGenerator>
#include <QSettings>
#include <QUrl>

namespace {

const QStringList kAudioSuffixes = {
    QStringLiteral("mp3"), QStringLiteral("flac"), QStringLiteral("ogg"),
    QStringLiteral("wav"), QStringLiteral("m4a"), QStringLiteral("aac"),
    QStringLiteral("wma"), QStringLiteral("opus"),
};

} // namespace

MusicController::MusicController(const QString &musicDir, QObject *parent)
    : QObject(parent)
    , m_musicDir(musicDir)
    , m_coverCacheDir(musicDir + QStringLiteral("/.covers"))
{
    QDir().mkpath(m_musicDir);
    QDir().mkpath(m_coverCacheDir);

    m_audio.setVolume(1.0);
    m_audio.setMuted(m_muted);
    m_player.setAudioOutput(&m_audio);

    connect(&m_player, &QMediaPlayer::playbackStateChanged, this,
            [this](QMediaPlayer::PlaybackState state) {
                setPlaying(state == QMediaPlayer::PlayingState);
            });
    connect(&m_player, &QMediaPlayer::metaDataChanged, this,
            &MusicController::updateCoverFromMetadata);
    connect(&m_player, &QMediaPlayer::mediaStatusChanged, this,
            [this](QMediaPlayer::MediaStatus status) {
                if (status == QMediaPlayer::LoadedMedia
                    || status == QMediaPlayer::BufferedMedia) {
                    updateCoverFromMetadata();
                }
                if (status == QMediaPlayer::EndOfMedia && m_enabled)
                    playRandomNext();
            });

    loadSettings();
    scanMusicDirectory();

    if (m_enabled && m_autoplay && !m_tracks.isEmpty())
        playRandomNext();
}

bool MusicController::playing() const
{
    return m_playing;
}

void MusicController::setPlaying(bool playing)
{
    if (m_playing == playing)
        return;
    m_playing = playing;
    emit playingChanged();
}

bool MusicController::isAudioFile(const QString &path)
{
    return kAudioSuffixes.contains(QFileInfo(path).suffix().toLower());
}

QStringList MusicController::filterExistingTracks(const QStringList &paths)
{
    QStringList result;
    result.reserve(paths.size());
    for (const QString &path : paths) {
        const QString normalized = QDir::fromNativeSeparators(path.trimmed());
        if (!normalized.isEmpty() && QFileInfo::exists(normalized) && isAudioFile(normalized))
            result.append(normalized);
    }
    return result;
}

void MusicController::loadSettings()
{
    QSettings settings;
    m_enabled = settings.value(QStringLiteral("music/enabled"), true).toBool();
    m_autoplay = settings.value(QStringLiteral("music/autoplay"), true).toBool();
    m_muted = settings.value(QStringLiteral("music/muted"), false).toBool();
    m_tracks = filterExistingTracks(
        settings.value(QStringLiteral("music/tracks")).toStringList());
    m_audio.setVolume(1.0);
    m_audio.setMuted(m_muted);
}

void MusicController::saveSettings()
{
    QSettings settings;
    settings.setValue(QStringLiteral("music/enabled"), m_enabled);
    settings.setValue(QStringLiteral("music/autoplay"), m_autoplay);
    settings.setValue(QStringLiteral("music/muted"), m_muted);
    settings.setValue(QStringLiteral("music/tracks"), m_tracks);
}

void MusicController::mergeTracks(const QStringList &paths)
{
    const QStringList incoming = filterExistingTracks(paths);
    if (incoming.isEmpty())
        return;

    bool changed = false;
    for (const QString &path : incoming) {
        if (!m_tracks.contains(path)) {
            m_tracks.append(path);
            changed = true;
        }
    }

    if (!changed)
        return;

    saveSettings();
    emit tracksChanged();
}

void MusicController::scanMusicDirectory()
{
    QDir dir(m_musicDir);
    if (!dir.exists())
        return;

    QStringList found;
    const QFileInfoList entries = dir.entryInfoList(
        QDir::Files | QDir::Readable | QDir::NoDotAndDotDot, QDir::Name);
    for (const QFileInfo &info : entries) {
        if (isAudioFile(info.absoluteFilePath()))
            found.append(info.absoluteFilePath());
    }

    mergeTracks(found);
}

void MusicController::addTrackPaths(const QStringList &paths)
{
    mergeTracks(paths);
    if (m_enabled && m_playing)
        return;
    if (m_enabled && m_autoplay && !m_tracks.isEmpty() && m_currentIndex < 0)
        playRandomNext();
}

void MusicController::addTrackUrls(const QStringList &urls)
{
    QStringList paths;
    paths.reserve(urls.size());
    for (const QString &url : urls) {
        const QString local = QUrl(url).toLocalFile();
        if (!local.isEmpty())
            paths.append(local);
    }
    addTrackPaths(paths);
}

void MusicController::removeTrackAt(int index)
{
    if (index < 0 || index >= m_tracks.size())
        return;

    const bool removingCurrent = index == m_currentIndex;
    m_tracks.removeAt(index);
    saveSettings();
    emit tracksChanged();

    if (m_tracks.isEmpty()) {
        m_player.stop();
        m_currentIndex = -1;
        m_currentTrackName.clear();
        setCurrentCoverPath({});
        emit currentTrackChanged();
        return;
    }

    if (removingCurrent && m_enabled)
        playRandomNext();
    else if (m_currentIndex > index)
        --m_currentIndex;
}

void MusicController::clearTracks()
{
    if (m_tracks.isEmpty())
        return;

    m_player.stop();
    m_tracks.clear();
    m_currentIndex = -1;
    m_currentTrackName.clear();
    setCurrentCoverPath({});
    saveSettings();
    emit tracksChanged();
    emit currentTrackChanged();
}

QString MusicController::trackNameAt(int index) const
{
    if (index < 0 || index >= m_tracks.size())
        return {};
    return QFileInfo(m_tracks.at(index)).completeBaseName();
}

QString MusicController::coverCachePath(const QString &trackPath) const
{
    const QString key = QString::number(qHash(trackPath));
    return m_coverCacheDir + QStringLiteral("/") + key + QStringLiteral(".jpg");
}

void MusicController::setCurrentCoverPath(const QString &path)
{
    if (m_currentCoverPath == path)
        return;
    m_currentCoverPath = path;
    emit currentCoverChanged();
}

void MusicController::updateCoverFromMetadata()
{
    if (m_currentIndex < 0 || m_currentIndex >= m_tracks.size())
        return;

    QImage image;
    const QMediaMetaData &meta = m_player.metaData();

    const QVariant thumbnail = meta.value(QMediaMetaData::ThumbnailImage);
    if (thumbnail.canConvert<QImage>())
        image = thumbnail.value<QImage>();

    if (image.isNull()) {
        const QVariant coverArt = meta.value(QMediaMetaData::CoverArtImage);
        if (coverArt.canConvert<QImage>())
            image = coverArt.value<QImage>();
    }

    if (image.isNull()) {
        setCurrentCoverPath({});
        return;
    }

    const QString cachePath = coverCachePath(m_tracks.at(m_currentIndex));
    if (!image.save(cachePath, "JPG", 88)) {
        setCurrentCoverPath({});
        return;
    }

    setCurrentCoverPath(cachePath);
}

void MusicController::playTrackAt(int index)
{
    if (index < 0 || index >= m_tracks.size())
        return;

    m_currentIndex = index;
    m_currentTrackName = trackNameAt(index);
    emit currentTrackChanged();

    const QString trackPath = m_tracks.at(index);
    const QString cachedCover = coverCachePath(trackPath);
    if (QFileInfo::exists(cachedCover))
        setCurrentCoverPath(cachedCover);
    else
        setCurrentCoverPath({});

    m_player.setSource(QUrl::fromLocalFile(trackPath));
    if (m_enabled)
        m_player.play();
}

void MusicController::playRandomNext()
{
    if (!m_enabled || m_tracks.isEmpty())
        return;

    int nextIndex = 0;
    if (m_tracks.size() == 1) {
        nextIndex = 0;
    } else {
        do {
            nextIndex = QRandomGenerator::global()->bounded(m_tracks.size());
        } while (nextIndex == m_currentIndex);
    }

    playTrackAt(nextIndex);
}

void MusicController::togglePlay()
{
    if (m_tracks.isEmpty())
        return;

    if (m_player.playbackState() == QMediaPlayer::PlayingState) {
        pause();
        return;
    }

    if (m_currentIndex >= 0 && m_player.playbackState() == QMediaPlayer::PausedState) {
        setEnabled(true);
        m_player.play();
        return;
    }

    setEnabled(true);
    playRandomNext();
}

void MusicController::play()
{
    if (m_tracks.isEmpty())
        return;

    setEnabled(true);
    if (m_currentIndex < 0)
        playRandomNext();
    else
        m_player.play();
}

void MusicController::pause()
{
    m_player.pause();
}

void MusicController::skipNext()
{
    if (m_tracks.isEmpty())
        return;

    setEnabled(true);
    playRandomNext();
}

void MusicController::setEnabled(bool enabled)
{
    if (m_enabled == enabled)
        return;

    m_enabled = enabled;
    saveSettings();
    emit enabledChanged();

    if (!m_enabled)
        m_player.pause();
    else if (m_autoplay && m_currentIndex >= 0)
        m_player.play();
    else if (m_autoplay && !m_tracks.isEmpty())
        playRandomNext();
}

void MusicController::setAutoplay(bool autoplay)
{
    if (m_autoplay == autoplay)
        return;

    m_autoplay = autoplay;
    saveSettings();
    emit autoplayChanged();
}

void MusicController::toggleMute()
{
    setMuted(!m_muted);
}

void MusicController::setMuted(bool muted)
{
    if (m_muted == muted)
        return;

    m_muted = muted;
    m_audio.setMuted(m_muted);
    saveSettings();
    emit mutedChanged();
}

void MusicController::openMusicFolder()
{
    QDesktopServices::openUrl(QUrl::fromLocalFile(m_musicDir));
}
