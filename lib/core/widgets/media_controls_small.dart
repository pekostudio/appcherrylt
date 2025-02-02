import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:appcherrylt/core/providers/audio_provider.dart';

class MediaControlsSmall extends StatelessWidget {
  const MediaControlsSmall({super.key, required int playlistId});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: audioProvider.isPlaying
              ? SvgPicture.asset('assets/images/btn-pause.svg',
                  width: 36.0, height: 36.0)
              : SvgPicture.asset('assets/images/btn-play.svg',
                  width: 36.0, height: 36.0),
          onPressed: () => audioProvider.togglePlayPause(context),
        ),
      ],
    );
  }
}
