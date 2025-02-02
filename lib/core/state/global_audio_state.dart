import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger();

class GlobalAudioState with ChangeNotifier {
  bool _isPlaying = false;
  String _currentPlaylistCover = '';
  String _currentPlaylistTitle = '';
  String _currentSongName = '';
  int _currentPlaylistId = 0;

  GlobalAudioState(currentPlaylistCover);

  bool get isPlaying => _isPlaying;
  String get currentPlaylistCover => _currentPlaylistCover;
  String get currentPlaylistTitle => _currentPlaylistTitle;
  String get currentSongName => _currentSongName;
  int get currentPlaylistId => _currentPlaylistId;

  void setCurrentPlaylistId(int playlistId) {
    if (_currentPlaylistId != playlistId) {
      _currentPlaylistId = playlistId;
      notifyListeners();
    }
  }

  void updateAudioState(bool isPlaying, String songName, int playlistId,
      String title, String cover) {
    _isPlaying = isPlaying;
    _currentPlaylistCover = cover;
    _currentPlaylistTitle = title;
    _currentSongName = songName;
    _currentPlaylistId = playlistId;
    logger.d("Global audio state has been changed");
    notifyListeners();
  }
}
