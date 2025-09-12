import 'package:flutter/material.dart';
import 'package:appcherrylt/api/api.dart';
import 'package:appcherrylt/core/models/favourites.dart';

class GetPlaylists with ChangeNotifier {
  List<dynamic>? _playlists;
  List<dynamic>? get playlists => _playlists;

  List<int>? _playlistsCategoryId;
  List<int>? get playlistsCategoryId => _playlistsCategoryId;

  Map<int, String> _categoryNames = {};
  Map<int, String> get categoryNames => _categoryNames;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  final API api = API();

  Future<void> fetchTracks(
      String token, FavoriteManager favoriteManager) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final playlists = await API().getPlaylists(token);
      _playlists = playlists;
      _playlistsCategoryId = _extractCategoryIds(playlists);
      _categoryNames = _extractCategoryNames(playlists);
      _isLoading = false;
      if (playlists != null) {
        favoriteManager.loadFavorites(playlists);
      }
      notifyListeners();
    } catch (err) {
      _error = 'Failed to load tracks: $err';
      _playlists = null;
      _playlistsCategoryId = null;
      _categoryNames = {};
      _isLoading = false;
      notifyListeners();
    }
  }

  // Category Id's unique list
  List<int> _extractCategoryIds(List<dynamic>? playlists) {
    if (playlists == null) return [];
    var ids = playlists
        .map((playlist) {
          return playlist['category_id'] as int;
        })
        .toSet()
        .toList(); // Convert to Set to remove duplicates, then back to List
    return ids;
  }

  // Filter playlists by category ID
  List<dynamic> getPlaylistsByCategoryId(int categoryId) {
    return _playlists
            ?.where((playlist) => playlist['category_id'] == categoryId)
            .toList() ??
        [];
  }

  // Category names
  Map<int, String> _extractCategoryNames(List<dynamic>? playlists) {
    if (playlists == null) return {};
    Map<int, String> names = {};
    for (var playlist in playlists) {
      int id = playlist['category_id'];
      String name = playlist['category_name'];
      names[id] = name;
    }
    return names;
  }

  List<dynamic>? get favoritePlaylists {
    return _playlists
        ?.where((playlist) => playlist['favorite'] as bool)
        .toList();
  }

  void updateFavoriteStatus(String playlistId, bool isFavorite) {
    // Find the playlist by ID and update its favorite status
    var playlist = playlists?.firstWhere((p) => p['id'] == playlistId);
    if (playlist != null) {
      playlist['favorite'] = isFavorite;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchPlaylistDetails(
      int playlistId, String accessToken) async {
    try {
      if (_playlists == null || _playlists!.isEmpty) {
        throw Exception('Playlists not loaded');
      }

      var playlist = _playlists?.firstWhere((p) => p['id'] == playlistId,
          orElse: () => null);
      if (playlist != null) {
        return playlist;
      } else {
        throw Exception('Playlist not found');
      }
    } catch (e) {
      throw Exception('Failed to fetch playlist details: $e');
    }
  }
}
