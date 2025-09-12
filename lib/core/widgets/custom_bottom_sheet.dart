import 'package:appcherrylt/core/providers/audio_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appcherrylt/core/models/user_session.dart';
import 'package:appcherrylt/core/services/background_audio_handler.dart';
import 'package:appcherrylt/features/auth/presentation/login.dart';
import 'package:appcherrylt/core/state/global_audio_state.dart';
import 'package:appcherrylt/main.dart';
import 'package:logger/logger.dart';
import 'dart:io';

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
  final Logger logger = Logger();

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

  // Non-blocking audio cleanup for iOS
  void _performNonBlockingAudioCleanup() {
    // Run audio cleanup in background without blocking logout
    Future.microtask(() async {
      try {
        final audioProvider =
            Provider.of<AudioProvider>(context, listen: false);

        // Stop playback only - don't reset to avoid interfering with new sessions
        await audioProvider.stop();
        logger.d("✓ iOS: Stopped audio provider (background)");

        // Don't reset or reinitialize - let the new session handle it
        // This prevents interference with playlist population after login
        logger.d(
            "✓ iOS: Audio cleanup completed (background) - no reset to avoid interference");
      } catch (e) {
        logger.e("iOS background audio cleanup error: $e");
      }
    });
  }

  Future<void> _performLogout() async {
    logger.d("Starting comprehensive logout process");

    try {
      // Step 1: Clear persisted credentials immediately
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.setBool('remember_me', false);
      await prefs.remove('active_playlist_id');
      await prefs.remove('active_playlist_name');
      await prefs.remove('has_active_schedule');
      logger.d("✓ Cleared persisted credentials");

      // Step 2: Clear in-memory session token
      if (mounted) {
        try {
          final userSession = Provider.of<UserSession>(context, listen: false);
          userSession.setGlobalToken('');
          userSession.setUserId('');
          userSession.setuserEmail('');
          logger.d("✓ Cleared in-memory session data");
        } catch (e) {
          logger.e("Error clearing session: $e");
        }
      }

      // Step 3: Platform-specific audio cleanup
      if (Platform.isIOS) {
        // iOS: Non-blocking audio cleanup - don't wait for completion
        logger.d("iOS detected - performing non-blocking audio cleanup");
        if (mounted) {
          // Start audio cleanup but don't await it
          _performNonBlockingAudioCleanup();
        }
      } else {
        // Android: Minimal audio cleanup to avoid interfering with new sessions
        if (mounted) {
          try {
            final audioProvider =
                Provider.of<AudioProvider>(context, listen: false);

            // Stop playback only - don't reset to avoid interfering with new sessions
            await audioProvider.stop();
            logger.d("✓ Android: Stopped audio provider");

            // Minimal wait for audio session cleanup
            await Future.delayed(const Duration(milliseconds: 100));

            // Don't reset - let the new session handle it
            // This prevents interference with playlist population after login
            logger.d(
                "✓ Android: Audio cleanup completed - no reset to avoid interference");
          } catch (e) {
            logger.e("Android audio cleanup error: $e");
          }
        }
      }

      // Step 4: Platform-specific background handler cleanup
      if (Platform.isIOS) {
        // iOS: Non-blocking background handler cleanup
        logger.d(
            "iOS detected - performing non-blocking background handler cleanup");
        // Start background handler cleanup but don't await it
        Future.microtask(() async {
          try {
            await BackgroundAudioHandler.stop();
            logger.d("✓ iOS: Stopped background audio handler (background)");
          } catch (e) {
            logger.e("iOS background handler cleanup error: $e");
          }
        });
      } else {
        // Android: Non-blocking background handler cleanup
        logger.d(
            "Android detected - performing non-blocking background handler cleanup");
        // Start background handler cleanup but don't await it
        Future.microtask(() async {
          try {
            await BackgroundAudioHandler.stop();
            logger
                .d("✓ Android: Stopped background audio handler (background)");
          } catch (e) {
            logger.e("Android background handler cleanup error: $e");
          }
        });
      }

      // Step 5: Additional cleanup - reset global audio state
      if (mounted) {
        try {
          final globalAudioState =
              Provider.of<GlobalAudioState>(context, listen: false);
          globalAudioState.updateAudioState(false, "", 0, "", "");
          logger.d("✓ Reset global audio state");

          // iOS: Additional aggressive cleanup
          if (Platform.isIOS) {
            // Force clear any remaining audio state
            globalAudioState.updateAudioState(false, "", 0, "", "");
            logger.d("✓ iOS: Force cleared global audio state");
          }
        } catch (e) {
          logger.e("Error resetting global audio state: $e");
        }
      }

      // Step 6: Platform-specific final wait
      if (Platform.isIOS) {
        // iOS: Minimal wait since cleanup is non-blocking
        await Future.delayed(const Duration(milliseconds: 50));
        logger.d("✓ iOS: Minimal cleanup completed, proceeding to navigation");
      } else {
        // Android: Minimal wait since cleanup is now non-blocking
        await Future.delayed(const Duration(milliseconds: 50));
        logger.d(
            "✓ Android: Minimal cleanup completed, proceeding to navigation");
      }

      // Step 7: Force navigation even if audio system is interfering
      if (mounted) {
        logger.d("Attempting navigation to login...");

        // Immediate navigation attempt without waiting
        try {
          Navigator.pushNamedAndRemoveUntil(context, 'login', (route) => false);
          logger.d("✓ Navigation successful with pushNamedAndRemoveUntil");
          return;
        } catch (e) {
          logger.e("pushNamedAndRemoveUntil failed: $e");
        }

        // Method 1: Force navigation with delayed execution
        try {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, 'login');
            }
          });
          logger.d("✓ Navigation scheduled with delay");
          return;
        } catch (e) {
          logger.e("Delayed navigation failed: $e");
        }

        // Method 2: Try pushReplacementNamed
        try {
          Navigator.pushReplacementNamed(context, 'login');
          logger.d("✓ Navigation successful with pushReplacementNamed");
          return;
        } catch (e) {
          logger.e("pushReplacementNamed failed: $e");
        }

        // Method 3: Try direct navigation
        try {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
          );
          logger.d("✓ Navigation successful with direct MaterialPageRoute");
          return;
        } catch (e) {
          logger.e("Direct navigation failed: $e");
        }

        // Method 4: Force navigation using navigatorKey
        try {
          navigatorKey.currentState
              ?.pushNamedAndRemoveUntil('login', (route) => false);
          logger.d("✓ Navigation successful with navigatorKey");
          return;
        } catch (e) {
          logger.e("NavigatorKey navigation failed: $e");
        }

        // Method 5: Force navigation using WidgetsBinding
        try {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacementNamed(context, 'login');
            }
          });
          logger.d("✓ Navigation scheduled with postFrameCallback");
          return;
        } catch (e) {
          logger.e("PostFrameCallback navigation failed: $e");
        }

        // Method 6: Last resort - restart the app
        logger.e("All navigation methods failed, attempting app restart");
        // This would require additional setup, but let's try a simple approach
        throw Exception("Navigation failed completely");
      }
    } catch (e) {
      logger.e("Critical error during logout: $e");

      // Emergency fallback - try to navigate anyway
      if (mounted) {
        try {
          Navigator.pushReplacementNamed(context, 'login');
        } catch (_) {
          logger.e("Emergency navigation also failed");
        }
      }
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
                'versija 1.5.7',
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
