import 'package:appcherrylt/config/theme.dart';
import 'package:appcherrylt/config/theme_notifier.dart';
import 'package:appcherrylt/core/widgets/custom_bottom_sheet.dart';
import 'package:appcherrylt/features/offline/presentation/offline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:appcherrylt/features/home/presentation/index.dart';
import 'package:appcherrylt/core/providers/audio_provider.dart';
import 'package:appcherrylt/core/providers/audio_provider_offline.dart';
//import 'package:appcherrylt/core/providers/connectivity_provider.dart';

class CherryTopNavigation extends StatefulWidget {
  final bool? isOffline;

  const CherryTopNavigation({
    super.key,
    this.isOffline,
  });

  @override
  CherryTopNavigationState createState() => CherryTopNavigationState();
}

class CherryTopNavigationState extends State<CherryTopNavigation> {
  bool _darkModeSwitch = false; // For theme switching
  bool _isOfflineMode = false; // For online/offline switching

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isOfflineMode = widget.isOffline ??
            ModalRoute.of(context)?.settings.name == '/offline';
        // Get initial theme state
        _darkModeSwitch = Theme.of(context).brightness == Brightness.dark;
      });
    });
  }

  void _onDarkModeChanged(bool value) {
    setState(() {
      _darkModeSwitch = value;
      if (value) {
        Provider.of<ThemeNotifier>(context, listen: false)
            .setTheme(cherryDarkTheme);
      } else {
        Provider.of<ThemeNotifier>(context, listen: false)
            .setTheme(cherryLightTheme);
      }
    });
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.0),
        ),
      ),
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (BuildContext context) {
        return SafeArea(
          child: CustomBottomSheet(
            text1: 'Dark mode',
            text2: 'Log out',
            initialSwitchValue: _darkModeSwitch, // Pass dark mode state
            onSwitchChanged: _onDarkModeChanged, // Pass dark mode handler
            icon2: Icons.logout,
            height: MediaQuery.of(context).size.height * 0.3,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: screenHeight * 0.06,
              minHeight: screenHeight * 0.06,
            ),
            icon: Icon(
              Icons.more_horiz,
              size: screenHeight * 0.05,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: _showBottomSheet,
          ),
          SvgPicture.asset(
            'assets/images/cherrymusic-logo-white.svg',
            width: screenHeight * 0.20,
          ),
          SizedBox(
            width: screenHeight * 0.06,
            height: screenHeight * 0.04,
            child: Stack(
              children: [
                Switch(
                  value: _isOfflineMode,
                  onChanged: (bool value) async {
                    setState(() {
                      _isOfflineMode = value;
                    });
                    if (value) {
                      // Only stop online audio player before navigating to offline
                      final audioProvider =
                          Provider.of<AudioProvider>(context, listen: false);
                      await audioProvider.stop();

                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OfflinePlaylistsPage(),
                            settings: const RouteSettings(name: '/offline'),
                          ),
                        );
                      }
                    } else {
                      // Only stop offline audio player before navigating to online
                      final audioProviderOffline =
                          Provider.of<AudioProviderOffline>(context,
                              listen: false);
                      await audioProviderOffline.stop();

                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const IndexPage(),
                            settings: const RouteSettings(name: '/'),
                          ),
                        );
                      }
                    }
                  },
                  activeColor: Colors.red,
                  inactiveThumbColor: Colors.green,
                ),
                Positioned(
                  left: _isOfflineMode ? 7 : 27,
                  top: 10,
                  child: Text(
                    _isOfflineMode ? 'Off' : 'On',
                    style: TextStyle(
                      fontSize: 10,
                      color: _isOfflineMode
                          ? Colors.white
                          : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
