import 'package:appcherrylt/core/providers/audio_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appcherrylt/core/models/user_session.dart';
import 'package:appcherrylt/core/services/background_audio_handler.dart';

class CustomBottomSheet extends StatefulWidget {
  final String text1;
  final String text2;
  final bool initialSwitchValue;
  final ValueChanged<bool> onSwitchChanged;
  final IconData icon2;
  final double height;

  const CustomBottomSheet({
    super.key,
    required this.text1,
    required this.text2,
    required this.initialSwitchValue,
    required this.onSwitchChanged,
    required this.icon2,
    this.height = 240.0,
  });

  @override
  CustomBottomSheetState createState() => CustomBottomSheetState();
}

class CustomBottomSheetState extends State<CustomBottomSheet> {
  late bool _switchValue;

  @override
  void initState() {
    super.initState();
    _switchValue = widget.initialSwitchValue;
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Atsijungti',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Text(
            'Ar tikrai norite atsijungti?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Nutraukti',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                // Perform logout action here
                await _performLogout();
              },
              child: Text(
                'Atsijungti',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    // Stop any audio playback
    try {
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      await audioProvider.stop();
      await audioProvider.reset(); // fully release audio pipeline
    } catch (_) {}

    // Stop background handler playback as well
    try {
      await BackgroundAudioHandler.stop();
    } catch (_) {}

    // Clear in-memory session token
    try {
      Provider.of<UserSession>(context, listen: false).setGlobalToken('');
    } catch (_) {}

    // Clear persisted credentials and remember flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.setBool('remember_me', false);

    // Optional: clear any active schedule flags
    await prefs.remove('active_playlist_id');
    await prefs.remove('active_playlist_name');
    await prefs.remove('has_active_schedule');

    // Navigate to login and clear back stack
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, 'login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: widget.height,
      padding: const EdgeInsets.all(32.0),
      color: Theme.of(context).canvasColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.text1,
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
              Switch(
                value: _switchValue,
                activeThumbColor: Colors.red,
                onChanged: (value) {
                  setState(() {
                    _switchValue = value;
                    widget.onSwitchChanged(value);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.text2,
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
              IconButton(
                icon: Icon(
                  widget.icon2,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: () {
                  _handleLogout(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'versija 1.5.6',
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
