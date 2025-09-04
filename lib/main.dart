import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:appcherrylt/features/auth/presentation/login.dart';
import 'package:appcherrylt/features/home/presentation/index.dart';
import 'package:appcherrylt/config/theme_notifier.dart';
import 'package:appcherrylt/core/providers/audio_provider.dart';
import 'package:appcherrylt/core/providers/ads_provider.dart';
import 'package:appcherrylt/core/models/user_session.dart';
import 'package:appcherrylt/features/home/data/get_playlists.dart';
import 'package:appcherrylt/core/models/favourites.dart';
import 'package:appcherrylt/core/models/get_tracks.dart';
import 'package:appcherrylt/core/state/global_audio_state.dart';
import 'package:appcherrylt/features/scheduler/data/get_scheduler.dart';
import 'package:appcherrylt/core/providers/scheduler_provider.dart';
import 'package:appcherrylt/core/services/background_service.dart';
import 'package:appcherrylt/core/services/background_audio_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:isolate';
import 'dart:ui';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Top-level callback for background tasks
@pragma('vm:entry-point')
void backgroundTaskCallback() {
  // This function could be needed for registration
  // but we'll use the specific callbacks in BackgroundService
}

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize audio background service
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  // Initialize alarm manager for background tasks
  final bool alarmInitialized = await BackgroundService.initialize();

  // Start periodic check if initialized successfully
  if (alarmInitialized) {
    await BackgroundService.startPeriodicScheduleCheck();
  }

  // Initialize background audio handler
  await BackgroundAudioHandler.initialize();

  // Set up receiver for messages from background isolate
  final ReceivePort port = ReceivePort();
  IsolateNameServer.registerPortWithName(
    port.sendPort,
    'background_scheduler_isolate',
  );

  // Listen for messages from background isolate
  port.listen((message) async {
    if (message is Map<String, dynamic>) {
      if (message['type'] == 'start_playlist' &&
          message['playlist_id'] != null) {
        // Load and play the playlist directly in background
        await BackgroundAudioHandler.loadAndPlayScheduledPlaylist(
            message['playlist_id']);
      }
    }
  });

  // Read saved remember flag and token prior to runApp
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool rememberMe = prefs.getBool('remember_me') ?? false;
  final String storedToken = prefs.getString('access_token') ?? '';
  final bool shouldAutoLogin = rememberMe && storedToken.isNotEmpty;

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
      child: MyApp(
        startOnIndex: shouldAutoLogin,
        initialToken: storedToken,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool startOnIndex;
  final String initialToken;

  const MyApp(
      {super.key, required this.startOnIndex, required this.initialToken});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.startOnIndex && widget.initialToken.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<UserSession>(context, listen: false)
            .setGlobalToken(widget.initialToken);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app is explicitly closed (removed from recents), stop any playback
    if (state == AppLifecycleState.detached) {
      try {
        Provider.of<AudioProvider>(context, listen: false).stop();
      } catch (_) {}
      // Also stop any background handler playback just in case
      BackgroundAudioHandler.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Cherry Music',
          theme: themeNotifier.getTheme(),
          initialRoute: widget.startOnIndex ? 'index' : 'login',
          routes: {
            'login': (context) => LoginPage(),
            'index': (context) => const IndexPage(),
          },
          navigatorKey: navigatorKey,
          navigatorObservers: [routeObserver],
        );
      },
    );
  }
}
