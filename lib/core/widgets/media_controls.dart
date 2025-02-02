import 'package:appcherrylt/core/providers/audio_provider.dart';
import 'package:appcherrylt/core/widgets/custom_player_seekbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class MediaControls extends StatelessWidget {
  final int playlistId;

  const MediaControls({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  16.0, 0, 16.0, 0), // Adjust the padding as needed
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
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () =>
                      audioProvider.dislikeCurrentTrack(context, playlistId),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: SvgPicture.asset(
                      'assets/images/icon-dislike.svg',
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const Text(
                  'RATE THIS SONG',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.1,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      audioProvider.likeCurrentTrack(context, playlistId),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: SvgPicture.asset(
                      'assets/images/icon-like.svg',
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        // Loading spinner only when audio is loading, not during playlist population
        if (audioProvider.isLoading && !audioProvider.isInitialLoad)
          Positioned.fill(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: const Center(
                child: SizedBox(
                  width: 80.0, // Adjust the width as needed
                  height: 80.0, // Adjust the height as needed
                  child: CircularProgressIndicator(
                    color: Colors.red,
                    strokeWidth: 5.0, // Adjust the stroke width as needed
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
