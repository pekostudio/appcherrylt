import 'package:appcherrylt/core/state/global_audio_state.dart';
import 'package:appcherrylt/core/widgets/media_controls.dart';
import 'package:appcherrylt/core/widgets/media_controls_small.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:appcherrylt/core/providers/audio_provider.dart';
import 'package:logger/logger.dart';

class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({super.key});

  @override
  AudioPlayerWidgetState createState() => AudioPlayerWidgetState();
}

class AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final Logger logger = Logger();
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final audioProvider = Provider.of<AudioProvider>(context);
    final globalAudioState = Provider.of<GlobalAudioState>(context);
    logger
        .d("Current Playlist Cover: ${globalAudioState.currentPlaylistCover}");

    return GestureDetector(
      onTap: !_isExpanded ? _toggleExpand : null, // Only expand on tap
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _isExpanded ? screenHeight : screenHeight * 0.15,
        color: theme.cardColor,
        padding: const EdgeInsets.all(16.0),
        child: _isExpanded
            ? Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 98),
                        Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.6,
                            height: MediaQuery.of(context).size.width * 0.6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  16.0), // Rounded corners
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withAlpha(153), // Shadow color
                                  blurRadius: 56, // Spread of the shadow
                                  offset: const Offset(
                                      0, 0), // Position of the shadow
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16.0),
                              child: CachedNetworkImage(
                                imageUrl: globalAudioState.currentPlaylistCover,
                                width: MediaQuery.of(context).size.width * 0.65,
                                height:
                                    MediaQuery.of(context).size.width * 0.65,
                                fit: BoxFit.contain,
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          child: Text(
                            globalAudioState.currentPlaylistTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 0),
                        MediaControls(
                            playlistId: globalAudioState.currentPlaylistId),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 32,
                    left: 0,
                    child: SizedBox(
                      width: 64, // Set the width of the button
                      height: 64, // Set the height of the button
                      child: IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down),
                        iconSize: 36, // Set the size of the icon
                        onPressed: _toggleExpand, // Collapse the container
                        tooltip: "Uždaryti",
                      ),
                    ),
                  ),
                ],
              )
            : Column(
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
                                Colors.black.withAlpha(76),
                                BlendMode.darken,
                              ),
                              child: Image.network(
                                globalAudioState.currentPlaylistCover,
                                width: 50,
                                height: 50,
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
                                      width: 50,
                                      height: 50,
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
                                    audioProvider.currentPlayingSongName,
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
                              globalAudioState.currentPlaylistTitle.characters
                                      .take(50)
                                      .toString() +
                                  (globalAudioState
                                              .currentPlaylistTitle.length >
                                          50
                                      ? '...'
                                      : ''),
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: MediaControlsSmall(
                          playlistId: globalAudioState.currentPlaylistId,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: StreamBuilder<PositionData>(
                      stream: Provider.of<AudioProvider>(context)
                          .positionDataStream,
                      builder: (context, snapshot) {
                        final positionData = snapshot.data;
                        final duration =
                            positionData?.duration ?? Duration.zero;
                        final position =
                            positionData?.position ?? Duration.zero;
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
    );
  }
}
