import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;

class OfflinePlaylistData {
  static const String _offlinePlaylistsKey = 'offline_playlists';
  static final Logger logger = Logger();

  static Future<void> markPlaylistAsOffline(int playlistId) async {
    final prefs = await SharedPreferences.getInstance();
    final offlinePlaylists = prefs.getStringList(_offlinePlaylistsKey) ?? [];
    if (!offlinePlaylists.contains(playlistId.toString())) {
      offlinePlaylists.add(playlistId.toString());
      await prefs.setStringList(_offlinePlaylistsKey, offlinePlaylists);
    }
  }

  static Future<List<int>> getOfflinePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final offlinePlaylists = prefs.getStringList(_offlinePlaylistsKey) ?? [];
    return offlinePlaylists
        .map((id) => int.tryParse(id) ?? 0)
        .where((id) => id != 0)
        .toList();
  }

  static Future<String?> getCoverImagePath(int playlistId) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$playlistId/cover.jpg';
    final file = File(filePath);
    if (await file.exists()) {
      return filePath;
    }
    return null;
  }

  static Future<void> removeOfflinePlaylist(int playlistId) async {
    final prefs = await SharedPreferences.getInstance();
    final offlinePlaylists = prefs.getStringList(_offlinePlaylistsKey) ?? [];
    if (offlinePlaylists.remove(playlistId.toString())) {
      await prefs.setStringList(_offlinePlaylistsKey, offlinePlaylists);
    }
  }

  static Future<List<dynamic>> getOfflineTracks(int playlistId) async {
    final directory = await getApplicationDocumentsDirectory();
    final playlistDirectory = Directory('${directory.path}/$playlistId');

    if (!await playlistDirectory.exists()) {
      return [];
    }

    List<dynamic> tracks = [];
    await for (var entity in playlistDirectory.list()) {
      if (entity is File && entity.path.endsWith('.mp3')) {
        final fileName = path.basename(entity.path);
        final parts = fileName.split(' - ');
        if (parts.length >= 2) {
          tracks.add({
            'id': tracks.length,
            'artist': parts[0],
            'title': parts[1].replaceAll('.mp3', ''),
            'filePath': entity.path,
          });
        }
      }
    }

    return tracks;
  }

  // Download cover image
  Future<void> downloadCoverImage(String url, int playlistId) async {
    try {
      logger.d('Starting download of cover image from $url');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = path.join(directory.path, '$playlistId', 'cover.jpg');
        final file = File(filePath);
        await file.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);
        logger.d('Cover image downloaded and saved to $filePath');
      } else {
        logger.e(
            'Failed to download cover image. Status code: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error downloading cover image: $e');
    }
  }

  static Future<void> deletePlaylistFiles(int playlistId) async {
    final directory = await getApplicationDocumentsDirectory();
    final playlistDirectory = Directory('${directory.path}/$playlistId');

    logger
        .d('Attempting to delete playlist files for playlist ID: $playlistId');

    if (await playlistDirectory.exists()) {
      try {
        int fileCount = 0;
        await for (var entity in playlistDirectory.list()) {
          if (entity is File) {
            logger.d('Deleting file: ${entity.path}');
            await entity.delete();
            fileCount++;
          }
        }

        await playlistDirectory.delete(recursive: true);
        logger.d(
            'Successfully deleted playlist directory: ${playlistDirectory.path}');
        logger.d('Total files deleted: $fileCount');
      } catch (e) {
        logger.e('Error deleting playlist files: $e');
      }
    } else {
      logger.d('Playlist directory does not exist: ${playlistDirectory.path}');
    }
  }
}
