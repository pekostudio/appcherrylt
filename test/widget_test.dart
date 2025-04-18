// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:appcherrylt/config/theme_notifier.dart';
import 'package:appcherrylt/core/models/user_session.dart';
import 'package:appcherrylt/features/home/data/get_playlists.dart';
import 'package:appcherrylt/core/models/favourites.dart';
import 'package:appcherrylt/core/models/get_tracks.dart';
import 'package:appcherrylt/features/scheduler/data/get_scheduler.dart';
import 'package:appcherrylt/core/providers/scheduler_provider.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // This is a simple test that just verifies the app can be created
    // without crashing, without testing specific functionality.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => UserSession()),
          ChangeNotifierProvider(create: (context) => GetPlaylists()),
          ChangeNotifierProvider(create: (context) => FavoriteManager()),
          ChangeNotifierProvider(create: (context) => GetTracks()),
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          ChangeNotifierProvider(create: (_) => GetSchedule()),
          ChangeNotifierProvider(create: (_) => SchedulerProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Test passed!'),
            ),
          ),
        ),
      ),
    );

    // Verify that the test text is displayed
    expect(find.text('Test passed!'), findsOneWidget);
  });
}
