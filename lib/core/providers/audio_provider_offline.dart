import 'package:appcherrylt/core/state/global_audio_state.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:logger/logger.dart';

class AudioProviderOffline extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer(
    handleInterruptions: true,
    androidApplyAudioAttributes: true,
    androidOffloadSchedulingEnabled: true,
  );

  // Audio state
  bool _isPlaying = false;
  bool _isPaused = false;
  String _currentPlayingSongName = '';
  int? _currentPlaylistId;
  String? _currentPlaylistTitle;
  String? _currentPlaylistCover;
  List<Map<String, dynamic>> _tracks = [];
  int _currentTrackIndex = 0;
  BuildContext? _context;
  final Logger logger = Logger();

  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  String get currentPlayingSongName => _currentPlayingSongName;
  int? get currentPlaylistId => _currentPlaylistId;
  String? get currentPlaylistTitle => _currentPlaylistTitle;
  String? get currentPlaylistCover => _currentPlaylistCover;

  var _playlist = ConcatenatingAudioSource(
    useLazyPreparation: true,
    children: [],
  );

  AudioProviderOffline(BuildContext context) {
    _context = context;
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed &&
          _isPlaying &&
          !_isPaused) {
        logger.d("Track completed, auto-loading next track.");
        next();
      }
    });

    _player.currentIndexStream.listen((index) {
      if (index != null && index != _currentTrackIndex) {
        _currentTrackIndex = index;
        _updateCurrentTrackInfo();
      }
    });

    // Add sequence state stream listener to update track info
    _player.sequenceStateStream.listen((sequenceState) {
      if (sequenceState != null && sequenceState.currentSource != null) {
        final mediaItem = sequenceState.currentSource!.tag as MediaItem;
        _currentPlayingSongName = '${mediaItem.album} - ${mediaItem.title}';
        logger.d(
            'Updated track info from sequence state: $_currentPlayingSongName');
        notifyListeners();
      }
    });
  }

  void _updateCurrentTrackInfo() {
    if (_currentTrackIndex >= 0 && _currentTrackIndex < _tracks.length) {
      final currentTrack = _tracks[_currentTrackIndex];
      _currentPlayingSongName =
          '${currentTrack['artist']} - ${currentTrack['title']}';
      logger.d(
          'Updated current track: $_currentPlayingSongName (Index: $_currentTrackIndex)');

      // Update global audio state
      if (_context != null) {
        try {
          final globalAudioState =
              Provider.of<GlobalAudioState>(_context!, listen: false);
          globalAudioState.updateAudioState(
            true,
            _currentPlayingSongName,
            _currentPlaylistId ?? 0,
            _currentPlaylistTitle ?? "Unknown Playlist",
            _currentPlaylistCover ?? "",
          );
        } catch (e) {
          logger.e('Error updating global audio state: $e');
        }
      }

      notifyListeners();
    }
  }

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _player.positionStream,
        _player.bufferedPositionStream,
        _player.durationStream,
        (position, bufferedPosition, duration) => PositionData(
          position,
          bufferedPosition,
          duration ?? Duration.zero,
        ),
      );

  Future<void> setOfflinePlaylist(List<Map<String, dynamic>> tracks) async {
    try {
      // Stop current playback and clear state
      await _player.stop();
      _isPlaying = false;
      _isPaused = false;
      _currentTrackIndex = 0;
      _tracks.clear();
      _playlist = ConcatenatingAudioSource(children: []);

      // Verify playlist ID from tracks
      if (tracks.isEmpty) {
        logger.e('No tracks provided to setOfflinePlaylist');
        return;
      }

      final playlistId = tracks[0]['playlistId'];
      if (playlistId == null) {
        logger.e('Track data missing playlistId');
        return;
      }

      // Set new tracks and playlist ID
      _tracks = List<Map<String, dynamic>>.from(tracks);
      _currentPlaylistId = playlistId;
      logger.d(
          'Setting up playlist ID: $playlistId with ${tracks.length} tracks');

      // Create audio sources
      final audioSources = _tracks
          .map((track) {
            final filePath = track['filePath'];
            if (!filePath.contains('/$playlistId/')) {
              logger.e(
                  'Track filepath does not match playlist ID: $filePath vs $playlistId');
              return null;
            }

            logger.d(
                'Creating audio source for track: ${track['title']} from playlist $playlistId at $filePath');

            return AudioSource.uri(
              Uri.file(filePath),
              tag: MediaItem(
                id: '${playlistId}_${track['id']}',
                title: track['title'],
                album: track['artist'],
              ),
            );
          })
          .whereType<AudioSource>()
          .toList();

      if (audioSources.isEmpty) {
        logger.e('No valid audio sources found for playlist $playlistId');
        return;
      }

      // Set the audio source
      await _player.setAudioSource(
        ConcatenatingAudioSource(children: audioSources),
        initialIndex: 0,
        initialPosition: Duration.zero,
      );

      _updateCurrentTrackInfo();
      logger.d(
          'Successfully set up playlist $playlistId with ${audioSources.length} tracks');

      notifyListeners();
    } catch (e, stackTrace) {
      logger.e('Error setting offline playlist: $e');
      logger.e('Stack trace: $stackTrace');
      rethrow;
    }
  }

  void play() {
    if (!_isPlaying) {
      _player.play();
      _isPlaying = true;
      _isPaused = false;
      _updateCurrentTrackInfo();
      notifyListeners();
      logger.d(
          "Playing offline playlist $_currentPlaylistId at track $_currentTrackIndex");
    }
  }

  void pause() {
    _player.pause();
    _isPlaying = false;
    _isPaused = true;
    notifyListeners();
    logger.d(
        "Paused offline playlist $_currentPlaylistId at track $_currentTrackIndex");
  }

  void togglePlayPause(BuildContext context) {
    final globalAudioState =
        Provider.of<GlobalAudioState>(context, listen: false);

    if (_player.playing) {
      pause();
    } else {
      play();
      globalAudioState.updateAudioState(
        true,
        _currentPlayingSongName,
        _currentPlaylistId ?? 0,
        _currentPlaylistTitle ?? "Unknown Playlist",
        _currentPlaylistCover ?? "",
      );
    }
  }

  void next() {
    logger.d("Next button pressed");
    if (_currentTrackIndex + 1 < _tracks.length) {
      _currentTrackIndex++;
      _player.seekToNext();
      _player.play();
    } else {
      logger.d("No more tracks to play next.");
    }
  }

  void previous() {
    logger.d("Previous button pressed");
    if (_currentTrackIndex > 0) {
      _currentTrackIndex--;
      _player.seekToPrevious();
      _player.play();
    } else {
      logger.d("No previous tracks available.");
    }
  }

  void seek(Duration position) {
    _player.seek(position);
    notifyListeners();
  }

  Future<void> stop() async {
    logger.d('Stopping audio playback');
    try {
      if (_player.audioSource != null) {
        await _player.stop();
        _isPlaying = false;
        _isPaused = false;
        notifyListeners();
      }

      _currentTrackIndex = 0;
      _currentPlayingSongName = '';
      _currentPlaylistId = null;
      _currentPlaylistTitle = null;
      _currentPlaylistCover = null;
      _tracks = [];

      if (_context != null) {
        final globalAudioState =
            Provider.of<GlobalAudioState>(_context!, listen: false);
        globalAudioState.updateAudioState(
          false,
          "",
          0,
          "",
          "",
        );
      }

      logger.d('Audio playback stopped successfully');
    } catch (e) {
      logger.e('Error stopping audio playback: $e');
      rethrow;
    }
  }

  void setPlaylistDetails(int playlistId, String title, String cover) {
    if (_currentPlaylistId != playlistId) {
      logger.d(
          'Updating playlist details from $_currentPlaylistId to $playlistId');
      _currentPlaylistId = playlistId;
    }
    _currentPlaylistTitle = title;
    _currentPlaylistCover = cover;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}
