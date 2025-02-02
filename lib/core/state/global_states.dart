import 'package:flutter/material.dart';

class GlobalStates extends ChangeNotifier {
  int? _playlistId;

  int? get playlistId => _playlistId;

  void setPlaylistId(int id) {
    _playlistId = id;
    notifyListeners();
  }
}
