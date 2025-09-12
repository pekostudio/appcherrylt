import 'package:appcherrylt/core/providers/audio_provider.dart';
import 'package:appcherrylt/core/state/global_audio_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class PlaySimpleButton extends StatefulWidget {
  final VoidCallback onPressed; // Callback to open the modal
  final int playlistId; // Single playlist ID
  final String playlistTitle; // Playlist title
  final String playlistCover; // Playlist cover

  const PlaySimpleButton({
    super.key,
    required this.onPressed,
    required this.playlistId,
    required this.playlistTitle,
    required this.playlistCover,
  });

  @override
  State<PlaySimpleButton> createState() => _PlaySimpleButtonState();
}

class _PlaySimpleButtonState extends State<PlaySimpleButton> {
  void togglePlay() {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final globalAudioState =
        Provider.of<GlobalAudioState>(context, listen: false);

    globalAudioState.setCurrentPlaylistId(widget.playlistId);
    logger.d("Set global current playlist ID");

    widget.onPressed();
    audioProvider.play();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: SvgPicture.asset(
        'assets/images/btn-play.svg',
        width: 52.0,
        height: 52.0,
      ),
      onPressed: togglePlay,
    );
  }
}
