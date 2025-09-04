import 'package:appcherrylt/core/models/user_session.dart';
import 'package:appcherrylt/core/providers/audio_provider.dart';
import 'package:appcherrylt/core/providers/scheduler_provider.dart';
import 'package:appcherrylt/core/models/favourites.dart';
import 'package:appcherrylt/features/audio/presentation/music_page.dart';
import 'package:appcherrylt/features/home/data/get_playlists.dart';
import 'package:appcherrylt/features/home/presentation/index.dart';
import 'package:appcherrylt/features/scheduler/data/get_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appcherrylt/core/services/background_service.dart';

class SchedulerPage extends StatefulWidget {
  const SchedulerPage({super.key});

  @override
  SchedulerPageState createState() => SchedulerPageState();
}

class SchedulerPageState extends State<SchedulerPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Logger logger = Logger();
  Timer? _refreshTimer;
  bool _hasRedirected = false;
  StreamSubscription? _bgSharedPrefsCheckSubscription;

  @override
  void initState() {
    super.initState();

    // Stop any playing audio when scheduler page is opened
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    if (audioProvider.isPlaying) {
      audioProvider.stop();
    }

    // Start periodic check for playlist end
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      await _refreshScheduleData();
      _checkPlaylistEnd();
    });

    // Also set up a timer to check shared preferences for background scheduler updates
    _bgSharedPrefsCheckSubscription =
        Stream.periodic(const Duration(seconds: 10))
            .listen((_) => _checkBackgroundSchedulerAlerts());

    // Initial checks
    _checkPlaylistEnd();
    _checkBackgroundSchedulerAlerts();

    // Ensure background schedule checker is running
    BackgroundService.startPeriodicScheduleCheck();
  }

  Future<void> _checkBackgroundSchedulerAlerts() async {
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasActiveSchedule = prefs.getBool('has_active_schedule') ?? false;

      if (hasActiveSchedule) {
        final playlistId = prefs.getInt('active_playlist_id');
        final playlistName = prefs.getString('active_playlist_name');

        if (playlistId != null) {
          logger.d(
              'Background service found active playlist: $playlistId - $playlistName');

          final audioProvider =
              Provider.of<AudioProvider>(context, listen: false);

          // If we're not already playing this playlist, start it
          if (!audioProvider.isPlaying ||
              audioProvider.currentPlaylistId != playlistId) {
            // Navigate to the music page to play the scheduled playlist
            _navigateToMusicPage(playlistId, isScheduled: true);
          }
        }
      }
    } catch (e) {
      logger.e('Error checking background scheduler alerts: $e');
    }
  }

  void _checkPlaylistEnd() {
    if (!mounted) return;

    final schedulerProvider =
        Provider.of<SchedulerProvider>(context, listen: false);
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    try {
      // Check if current playlist should stop
      if (schedulerProvider.shouldStopCurrentPlaylist()) {
        logger.d('Stopping scheduled playlist as it has ended');

        // Stop the audio
        audioProvider.stop();

        // Reset navigation flag if needed
        _hasRedirected = false;

        // Show message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scheduled playlist has ended'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      logger.e('Error checking playlist end: $e');
    }
  }

  Future<void> _refreshScheduleData() async {
    if (!mounted) return;

    try {
      final getSchedule = Provider.of<GetSchedule>(context, listen: false);
      final schedulerProvider =
          Provider.of<SchedulerProvider>(context, listen: false);
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);

      await getSchedule.fetchSchedulerData(
          Provider.of<UserSession>(context, listen: false).globalToken);
      schedulerProvider.setSchedule(getSchedule);

      // Get current scheduled playlist
      final currentScheduledPlaylist =
          schedulerProvider.getCurrentScheduledPlaylist();

      // If there's a currently scheduled playlist
      if (currentScheduledPlaylist != null &&
          currentScheduledPlaylist.playlist != null) {
        // Check if we need to switch to this playlist
        if (!audioProvider.isPlaying ||
            audioProvider.currentPlaylistId !=
                currentScheduledPlaylist.playlist) {
          logger.d(
              'Switching to scheduled playlist: ${currentScheduledPlaylist.playlist}');
          // Stop current playback if any
          if (audioProvider.isPlaying) {
            await audioProvider.stop();
          }
          // Navigate to new playlist
          _navigateToMusicPage(currentScheduledPlaylist.playlist!,
              isScheduled: true);
        }
      } else if (audioProvider.isScheduledPlaylist) {
        // No scheduled playlist should be playing now
        logger.d('Current playlist no longer scheduled, stopping playback');
        await audioProvider.stop();
        if (mounted) {
          setState(
              () {}); // Just refresh the current page instead of replacing it
        }
      }
    } catch (e) {
      logger.e('Error refreshing schedule data: $e');
    }
  }

  @override
  void didUpdateWidget(SchedulerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final schedulerProvider =
        Provider.of<SchedulerProvider>(context, listen: false);
    final getSchedule = Provider.of<GetSchedule>(context, listen: false);
    schedulerProvider.setSchedule(getSchedule);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _bgSharedPrefsCheckSubscription?.cancel();
    _audioPlayer.dispose();

    // Remove Provider access from dispose
    // The navigation state will be handled by the navigation itself
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schedulerProvider = Provider.of<SchedulerProvider>(context);
    final getSchedule = Provider.of<GetSchedule>(context);

// Check if there are any scheduled playlists for today
    final hasSchedules = schedulerProvider.hasScheduledPlaylistsToday();
    if (!hasSchedules && !_hasRedirected) {
      _hasRedirected =
          true; // Set the flag to true to prevent further redirects
      logger.d('No schedules found for today, redirecting to IndexPage');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const IndexPage()),
        );
      });
      return const SizedBox.shrink();
    }

    final todaySchedule = schedulerProvider.todaySchedule;
    final currentPlayingSchedule =
        schedulerProvider.getCurrentPlayingSchedule();

    if (currentPlayingSchedule != null &&
        currentPlayingSchedule.playlist != null &&
        !schedulerProvider.isNavigatingToScheduledPlaylist) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        schedulerProvider.setNavigatingToScheduledPlaylist(true);
        _navigateToMusicPage(currentPlayingSchedule.playlist!,
            isScheduled: true);
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Scheduled playlists'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Schedule',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...todaySchedule.map((schedule) {
              final status = schedulerProvider.getScheduleStatus(schedule);
              return Card(
                color: Colors.white,
                child: ListTile(
                  title: Text(
                      'Playlist: ${schedule.playlistName ?? schedule.playlist}'),
                  subtitle: Text('Time: ${schedule.start} - ${schedule.end}'),
                  trailing: _getStatusChip(status),
                ),
              );
            }),
            const SizedBox(height: 24),
            const Text(
              'Upcoming Schedule',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: getSchedule.list?.length ?? 0,
                itemBuilder: (context, index) {
                  final schedule = getSchedule.list![index];
                  if (schedule.day == DateTime.now().weekday) {
                    return const SizedBox.shrink();
                  }

                  return Card(
                    child: ListTile(
                      title: Text('Playlist: ${schedule.playlistName}'),
                      subtitle: Text(
                          '${schedulerProvider.getDayName(schedule.day!)}: ${schedule.start} - ${schedule.end}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getStatusChip(ScheduleStatus status) {
    switch (status) {
      case ScheduleStatus.upcoming:
        return const Chip(
          label: Text('Upcoming'),
          backgroundColor: Colors.white,
          labelStyle: TextStyle(color: Colors.black),
        );
      case ScheduleStatus.completed:
        return const Chip(
          label: Text('Completed'),
          backgroundColor: Colors.grey,
          labelStyle: TextStyle(color: Colors.white),
        );
      case ScheduleStatus.playing:
        return const Chip(
          label: Text('Playing'),
          backgroundColor: Colors.green,
          labelStyle: TextStyle(color: Colors.white),
        );
    }
  }

  void _navigateToMusicPage(int playlistId, {required bool isScheduled}) async {
    if (!mounted) return;

    final userSession = Provider.of<UserSession>(context, listen: false);
    final getPlaylists = Provider.of<GetPlaylists>(context, listen: false);
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final schedulerProvider =
        Provider.of<SchedulerProvider>(context, listen: false);
    final favoriteManager =
        Provider.of<FavoriteManager>(context, listen: false);

    // If we need to fetch playlists
    if (getPlaylists.playlists == null || getPlaylists.playlists!.isEmpty) {
      await getPlaylists.fetchTracks(userSession.globalToken, favoriteManager);
    }

    // Find the playlist from the list
    var foundPlaylist = getPlaylists.playlists?.firstWhere(
      (p) => p["id"] == playlistId,
      orElse: () => null,
    );

    // If playlist not found, try to get it from API directly
    if (foundPlaylist == null) {
      try {
        // You'll need to implement a method to fetch a single playlist if not already available
        await getPlaylists.fetchTracks(
            userSession.globalToken, favoriteManager);
        foundPlaylist = getPlaylists.playlists?.firstWhere(
          (p) => p["id"] == playlistId,
          orElse: () => null,
        );
      } catch (e) {
        logger.e('Error fetching playlist: $e');
      }
    }

    if (foundPlaylist == null) {
      logger.e('Could not find playlist with ID: $playlistId');
      return;
    }

    // Set this flag so we know we're navigating
    schedulerProvider.setNavigatingToScheduledPlaylist(true);

    audioProvider.setPlaylistDetails(
      playlistId,
      foundPlaylist['title'] ?? 'Unknown Playlist',
      foundPlaylist['cover'] ?? '',
      isScheduled: isScheduled,
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MusicPage(
          id: playlistId,
          name: foundPlaylist['name'] ?? '',
          title: foundPlaylist['title'] ?? 'Unknown Playlist',
          description: foundPlaylist['description'] ?? '',
          cover: foundPlaylist['cover'] ?? '',
          categoryId: foundPlaylist['category_id'] ?? 0,
          categoryName: foundPlaylist['category_name'] ?? '',
          labelNew: foundPlaylist['label_new'] ?? '',
          labelUpdated: foundPlaylist['label_updated'] ?? '',
          playlistId: playlistId,
          favorite: favoriteManager.isFavorite(playlistId),
          autoplay: true,
        ),
      ),
    );
  }
}
