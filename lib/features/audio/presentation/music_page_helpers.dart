// music_page_helpers.dart
import 'package:flutter/material.dart';
import 'package:appcherrylt/core/providers/audio_provider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:appcherrylt/core/models/get_tracks.dart';
import 'dart:math';

Future<void> populatePlaylist(
    BuildContext context, dynamic widget, Logger logger) async {
  final audioProvider = Provider.of<AudioProvider>(context, listen: false);

  try {
    // Wait for any existing audio operations to complete
    await audioProvider.stop();

    final tracks = await Provider.of<GetTracks>(context, listen: false)
        .fetchTracks(context, widget.id);

    if (!context.mounted) return;

    if (tracks.isNotEmpty) {
      // Create a new shuffled list instead of modifying the original
      final shuffledTracks = List.from(tracks)..shuffle(Random());

      try {
        // Initialize the audio source before setting playlist
        await audioProvider.initializeAudioSource();
      } catch (e) {
        logger.e('Error initializing audio source: $e');
        throw Exception('Failed to initialize audio player');
      }

      if (!context.mounted) return;

      await audioProvider.setPlaylist(shuffledTracks, context, widget.cover);
      logger.d("Playlist populated with ${tracks.length} tracks");
    } else {
      logger.d('No tracks available');
      throw Exception('No tracks available for this playlist');
    }
  } catch (e) {
    logger.e('Error populating playlist: $e');
    rethrow;
  }
}
