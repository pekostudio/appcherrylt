import 'package:appcherrylt/core/providers/ads_provider.dart';
import 'package:appcherrylt/core/providers/audio_provider.dart';
import 'package:appcherrylt/core/providers/scheduler_provider.dart';
import 'package:appcherrylt/core/state/global_audio_state.dart';
import 'package:appcherrylt/core/models/get_tracks.dart';
import 'package:appcherrylt/features/auth/presentation/login.dart';
import 'package:appcherrylt/features/home/presentation/index.dart';
import 'package:flutter/material.dart';
import 'package:appcherrylt/core/models/user_session.dart';
import 'package:appcherrylt/features/home/data/get_playlists.dart';
import 'package:appcherrylt/core/models/favourites.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:appcherrylt/config/theme_notifier.dart';
import 'package:appcherrylt/features/scheduler/data/get_scheduler.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserSession()),
        ChangeNotifierProvider(create: (context) => GetPlaylists()),
        ChangeNotifierProvider(create: (context) => FavoriteManager()),
        ChangeNotifierProvider(create: (context) => GetTracks()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(
            create: (_) => GlobalAudioState(
                'https://cherrymusic.lt/files/cherry-music-muzika-verslui-stylish-shopping.jpeg')),
        ChangeNotifierProvider(create: (context) => AudioProvider(context)),
        ChangeNotifierProxyProvider<AudioProvider, AdsProvider>(
          create: (context) =>
              AdsProvider(Provider.of<AudioProvider>(context, listen: false)),
          update: (context, audioProvider, previous) =>
              previous!..setContext(context),
        ),
        ChangeNotifierProvider(create: (context) => GetSchedule()),
        ChangeNotifierProvider(create: (_) => SchedulerProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, _) {
        return MaterialApp(
          title: 'Cherry Music App',
          routes: {
            'login': (context) => LoginPage(),
            'index': (context) => const IndexPage(),
          },
          theme: themeNotifier.getTheme(),
          navigatorKey: navigatorKey,
          home: Scaffold(
            body: LoginPage(),
          ),
          navigatorObservers: [routeObserver],
        );
      },
    );
  }
}
