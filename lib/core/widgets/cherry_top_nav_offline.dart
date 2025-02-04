import 'package:appcherrylt/config/theme.dart';
import 'package:appcherrylt/config/theme_notifier.dart';
import 'package:appcherrylt/core/widgets/custom_bottom_sheet.dart';
import 'package:appcherrylt/features/home/presentation/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class CherryTopNavigationOffline extends StatefulWidget {
  const CherryTopNavigationOffline({super.key});

  @override
  CherryTopNavigationOfflineState createState() =>
      CherryTopNavigationOfflineState();
}

class CherryTopNavigationOfflineState
    extends State<CherryTopNavigationOffline> {
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

  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 160.0, // Ensure it includes space for both Rows
      child: DecoratedBox(
        decoration:
            BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
        child: Column(
          children: [
            SizedBox(
              height: 50.0, // Height for the additional Row
              child: Row(),
            ),
            Expanded(
              // Allows the existing Row to take remaining space
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    icon: Icon(
                      Icons.more_horiz,
                      size: 36.0,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20.0),
                          ),
                        ),
                        elevation: 0,
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        builder: (BuildContext context) {
                          return CustomBottomSheet(
                            text1: 'Dark mode',
                            text2: 'Log out',
                            initialSwitchValue: _switchValue,
                            onSwitchChanged: _onSwitchChanged,
                            icon2: Icons.logout,
                            height: 260.0,
                          );
                        },
                      );
                    },
                  ),
                  SvgPicture.asset(
                    'assets/images/cherrymusic-logo-white.svg',
                    width: 160.0,
                  ),
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/images/icon-online.svg',
                      width: 46.0,
                      height: 20.0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const IndexPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
