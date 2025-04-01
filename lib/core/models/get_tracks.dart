import 'dart:async';
import 'dart:convert';
import 'package:appcherrylt/features/audio/providers/download_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:appcherrylt/core/models/user_session.dart';
import 'package:logger/logger.dart';

class GetTracks with ChangeNotifier {
  List<dynamic> _tracks = [];
  List<dynamic> get tracks => _tracks;
  final Logger logger = Logger();
  final DownloadService _downloadService = DownloadService();
  final StreamController<int> _downloadProgressController =
      StreamController<int>.broadcast();
  Stream<int> get downloadProgressStream => _downloadProgressController.stream;

  Future<void> fetchAndNotifyTracks(
      BuildContext context, int playlistId) async {
    try {
      _tracks = await fetchTracks(context, playlistId);
      notifyListeners();
    } catch (e) {
      logger.d("Failed to fetch tracks: $e");
    }
  }

  Future<List<dynamic>> fetchTracks(
      BuildContext context, int playlistId) async {
    String accessToken =
        Provider.of<UserSession>(context, listen: false).globalToken;
    var url = Uri.parse(
        'https://app.cherrymusic.lt/api/playlists/$playlistId/tracks?access_token=$accessToken');

    var headers = {
      'Authorization': 'Basic YXBwOnd5cWQ3eWdqbmpvOXVyaGdmem5yYmc4amI3OGI3bWZ1',
    };

    var response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data != null && data['data'] != null) {
        return List<dynamic>.from(data['data']);
      } else {
        logger.d('API Response: ${response.body}');
        return [];
      }
    } else {
      throw Exception('Failed to load tracks: ${response.body}');
    }
  }

  Future<void> downloadTracks(
    BuildContext context,
    int count,
    int playlistId,
  ) async {
    try {
      // Clear existing tracks before fetching new ones
      _tracks = [];
      logger.i('Fetching tracks for playlist $playlistId...');

      try {
        _tracks = await fetchTracks(context, playlistId);
        logger.i(
            'Successfully fetched ${_tracks.length} tracks for playlist $playlistId');
      } catch (e) {
        logger.e('Error fetching tracks for download: $e');
        rethrow; // Re-throw to be caught by the outer try-catch
      }

      if (_tracks.isEmpty) {
        logger.e('No tracks available to download after fetching');
        return;
      }

      String accessToken =
          Provider.of<UserSession>(context, listen: false).globalToken;

      if (accessToken.isEmpty) {
        logger.e('Access token is empty');
        throw Exception('Authentication error: Access token is empty');
      }

      logger.i(
          'Starting download of $count tracks with token: ${accessToken.substring(0, 10)}...');

      List<dynamic> tracksToDownload = _tracks.take(count).toList();
      int downloadedCount = 0;

      for (var track in tracksToDownload) {
        String trackStream = track['stream'] ?? '';
        String trackTitle = track['title'] ?? 'Unknown Track';
        String trackArtist = track['artist'] ?? 'Unknown Artist';

        if (trackStream.isEmpty) {
          logger.w(
              "Skipping track download: Stream URL is empty for track $trackTitle by $trackArtist");
          continue;
        }

        String fullStreamUrl = 'https://app.cherrymusic.lt$trackStream';
        String fileName = '$trackArtist - $trackTitle.mp3';

        logger.i('Downloading file: $fileName');

        await _downloadService.downloadFile(
            fullStreamUrl, fileName, accessToken, playlistId);

        downloadedCount++;
        _downloadProgressController.add(downloadedCount);
        logger.i('Successfully downloaded track $downloadedCount/$count');
      }

      logger.i('All downloads completed. Total: $downloadedCount tracks');
    } catch (e) {
      logger.e("Failed to download tracks: $e");
      rethrow; // Rethrow to allow UI to handle the error
    }
  }

  @override
  void dispose() {
    _downloadProgressController.close();
    super.dispose();
  }
}
