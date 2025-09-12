import 'package:flutter/material.dart';

class FavoriteManager with ChangeNotifier {
  final Map<int, bool> _favorites = {};

  // Get favorite status for a specific playlist
  bool isFavorite(int playlistId) {
    return _favorites[playlistId] ?? false;
  }

  // Set favorite status for a specific playlist
  void setFavorite(int playlistId, bool isFavorite) {
    _favorites[playlistId] = isFavorite;
    notifyListeners();
  }

  // Load initial favorite statuses from the server
  Future<void> loadFavorites(List<dynamic> playlists) async {
    for (var playlist in playlists) {
      int id = playlist['id'];
      bool status = playlist['favorite'];
      _favorites[id] = status;
    }
    notifyListeners();
  }
}
