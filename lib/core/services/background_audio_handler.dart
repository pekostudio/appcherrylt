import 'dart:async';
//import 'dart:io';
import 'dart:convert';
//import 'dart:isolate';

//import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:http/http.dart' as http;
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class BackgroundAudioHandler {
  static final AudioPlayer _player = AudioPlayer(
    handleInterruptions: true,
    androidApplyAudioAttributes: true,
    // androidAudioOffloadPreferences: AndroidAudioOffloadPreferences.enabled, // TODO: Fix enum values
  );
  static final Logger _logger = Logger();
  static bool _isInitialized = false;

  // Initialize the audio handler
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Mark as initialized without initializing JustAudioBackground again
      // since it's already done in main.dart
      _isInitialized = true;
      return true;
    } catch (e) {
      _logger.e('Error initializing audio background: $e');
      return false;
    }
  }

  // Method to load and play a scheduled playlist
  static Future<bool> loadAndPlayScheduledPlaylist(int playlistId) async {
    try {
      _logger.d('Loading scheduled playlist in background: $playlistId');

      // Get access token from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        _logger.e('No access token available for background playback');
        return false;
      }

      // Fetch playlist tracks
      final tracks = await _fetchPlaylistTracks(accessToken, playlistId);
      if (tracks == null || tracks.isEmpty) {
        _logger.e('Failed to fetch playlist tracks for ID: $playlistId');
        return false;
      }

      // Create audio sources
      final List<AudioSource> audioSources = [];
      final baseUrl = 'https://app.cherrymusic.lt';

      for (var i = 0; i < tracks.length && i < 5; i++) {
        final track = tracks[i];
        try {
          final url = '$baseUrl${track['file']}';
          audioSources.add(
            AudioSource.uri(
              Uri.parse(url),
              tag: MediaItem(
                id: track['id'].toString(),
                title: track['title'] ?? 'Unknown',
                album: track['artist'] ?? 'Unknown Artist',
                artUri: Uri.parse('$baseUrl${track['cover']}'),
              ),
            ),
          );
        } catch (e) {
          _logger.e('Error creating audio source for track ${track['id']}: $e');
        }
      }

      if (audioSources.isEmpty) {
        _logger.e('No audio sources created');
        return false;
      }

      try {
        // Stop any current playback
        await _player.stop();

        // Set audio sources directly using the new API
        await _player.setAudioSources(audioSources, initialIndex: 0);
        await _player.play();

        _logger.d('Started playback of scheduled playlist: $playlistId');
        return true;
      } catch (e) {
        _logger.e('Error during audio playback setup: $e');
        // Continue with SharedPreferences updates even if playback fails
      }

      // Update shared preferences to indicate active scheduled playlist
      await prefs.setInt('active_playlist_id', playlistId);
      final playlistName = tracks.first['title'] ?? 'Unknown Playlist';
      await prefs.setString('active_playlist_name', playlistName);
      await prefs.setBool('has_active_schedule', true);

      return true;
    } catch (e) {
      _logger.e('Error playing scheduled playlist: $e');
      return false;
    }
  }

  // Method to stop playback
  static Future<void> stop() async {
    await _player.stop();
  }

  // Fetch playlist tracks from API
  static Future<List<dynamic>?> _fetchPlaylistTracks(
      String accessToken, int playlistId) async {
    final url =
        Uri.parse('https://app.cherrymusic.lt/api/playlist/$playlistId/tracks')
            .replace(queryParameters: {'access_token': accessToken});

    final headers = {
      'Authorization': 'Basic YXBwOnd5cWQ3eWdqbmpvOXVyaGdmem5yYmc4amI3OGI3bWZ1',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = await compute(_parseJson, response.body);
        if (data != null && data['error'] == null && data['data'] != null) {
          return data['data'];
        }
      }
    } catch (e) {
      _logger.e('Error fetching playlist tracks: $e');
    }

    return null;
  }

  // Parse JSON in a separate isolate
  static Map<String, dynamic>? _parseJson(String responseBody) {
    try {
      return json.decode(responseBody) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
