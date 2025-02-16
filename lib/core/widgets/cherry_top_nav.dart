import 'package:appcherrylt/config/theme.dart';
import 'package:appcherrylt/config/theme_notifier.dart';
//import 'package:appcherrylt/features/offline/presentation/offline.dart';
import 'package:appcherrylt/core/widgets/custom_bottom_sheet.dart';
import 'package:appcherrylt/features/offline/presentation/offline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class CherryTopNavigation extends StatefulWidget {
  const CherryTopNavigation({super.key});

  @override
  CherryTopNavigationState createState() => CherryTopNavigationState();
}

class CherryTopNavigationState extends State<CherryTopNavigation> {
  bool _switchValue = false;

  void _onSwitchChanged(bool value) {
    setState(() {
      _switchValue = value;
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
            initialSwitchValue: _switchValue,
            onSwitchChanged: _onSwitchChanged,
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
          IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: screenHeight * 0.05,
              minHeight: screenHeight * 0.05,
            ),
            icon: SvgPicture.asset(
              'assets/images/icon-offline.svg',
              width: screenHeight * 0.04,
              height: screenHeight * 0.02,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OfflinePlaylistsPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
