import 'package:appcherrylt/core/providers/audio_provider.dart';
import 'package:flutter/material.dart';
import 'package:appcherrylt/features/auth/presentation/login.dart';
import 'package:provider/provider.dart';

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
            'Confirm Logout',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Cancel',
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
                'Logout',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    // Stop the audio player
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    audioProvider.stop();

    // Check if the widget is still mounted before navigating
    if (mounted) {
      // Navigate to the login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
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
                activeColor: Colors.red,
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
                'version 1.5.1',
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
