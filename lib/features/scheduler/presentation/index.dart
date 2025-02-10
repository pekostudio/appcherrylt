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

    // Initial check
    _checkPlaylistEnd();
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

      if (currentScheduledPlaylist != null &&
          currentScheduledPlaylist.playlist != null) {
        // If there's a scheduled playlist that should be playing now
        if (audioProvider.currentPlaylistId !=
            currentScheduledPlaylist.playlist) {
          // Use existing _navigateToMusicPage method which handles fetching playlist details
          _navigateToMusicPage(currentScheduledPlaylist.playlist!,
              isScheduled: true);
        }
      } else if (audioProvider.isScheduledPlaylist) {
        logger.d('Current playlist no longer scheduled, stopping playback');
        await audioProvider.stop();
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

  void _navigateToMusicPage(int? playlistId,
      {required bool isScheduled}) async {
    if (playlistId == null) return;

    final userSession = Provider.of<UserSession>(context, listen: false);
    final getPlaylists = Provider.of<GetPlaylists>(context, listen: false);
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final favoriteManager =
        Provider.of<FavoriteManager>(context, listen: false);

    try {
      await audioProvider.stop();

      // First try to load playlists if not loaded
      if (getPlaylists.playlists == null || getPlaylists.playlists!.isEmpty) {
        await getPlaylists.fetchTracks(
            userSession.globalToken, favoriteManager);
      }

      final playlistDetails = await getPlaylists.fetchPlaylistDetails(
          playlistId, userSession.globalToken);

      if (!mounted) return;

      if (playlistDetails != null) {
        audioProvider.setPlaylistDetails(
          playlistDetails['id'],
          playlistDetails['title'],
          playlistDetails['cover'],
          isScheduled: true,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MusicPage(
              id: playlistDetails['id'],
              name: playlistDetails['name'],
              title: playlistDetails['title'],
              description: playlistDetails['description'],
              cover: playlistDetails['cover'],
              categoryId: playlistDetails['category_id'],
              categoryName: playlistDetails['category_name'],
              labelNew: playlistDetails['label_new'],
              labelUpdated: playlistDetails['label_updated'],
              playlistId: playlistDetails['id'],
              favorite: true,
              autoplay: true,
            ),
          ),
        );
      } else {
        throw Exception('Failed to fetch playlist details: Playlist not found');
      }
    } catch (e) {
      logger.e('Error fetching playlist details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading playlist: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
