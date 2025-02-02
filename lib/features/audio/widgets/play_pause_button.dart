import 'package:appcherrylt/core/providers/audio_provider.dart';
import 'package:appcherrylt/core/state/global_audio_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class PlayPauseButton extends StatefulWidget {
  final VoidCallback onPressed; // Callback to open the modal
  final int playlistId; // Single playlist ID
  final String playlistTitle; // Playlist title
  final String playlistCover; // Playlist cover

  const PlayPauseButton({
    super.key,
    required this.onPressed,
    required this.playlistId,
    required this.playlistTitle,
    required this.playlistCover,
  });

  @override
  State<PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButton> {
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update local state when dependencies change
    final audioProvider = Provider.of<AudioProvider>(context);
    setState(() {
      isPlaying = audioProvider.isPlaying;
    });
  }

  void togglePlayPause() {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final globalAudioState =
        Provider.of<GlobalAudioState>(context, listen: false);

    if (!isPlaying) {
      // Check if we're switching to a different playlist
      if (globalAudioState.currentPlaylistId != widget.playlistId) {
        // Reset audio if switching to a different playlist
        audioProvider.stop(); // Assuming you have a stop method
        audioProvider.setPlaylistDetails(
          widget.playlistId,
          widget.playlistTitle,
          widget.playlistCover,
        );
      }

      setState(() {
        isPlaying = true;
      });

      // Update GlobalAudioState
      globalAudioState.updateAudioState(
        true,
        "Current Song Name", // Replace with actual song name if available
        widget.playlistId,
        widget.playlistTitle,
        widget.playlistCover,
      );

      widget.onPressed();
      audioProvider.play();
    } else {
      setState(() {
        isPlaying = false;
      });

      // Update GlobalAudioState
      globalAudioState.updateAudioState(
        false,
        "Current Song Name", // Replace with actual song name if available
        widget.playlistId, // Keep the playlist ID even when paused
        widget.playlistTitle,
        widget.playlistCover,
      );

      audioProvider.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GlobalAudioState>(
      builder: (context, globalAudioState, _) {
        return IconButton(
          icon: globalAudioState.isPlaying
              ? SvgPicture.asset(
                  'assets/images/btn-pause.svg',
                  width: 52.0,
                  height: 52.0,
                )
              : SvgPicture.asset(
                  'assets/images/btn-play.svg',
                  width: 52.0,
                  height: 52.0,
                ),
          onPressed: togglePlayPause,
        );
      },
    );
  }
}
