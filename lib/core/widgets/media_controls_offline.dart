import 'package:appcherrylt/core/providers/audio_provider_offline.dart';
import 'package:appcherrylt/core/widgets/custom_player_seekbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

class MediaControlsOffline extends StatelessWidget {
  final int playlistId;
  static final Logger logger = Logger();

  const MediaControlsOffline({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProviderOffline>(context);

    // Verify if we're showing controls for the correct playlist
    if (audioProvider.currentPlaylistId != playlistId) {
      logger.d(
          'MediaControls playlist ID mismatch: expected $playlistId but got ${audioProvider.currentPlaylistId}');
      return const SizedBox.shrink();
    }

    // Verify if the provider has tracks loaded
    if (!audioProvider.isPlaying && !audioProvider.isPaused) {
      logger.d('MediaControls: no active playback for playlist $playlistId');
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
              child: Text(
                audioProvider.currentPlayingSongName,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<PositionData>(
              stream: audioProvider.positionDataStream,
              builder: (context, snapshot) {
                final positionData = snapshot.data;
                return SeekBar(
                  duration: positionData?.duration ?? Duration.zero,
                  position: positionData?.position ?? Duration.zero,
                  bufferedPosition:
                      positionData?.bufferedPosition ?? Duration.zero,
                  onChanged: (newPosition) {
                    audioProvider.seek(newPosition);
                  },
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 56.0,
                  onPressed: audioProvider.previous,
                ),
                IconButton(
                  icon: audioProvider.isPlaying
                      ? SvgPicture.asset('assets/images/btn-pause.svg',
                          width: 92.0, height: 92.0)
                      : SvgPicture.asset('assets/images/btn-play.svg',
                          width: 92.0, height: 92.0),
                  onPressed: () => audioProvider.togglePlayPause(context),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 56.0,
                  onPressed: audioProvider.next,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ],
    );
  }
}
