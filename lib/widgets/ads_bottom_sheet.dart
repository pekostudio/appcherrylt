import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AdsBottomSheet extends StatelessWidget {
  final AudioPlayer player;

  const AdsBottomSheet({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Ad is playing'),
          StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              return Text('Position: ${position.inSeconds} sec');
            },
          ),
          ElevatedButton(
            onPressed: () {
              player.stop();
              Navigator.pop(context);
            },
            child: const Text('Stop Ad'),
          ),
        ],
      ),
    );
  }
}