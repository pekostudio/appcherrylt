import 'package:appcherrylt/core/widgets/media_controls_small.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:appcherrylt/core/providers/audio_provider.dart';
import 'package:logger/logger.dart';

class NowPlayingWidget extends StatelessWidget {
  final int playlistId;
  final String playlistTitle;
  final String playlistCover;
  final String songName;
  final bool isOnMusicPage;
  final VoidCallback openModal;

  NowPlayingWidget({
    super.key,
    required this.playlistId,
    required this.playlistTitle,
    required this.playlistCover,
    required this.songName,
    required this.isOnMusicPage,
    required this.openModal,
  });

  final Logger logger = Logger();

  void _handleTap(BuildContext context) {
    openModal();
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    } else {
      return '${text.substring(0, maxLength - 3)}...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: RepaintBoundary(
        child: Container(
          height: 130,
          color: theme.cardColor,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.black.withAlpha(77),
                            BlendMode.darken,
                          ),
                          child: Image.network(
                            playlistCover,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.error),
                          ),
                        ),
                      ),
                      Selector<AudioProvider, bool>(
                        selector: (_, provider) => provider.isPlaying,
                        builder: (_, isPlaying, __) {
                          return isPlaying
                              ? Lottie.asset(
                                  'assets/images/Animation_-_1713696970727.json',
                                  width: 56,
                                  height: 56,
                                )
                              : const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _truncateText(songName, 50),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          playlistTitle.characters.take(50).toString() +
                              (playlistTitle.length > 50 ? '...' : ''),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: MediaControlsSmall(
                      playlistId: playlistId,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: StreamBuilder<PositionData>(
                  stream:
                      Provider.of<AudioProvider>(context).positionDataStream,
                  builder: (context, snapshot) {
                    final positionData = snapshot.data;
                    final duration = positionData?.duration ?? Duration.zero;
                    final position = positionData?.position ?? Duration.zero;
                    final progress = duration.inMilliseconds > 0
                        ? position.inMilliseconds / duration.inMilliseconds
                        : 0.0;

                    return LinearProgressIndicator(
                      value: progress,
                      backgroundColor: theme.colorScheme.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.secondary),
                      minHeight: 3,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
