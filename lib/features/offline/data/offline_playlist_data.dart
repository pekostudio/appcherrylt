import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;

class OfflinePlaylistData {
  static const String _offlinePlaylistsKey = 'offline_playlists';
  static final Logger logger = Logger();

  static Future<void> markPlaylistAsOffline(
      int playlistId, String name, String coverPath) async {
    logger.d(
        'Marking playlist as offline - ID: $playlistId, Name: $name, Cover: $coverPath');
    final prefs = await SharedPreferences.getInstance();
    final offlinePlaylists = prefs.getStringList(_offlinePlaylistsKey) ?? [];

    // Add to offline playlists list if not already there
    if (!offlinePlaylists.contains(playlistId.toString())) {
      offlinePlaylists.add(playlistId.toString());
      await prefs.setStringList(_offlinePlaylistsKey, offlinePlaylists);
    }

    // Store name
    await prefs.setString('playlist_name_$playlistId', name);

    // Only store cover path if it's a local file path (not a URL)
    if (!coverPath.startsWith('http')) {
      await prefs.setString('playlist_cover_$playlistId', coverPath);
      logger.d('Stored local cover path: $coverPath');
    } else {
      logger.d('Skipping URL cover path storage: $coverPath');
    }

    logger.d(
        'Playlist metadata stored - Name: ${prefs.getString('playlist_name_$playlistId')}, Cover: ${prefs.getString('playlist_cover_$playlistId')}');
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
    final prefs = await SharedPreferences.getInstance();
    final coverPath = prefs.getString('playlist_cover_$playlistId');
    logger.d('Getting cover path for playlist $playlistId: $coverPath');

    if (coverPath != null) {
      final file = File(coverPath);
      final exists = await file.exists();
      logger.d('Cover file exists: $exists for path: $coverPath');
      if (exists) {
        return coverPath;
      } else {
        logger.d('Cover file does not exist at path: $coverPath');
      }
    } else {
      logger.d(
          'No cover path stored in SharedPreferences for playlist $playlistId');
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

  static Future<List<Map<String, dynamic>>> getOfflineTracks(
      int playlistId) async {
    final directory = await getApplicationDocumentsDirectory();
    final playlistDirectory = Directory('${directory.path}/$playlistId');

    if (!await playlistDirectory.exists()) {
      return [];
    }

    List<Map<String, dynamic>> tracks = [];
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
      logger.d(
          'Starting download of cover image from $url for playlist $playlistId');

      // Validate URL
      if (url.isEmpty) {
        logger.e('Empty URL provided for cover image download');
        return;
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final playlistDir = Directory('${directory.path}/$playlistId');
        final filePath = path.join(playlistDir.path, 'cover.jpg');

        // Ensure directory exists
        if (!await playlistDir.exists()) {
          await playlistDir.create(recursive: true);
          logger.d('Created playlist directory: ${playlistDir.path}');
        }

        // Save the file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Verify file was written
        if (await file.exists()) {
          logger.d('Cover image downloaded and saved to $filePath');
          logger.d('File size: ${await file.length()} bytes');

          // Save the cover image path in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('playlist_cover_$playlistId', filePath);

          // Verify SharedPreferences was updated
          final savedPath = prefs.getString('playlist_cover_$playlistId');
          logger.d('Verified cover path in SharedPreferences: $savedPath');
        } else {
          logger.e('File was not created after write attempt');
        }
      } else {
        logger.e(
            'Failed to download cover image. Status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      logger.e('Error downloading cover image: $e');
      logger.e('Stack trace: $stackTrace');
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

  static Future<String?> getPlaylistName(int playlistId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('playlist_name_$playlistId');
  }

  static Future<void> verifyAndCleanupCoverPath(int playlistId) async {
    final prefs = await SharedPreferences.getInstance();
    final coverPath = prefs.getString('playlist_cover_$playlistId');

    if (coverPath != null) {
      final file = File(coverPath);
      if (!await file.exists()) {
        logger.d('Removing invalid cover path for playlist $playlistId');
        await prefs.remove('playlist_cover_$playlistId');
      }
    }
  }
}
