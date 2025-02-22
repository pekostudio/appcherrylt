import 'dart:typed_data';
import 'package:appcherrylt/api/api.dart';
import 'package:appcherrylt/core/state/global_audio_state.dart';
import 'package:appcherrylt/core/models/user_session.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:logger/logger.dart';

class MyJABytesSource extends StreamAudioSource {
  final Uint8List _buffer;
  final MediaItem mediaItem;

  MyJABytesSource(this._buffer, this.mediaItem) : super(tag: mediaItem);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    return StreamAudioResponse(
      sourceLength: _buffer.length,
      contentLength: (end ?? _buffer.length) - (start ?? 0),
      offset: start ?? 0,
      stream: Stream.fromIterable([_buffer.sublist(start ?? 0, end)]),
      contentType: 'audio/mpeg',
    );
  }
}

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer(
    handleInterruptions: true,
    androidApplyAudioAttributes: true,
    androidOffloadSchedulingEnabled: true,
  );
  // Audio state
  bool _isPlaying = false;
  bool _isPaused = false;
  String? _currentSongName;
  int? _currentPlaylistId;
  String? _currentPlaylistTitle;
  String? _currentPlaylistCover;

  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  String? get currentSongName => _currentSongName;
  int? get currentPlaylistId => _currentPlaylistId;
  String? get currentPlaylistTitle => _currentPlaylistTitle;
  String? get currentPlaylistCover => _currentPlaylistCover;

  bool _isLoading = false;
  String baseUrl = 'https://app.cherrymusic.lt';
  String _currentPlayingSongName = '';

  String? _playlistTitle;
  String? _playlistCover;
  int? _playlistId;
  int _currentTrackIndex = 0;
  List<dynamic> _tracks = [];
  BuildContext? _context;
  final Logger logger = Logger();
  bool _isInitialLoad = true;
  bool get isInitialLoad => _isInitialLoad;

  bool _isScheduledPlaylist = false;
  bool get isScheduledPlaylist => _isScheduledPlaylist;
  set isScheduledPlaylist(bool value) {
    _isScheduledPlaylist = value;
    notifyListeners();
  }

  var _playlist = ConcatenatingAudioSource(
    useLazyPreparation: true,
    children: [],
  );

  bool _isScheduled = false;

  bool get isScheduled => _isScheduled;

  bool _isInitialized = true;
  bool get isInitialized => _isInitialized;

  AudioProvider(BuildContext context) {
    _context = context; // Save the context
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed &&
          !_isInitialLoad &&
          _isPlaying &&
          !_isPaused) {
        logger.d("Track completed, auto-loading next track.");
        _loadNextTrack();
      } else {
        logger.d(
            "Track completed but not auto-loading next track due to conditions. isInitialLoad: $_isInitialLoad, isPlaying: $_isPlaying, isPaused: $_isPaused");
      }
    });

    _player.sequenceStateStream.listen((sequenceState) {
      if (sequenceState != null && sequenceState.currentSource != null) {
        final currentItem = sequenceState.currentSource!.tag as MediaItem;
        setCurrentPlayingSongName(
            '${currentItem.album} - ${currentItem.title}');
        _currentTrackIndex = _player.currentIndex ?? 0;

        // Dynamically update _currentPlayingSongName
        _currentPlayingSongName = '${currentItem.album} - ${currentItem.title}';
        notifyListeners();
      }
    });
  }

  bool get isLoading => _isLoading; // Getter for loading state
  String get currentPlayingSongName => _currentPlayingSongName;
  String? get playlistTitle => _playlistTitle;
  String? get playlistCover => _playlistCover;
  int? get playlistId => _playlistId;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;

  // ADS
  Future<void> playAd(AudioSource audioSource) async {
    // Save the current audio source
    final currentAudioSource = _player.audioSource;

    // Set the ad audio source and play the ad
    await _player.setAudioSource(audioSource);

    await _player.play();

    // Wait for the ad to finish playing
    await _player.processingStateStream
        .firstWhere((state) => state == ProcessingState.completed);

    // Reset the audio source to the original playlist
    _isPlaying = true;
    await _player.setAudioSource(currentAudioSource!);
  }

  bool isPlaylistSet(int playlistId) {
    return _playlistId == playlistId && _tracks.isNotEmpty;
  }

  // SET Playlist
  Future<void> setPlaylist(
      List<dynamic> tracks, BuildContext context, String coverUrl,
      {bool isScheduled = false}) async {
    _isLoading = true;
    _isInitialLoad = true; // Add this flag to prevent auto-play during the load
    _isScheduledPlaylist = isScheduled;
    notifyListeners();

    _tracks = tracks;
    _currentTrackIndex = 0;

    // Load audio sources in the background
    List<AudioSource> audioSources =
        await _loadInitialTracks(context, coverUrl);

    // Clear previous playlist if any
    if (_playlist.length > 0) {
      await _playlist.clear();
    }

    // Add loaded tracks to the playlist
    if (audioSources.isNotEmpty) {
      await _playlist.addAll(audioSources);
      // Set the playlist but do not start playback yet
      await _player.setAudioSource(_playlist,
          initialIndex: 0, initialPosition: Duration.zero);
    }

    _isLoading = false;
    _isInitialLoad = false; // Reset the flag after the load
    notifyListeners();
  }

  Future<List<AudioSource>> _loadInitialTracks(
      BuildContext context, String coverUrl) async {
    List<AudioSource> audioSources = [];

    // Load only the first track
    int tracksToLoad = 1;
    for (int i = 0; i < tracksToLoad && i < _tracks.length; i++) {
      try {
        AudioSource audioSource =
            await _createAudioSource(_tracks[i], coverUrl);
        audioSources.add(audioSource);
      } catch (e) {
        logger.d("Error loading track: $e");
      }
    }

    return audioSources;
  }

  Future<AudioSource> _createAudioSource(
      dynamic songData, String coverUrl) async {
    String streamUrl = songData['stream'];
    String urlWithToken =
        "$baseUrl$streamUrl?access_token=${Provider.of<UserSession>(_context!, listen: false).globalToken}";
    Uint8List audioData = await fetchAudioData(urlWithToken);

    MediaItem mediaItem = MediaItem(
      id: songData['id'].toString(),
      album: songData['artist'] ?? 'Album',
      title: songData['title'] ?? 'Title',
      artUri: Uri.parse(coverUrl), // Use the dynamic cover URL here
    );

    return MyJABytesSource(audioData, mediaItem);
  }

  void setCurrentPlayingSongName(String songName) {
    _currentPlayingSongName = songName;
    notifyListeners();
  }

  Future<Uint8List> fetchAudioData(String urlWithToken) async {
    try {
      final response = await http.get(Uri.parse(urlWithToken), headers: {
        'Authorization':
            'Basic YXBwOnd5cWQ3eWdqbmpvOXVyaGdmem5yYmc4amI3OGI3bWZ1',
      });

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to fetch audio data: ${response.statusCode}');
      }
    } catch (e) {
      logger.d("Error fetching audio data: $e");
      rethrow; // Rethrow the exception to be handled by the caller
    }
  }

  Future<void> _loadNextTrack() async {
    // Prevent loading if it's the initial load or player is not playing
    if (_isInitialLoad || !_player.playing) {
      logger.d("Initial load or player not playing. Skipping next track.");
      return;
    }

    // Check if there is a next track to load
    if (_currentTrackIndex + 1 < _tracks.length) {
      try {
        if (_currentTrackIndex + 1 >= _playlist.length) {
          logger.d("Adding next track to the playlist.");
          var nextSongData = _tracks[_currentTrackIndex + 1];
          AudioSource nextAudioSource =
              await _createAudioSource(nextSongData, _playlistCover ?? '');
          await _playlist.add(nextAudioSource);
        }
        _currentTrackIndex++;
        logger.d("Seeking to next track: $_currentTrackIndex");
        await _player.seek(Duration.zero, index: _currentTrackIndex);
        _player.play();
        logger.d("Playing next track: $_currentTrackIndex");
      } catch (e) {
        logger.d("Error loading next track: $e");
      }
    } else {
      logger.d("No more tracks to load.");
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

  get api => null;

  // Controls main

  // Method to start playing
  void playAudio({
    required BuildContext context,
    required String songName,
    required int playlistId,
    required String playlistTitle,
    required String playlistCover,
    bool isScheduledPlaylist = false,
  }) {
    try {
      final globalAudioState =
          Provider.of<GlobalAudioState>(context, listen: false);

      _currentSongName = songName;
      _currentPlaylistId = playlistId;
      _currentPlaylistTitle = playlistTitle;
      _currentPlaylistCover = playlistCover;

      // Update the global audio state
      globalAudioState.updateAudioState(
        true, // isPlaying
        _currentSongName ?? "Unknown Song", // songName
        _currentPlaylistId ?? 0, // playlistId
        _currentPlaylistTitle ?? "Unknown Playlist", // title
        _currentPlaylistCover ?? "", // cover
      );

      _player.play();
      _isPlaying = true;

      notifyListeners(); // Ensure the UI updates

      this.isScheduledPlaylist = isScheduledPlaylist;
    } catch (e) {
      logger.e("Error playing audio: $e");
    }
  }

// Method to pause playback
  void pauseAudio() {
    try {
      _player.pause();
      _isPlaying = false;
      _isPaused = true;
      notifyListeners();
    } catch (e) {
      logger.e("Error pausing audio: $e");
    }
  }

// Toggle between play and pause
  void togglePlayPause(BuildContext context) {
    final globalAudioState =
        Provider.of<GlobalAudioState>(context, listen: false);

    if (_player.playing) {
      pauseAudio();
      _isPaused = true;
    } else {
      // Don't try to play if there's no song loaded
      if (_currentSongName == null || _currentPlaylistId == null) {
        logger.d("No song loaded for playback.");
        return;
      }

      playAudio(
        context: context,
        songName: _currentSongName!,
        playlistId: _currentPlaylistId!,
        playlistTitle: _currentPlaylistTitle ?? "Unknown Playlist",
        playlistCover: _currentPlaylistCover ?? "",
      );
      _isPaused = false;
      globalAudioState.updateAudioState(
        true, // isPlaying
        _currentSongName!, // songName
        _currentPlaylistId!, // playlistId
        _currentPlaylistTitle ?? "Unknown Playlist", // title
        _currentPlaylistCover ?? "", // cover
      );
    }
  }

  ///////////
  void play() {
    if (!_isPlaying) {
      _player.play();
      _isPlaying = true;
      notifyListeners();
      logger.d("Playing new playlist");
    }
  }

  void pause() {
    _player.pause();
    _isPlaying = false;
    _isPaused = true;
    notifyListeners();
    logger.d("Audio paused");
  }

  // Controls small widget
  void togglePlayPauseSmall() {
    if (_player.playing) {
      pauseSmall();
      _isPaused = true;
    } else {
      playSmall();
      _isPaused = false;
    }
  }

  Future<void> stop() async {
    logger.d('Stopping audio playback');

    // Store the current scheduled status before stopping
    bool wasScheduled = isScheduledPlaylist;

    try {
      if (_player.audioSource != null) {
        await _player.stop();
        _isPlaying = false;
        _isPaused = false;
        _isInitialLoad = true;
        notifyListeners();
      }

      // Reset everything except scheduled status
      _currentTrackIndex = 0;
      _currentPlayingSongName = '';
      _currentPlaylistId = null;
      _currentPlaylistTitle = null;
      _currentPlaylistCover = null;
      _tracks = [];
      _currentPlayingSongName = '';

      // Restore the scheduled status instead of resetting it
      setPlaylistDetails(
        playlistId ?? 0,
        playlistTitle ?? '',
        playlistCover ?? '',
        isScheduled: wasScheduled, // Maintain the scheduled status
      );

      // Update the global audio state if context is available
      if (_context != null) {
        try {
          final globalAudioState =
              Provider.of<GlobalAudioState>(_context!, listen: false);
          globalAudioState.updateAudioState(
            false, // isPlaying
            "", // songName
            0, // playlistId
            "", // title
            "", // cover
          );
        } catch (e) {
          logger.e('Error updating global audio state: $e');
        }
      }

      logger.d('Audio playback stopped successfully');
    } catch (e) {
      logger.e('Error stopping audio playback: $e');
      rethrow;
    }
  }

  void playSmall() {
    if (_player.playing) {
      return;
    }
    try {
      _player.play();
    } catch (e) {
      logger.d("Error playing audio: $e");
    }
    _isPlaying = true;
    notifyListeners();
  }

  void pauseSmall() {
    _player.pause();
    _isPlaying = false;
    _isPaused = true;
    notifyListeners();
  }

  void next() {
    logger.d("Next button pressed");
    if (_currentTrackIndex + 1 < _tracks.length) {
      _loadNextTrack();
    } else {
      logger.d("No more tracks to play next.");
    }
  }

  void hideNowPlayingWidget() {
    notifyListeners();
  }

  Future<void> previous() async {
    logger.d("Loading previous track. Current index: $_currentTrackIndex");
    if (_currentTrackIndex > 0) {
      try {
        _currentTrackIndex--;
        var previousSongData = _tracks[_currentTrackIndex];
        logger.d("Previous song data: $previousSongData");
        logger.d("Playlist cover: $_playlistCover");
        logger.d("Context: $_context");
        logger.d(
            "UserSession: ${Provider.of<UserSession>(_context!, listen: false)}");
        logger.d(
            "GlobalToken: ${Provider.of<UserSession>(_context!, listen: false).globalToken}");
        logger.d("Playlist length: ${_playlist.length}");

        // Ensure the previous track is already in the playlist
        if (_currentTrackIndex < _playlist.length) {
          logger.d("Seeking to existing track in playlist");
          await _player.seek(Duration.zero, index: _currentTrackIndex);
        } else {
          logger.d("Adding new track to playlist");
          AudioSource previousAudioSource =
              await _createAudioSource(previousSongData, _playlistCover ?? '');
          await _playlist.add(previousAudioSource);
          await _player.seek(Duration.zero, index: _currentTrackIndex);
        }

        _player.play();
        logger.d("Playing previous track: $_currentTrackIndex");
      } catch (e) {
        logger.d("Error loading previous track: $e");
      }
    } else {
      logger.d("No previous tracks to play.");
    }
  }

  void seek(Duration position) {
    _player.seek(position);
    notifyListeners(); // Update UI with the new position
  }

  void setPlaylistDetails(int id, String title, String cover,
      {bool isScheduled = false}) {
    _playlistId = id;
    _playlistTitle = title;
    _playlistCover = cover;
    _isScheduled = isScheduled;
    notifyListeners();
  }

  Future<bool> likeCurrentTrack(BuildContext context, int playlistId) async {
    String accessToken =
        Provider.of<UserSession>(context, listen: false).globalToken;
    String? trackIdString = _player.sequenceState?.currentSource?.tag.id;

    int trackId = int.parse(trackIdString ?? '0');
    bool success =
        await API().setTrackLikeDislike(trackId, 1, playlistId, accessToken);
    if (success) {
      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            textAlign: TextAlign.center,
            'You Liked this song!',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
          ),
          backgroundColor: Colors.black,
          duration: Duration(seconds: 1),
        ),
      );
      return true;
    } else {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            textAlign: TextAlign.center,
            'You failed to Like this song',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
          ),
          backgroundColor: Colors.black,
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }
  }

  Future<bool> dislikeCurrentTrack(BuildContext context, int playlistId) async {
    String accessToken =
        Provider.of<UserSession>(context, listen: false).globalToken;
    String? trackIdString = _player.sequenceState?.currentSource?.tag.id;

    int trackId = int.parse(trackIdString ?? '0');
    bool success =
        await API().setTrackLikeDislike(trackId, -1, playlistId, accessToken);
    if (success) {
      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            textAlign: TextAlign.center,
            'You Disliked this song',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
          ),
          backgroundColor: Colors.black,
          duration: Duration(seconds: 1),
        ),
      );
      return true;
    } else {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            textAlign: TextAlign.center,
            'Failed to dislike this song',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
          ),
          backgroundColor: Colors.black,
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }
  }

  @override
  void dispose() {
    _isInitialized = false;
    _player.dispose();
    super.dispose();
  }

  /// Initializes or reinitializes the audio source
  Future<void> initializeAudioSource() async {
    try {
      // Create a new empty concatenating audio source
      _playlist = ConcatenatingAudioSource(children: []);
      await _player.setAudioSource(_playlist, initialIndex: 0);
    } catch (e) {
      print('Error initializing audio source: $e');
      rethrow;
    }
  }

  /// Resets the audio provider state
  Future<void> reset() async {
    logger.d('Resetting audio provider state');
    try {
      // Don't stop playback if something is playing
      if (!_isPlaying && !_isPaused) {
        if (_player.playing) {
          await _player.stop();
        }

        // Only reset state if nothing is playing
        _isPlaying = false;
        _isPaused = false;
        _currentSongName = null;
        _currentPlaylistId = null;
        _currentPlaylistTitle = null;
        _currentPlaylistCover = null;
        _currentPlayingSongName = '';
        _currentTrackIndex = 0;
        _tracks = [];
        _isInitialLoad = true;

        // Update global audio state if context is available
        if (_context != null) {
          try {
            final globalAudioState =
                Provider.of<GlobalAudioState>(_context!, listen: false);
            globalAudioState.updateAudioState(
              false, // isPlaying
              "", // songName
              0, // playlistId
              "", // title
              "", // cover
            );
          } catch (e) {
            logger.e('Error updating global audio state during reset: $e');
          }
        }

        // Reinitialize audio source only if we're actually resetting
        await initializeAudioSource();
      }

      notifyListeners();
      logger.d('Audio provider state reset successfully');
    } catch (e) {
      logger.e('Error resetting audio provider state: $e');
      rethrow;
    }
  }

  Future<void> setOfflinePlaylist(List<Map<String, dynamic>> tracks) async {
    try {
      // Initialize audio source with local files
      await initializeAudioSource();
      final audioSources = tracks.map((track) {
        return AudioSource.uri(Uri.file(track['filePath']));
      }).toList();

      // Clear previous playlist if any
      if (_playlist.length > 0) {
        await _playlist.clear();
      }

      // Add loaded tracks to the playlist
      if (audioSources.isNotEmpty) {
        await _playlist.addAll(audioSources);
        // Set the playlist but do not start playback yet
        await _player.setAudioSource(_playlist,
            initialIndex: 0, initialPosition: Duration.zero);
      }

      notifyListeners();
    } catch (e) {
      logger.e('Error setting offline playlist: $e');
    }
  }

  Future<AudioProvider> initialize() async {
    if (!_isInitialized) {
      return AudioProvider(_context!); // Return new instance with context
    }
    return this;
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}
