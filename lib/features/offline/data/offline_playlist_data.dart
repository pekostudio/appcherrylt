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

    // Store relative path for cover
    if (!coverPath.startsWith('http')) {
      final directory = await getApplicationDocumentsDirectory();
      String relativePath = coverPath.replaceFirst('${directory.path}/', '');

      // Ensure the relative path format is correct
      if (!relativePath.startsWith('$playlistId/')) {
        relativePath = '$playlistId/cover.jpg';
      }

      await prefs.setString('playlist_cover_$playlistId', relativePath);
      logger.d('Stored relative cover path: $relativePath');

      // Verify the file exists
      final file = File('${directory.path}/$relativePath');
      if (await file.exists()) {
        logger.d('Verified cover file exists at: ${file.path}');
      } else {
        logger.e('Cover file not found at: ${file.path}');
      }
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
    final relativePath = prefs.getString('playlist_cover_$playlistId');
    logger.d(
        'Getting relative cover path for playlist $playlistId: $relativePath');

    if (relativePath != null) {
      final directory = await getApplicationDocumentsDirectory();
      final absolutePath = '${directory.path}/$relativePath';
      final file = File(absolutePath);
      final exists = await file.exists();
      logger.d('Cover file exists: $exists for path: $absolutePath');

      // Verify the path belongs to the correct playlist
      if (exists && absolutePath.contains('/$playlistId/')) {
        return absolutePath;
      } else {
        logger.d(
            'Cover file does not exist or path is invalid for playlist $playlistId');
        // Clean up invalid path
        await prefs.remove('playlist_cover_$playlistId');
      }
    } else {
      logger.d(
          'No cover path stored in SharedPreferences for playlist $playlistId');
    }
    return null;
  }

  static Future<void> removeOfflinePlaylist(int playlistId) async {
    final prefs = await SharedPreferences.getInstance();

    // Remove from offline playlists list
    final offlinePlaylists = prefs.getStringList(_offlinePlaylistsKey) ?? [];
    if (offlinePlaylists.remove(playlistId.toString())) {
      await prefs.setStringList(_offlinePlaylistsKey, offlinePlaylists);
    }

    // Clean up all related SharedPreferences entries
    await prefs.remove('playlist_name_$playlistId');
    await prefs.remove('playlist_cover_$playlistId');

    logger.d('Removed all SharedPreferences entries for playlist $playlistId');
  }

  static Future<List<Map<String, dynamic>>> getOfflineTracks(
      int playlistId) async {
    final tracks = <Map<String, dynamic>>[];
    final directory = await getApplicationDocumentsDirectory();
    final playlistDirectory = Directory('${directory.path}/$playlistId');

    logger.d('Loading tracks for playlist ID: $playlistId');
    logger.d('Playlist directory: ${playlistDirectory.path}');

    if (!await playlistDirectory.exists()) {
      logger.d('Playlist directory does not exist: ${playlistDirectory.path}');
      return [];
    }

    try {
      await for (var entity in playlistDirectory.list()) {
        if (entity is File && entity.path.endsWith('.mp3')) {
          // Verify the file belongs to the correct playlist directory
          if (!entity.path.contains('/$playlistId/')) {
            logger.w(
                'Skipping file not in correct playlist directory: ${entity.path}');
            continue;
          }

          final fileName = path.basename(entity.path);
          final trackName = fileName.replaceAll('.mp3', '');

          final parts = trackName.split(' - ');
          final artist = parts.isNotEmpty ? parts[0] : 'Unknown Artist';
          final title = parts.length > 1 ? parts[1] : trackName;

          final track = {
            'filePath': entity.path,
            'id': tracks.length + 1,
            'title': title,
            'artist': artist,
            'name': trackName,
            'playlistId': playlistId, // Ensure playlist ID is included
          };

          tracks.add(track);
          logger.d(
              'Loaded track: $trackName from ${entity.path} for playlist $playlistId');
        }
      }

      logger.d(
          'Successfully loaded ${tracks.length} tracks for playlist $playlistId');
      return tracks;
    } catch (e) {
      logger.e('Error loading tracks for playlist $playlistId: $e');
      return [];
    }
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
        final fileName = 'cover.jpg';
        final relativePath = '$playlistId/$fileName';
        final absolutePath = '${directory.path}/$relativePath';

        // Ensure directory exists
        if (!await playlistDir.exists()) {
          await playlistDir.create(recursive: true);
          logger.d('Created playlist directory: ${playlistDir.path}');
        }

        // Delete existing cover file if it exists
        final existingFile = File(absolutePath);
        if (await existingFile.exists()) {
          await existingFile.delete();
          logger.d('Deleted existing cover file');
        }

        // Save the file
        final file = File(absolutePath);
        await file.writeAsBytes(response.bodyBytes);

        // Verify file was written
        if (await file.exists()) {
          logger.d('Cover image downloaded and saved to $absolutePath');
          logger.d('File size: ${await file.length()} bytes');

          // Store relative path in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('playlist_cover_$playlistId', relativePath);
          logger.d('Stored relative path in SharedPreferences: $relativePath');

          // Verify the file can be accessed using the relative path
          final verifyPath = '${directory.path}/$relativePath';
          final verifyFile = File(verifyPath);
          if (await verifyFile.exists()) {
            logger.d('Verified cover file is accessible using relative path');
          } else {
            logger.e('Cover file not accessible using relative path');
          }
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
    final relativePath = prefs.getString('playlist_cover_$playlistId');

    if (relativePath != null) {
      final directory = await getApplicationDocumentsDirectory();
      final absolutePath = '${directory.path}/$relativePath';
      final file = File(absolutePath);
      if (!await file.exists()) {
        logger.d('Removing invalid cover path for playlist $playlistId');
        await prefs.remove('playlist_cover_$playlistId');
      }
    }
  }

  static Future<void> cleanupOrphanedFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final prefs = await SharedPreferences.getInstance();
      final offlinePlaylists = prefs.getStringList(_offlinePlaylistsKey) ?? [];

      // Get all directories in app documents
      final dirs = directory.listSync().whereType<Directory>();

      for (var dir in dirs) {
        final dirName = path.basename(dir.path);
        final playlistId = int.tryParse(dirName);

        // If directory name is not a valid playlist ID or playlist is not in offline list
        if (playlistId == null ||
            !offlinePlaylists.contains(playlistId.toString())) {
          logger.d('Removing orphaned directory: ${dir.path}');
          await dir.delete(recursive: true);
        }
      }
    } catch (e) {
      logger.e('Error cleaning up orphaned files: $e');
    }
  }
}
