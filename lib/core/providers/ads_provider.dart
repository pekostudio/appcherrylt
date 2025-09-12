import 'dart:typed_data';
import 'package:appcherrylt/core/providers/audio_provider.dart';
import 'package:appcherrylt/core/models/user_session.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
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

class AdsProvider extends ChangeNotifier {
  final AudioProvider _audioProvider;
  String baseUrl = 'https://app.cherrymusic.lt/api/tracks';
  BuildContext? _context;
  final Logger logger = Logger();

  AdsProvider(this._audioProvider);

  void setContext(BuildContext context) {
    _context = context;
  }

  Future<Uint8List> fetchAudioData(String urlWithToken) async {
    try {
      http.Response response =
          await http.get(Uri.parse(urlWithToken), headers: {
        'Authorization':
            'Basic YXBwOnd5cWQ3eWdqbmpvOXVyaGdmem5yYmc4amI3OGI3bWZ1',
      });

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to fetch audio data: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error fetching audio data: $e');
      rethrow;
    }
  }

  Future<void> createAdsSource(String adsId) async {
    if (_context == null) {
      throw Exception("Context not set");
    }

    try {
      String urlWithToken =
          "$baseUrl/$adsId/stream?access_token=${Provider.of<UserSession>(_context!, listen: false).globalToken}";
      Uint8List audioData = await fetchAudioData(urlWithToken);

      // Create the MediaItem for the ad
      MediaItem mediaItem = MediaItem(
        id: adsId,
        album: 'Ad',
        title: 'Advertisement',
        artUri: Uri.parse(
            'https://app.cherrymusic.lt/img/covers/shopping-mall-g7c1d47fcb-1920_9yDSZsp3_thumb480x480.jpg'),
      );

      AudioSource audioSource = MyJABytesSource(audioData, mediaItem);

      // Play the ad using the AudioProvider's playAd method
      await _audioProvider.playAd(audioSource);
    } catch (error) {
      logger.e("Failed to create ads source: $error");
      throw Exception("Failed to create ads source");
    }
  }
}
