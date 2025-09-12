import 'dart:async';
import 'package:appcherrylt/core/models/favourites.dart';
import 'package:appcherrylt/core/models/user_session.dart';
import 'package:appcherrylt/core/providers/audio_provider.dart';
import 'package:appcherrylt/core/providers/scheduler_provider.dart';
import 'package:appcherrylt/core/widgets/audio_player_widget.dart';
import 'package:appcherrylt/core/widgets/favourite_toggle_icon.dart';
import 'package:appcherrylt/features/home/presentation/index.dart';
import 'package:appcherrylt/features/scheduler/data/get_scheduler.dart';
import 'package:appcherrylt/features/scheduler/presentation/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:appcherrylt/features/audio/presentation/music_page_helpers.dart';

class MusicPage extends StatefulWidget {
  final int id;
  final String name;
  final String title;
  final String description;
  final String cover;
  final int categoryId;
  final String categoryName;
  final String labelNew;
  final String labelUpdated;
  final int playlistId;
  final bool favorite;
  final bool autoplay;

  const MusicPage({
    super.key,
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.cover,
    required this.categoryId,
    required this.categoryName,
    required this.labelNew,
    required this.labelUpdated,
    required this.playlistId,
    required this.favorite,
    this.autoplay = false,
  });

  @override
  MusicPageState createState() => MusicPageState();
}

class MusicPageState extends State<MusicPage> {
  final Logger logger = Logger();
  bool _isLoading = false;
  late bool isFavorite;
  Timer? _schedulerCheckTimer;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.favorite;

    if (widget.autoplay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeAndPlay();
        // Start periodic scheduler check
        _startSchedulerCheck();
      });
    }
  }

  @override
  void dispose() {
    _schedulerCheckTimer?.cancel();
    super.dispose();
  }

  void _startSchedulerCheck() {
    // Check more frequently - every 30 seconds
    _schedulerCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkSchedulerStatus();
    });
    // Do initial check
    _checkSchedulerStatus();
  }

  Future<void> _checkSchedulerStatus() async {
    if (!mounted) return;

    // Store context before async operation
    final context = this.context;

    final getSchedule = Provider.of<GetSchedule>(context, listen: false);
    final schedulerProvider =
        Provider.of<SchedulerProvider>(context, listen: false);
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final userToken =
        Provider.of<UserSession>(context, listen: false).globalToken;

    // Force refresh schedule data
    await getSchedule.fetchSchedulerData(userToken);

    // Check if widget is still mounted before continuing
    if (!mounted) return;

    schedulerProvider.setSchedule(getSchedule);

    final currentTime = DateTime.now();

    // Check if this is the currently playing playlist
    if (audioProvider.currentPlaylistId == widget.playlistId) {
      bool isStillValid = false;

      // Check if the playlist is still scheduled for current time
      if (getSchedule.list != null) {
        for (var schedule in getSchedule.list!) {
          if (schedule.playlist == widget.playlistId &&
              schedulerProvider.isTimeInSchedule(schedule, currentTime)) {
            isStillValid = true;
            break;
          }
        }
      }

      // If playlist was scheduled but is no longer valid, redirect to scheduler
      if (!isStillValid && audioProvider.isScheduledPlaylist) {
        logger.d(
            'Scheduled playlist no longer active or time slot ended, returning to scheduler');
        await audioProvider.stop();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SchedulerPage()),
          );
        }
      }
    }
  }

  Future<void> _initializeAndPlay() async {
    if (!mounted) return;

    // Store context and providers before async operations
    final context = this.context;
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final schedulerProvider =
        Provider.of<SchedulerProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      bool wasPlaying = audioProvider.isPlaying;
      bool wasPaused = audioProvider.isPaused;

      if (wasPlaying || wasPaused) {
        await audioProvider.stop();
      }

      await Future.delayed(const Duration(milliseconds: 100));

      await populatePlaylist(context, widget, logger);

      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        if (wasPlaying || wasPaused) {
          setState(() {});
        }

        // Set isScheduledPlaylist based on current schedule
        final isScheduled = schedulerProvider.getCurrentScheduledPlaylistId() ==
            widget.playlistId;

        audioProvider.playAudio(
          context: context,
          songName: audioProvider.currentPlayingSongName,
          playlistId: widget.playlistId,
          playlistTitle: widget.title,
          playlistCover: widget.cover,
          isScheduledPlaylist: isScheduled, // Add this parameter
        );
      }
    } catch (e) {
      logger.e('Error initializing playlist: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading playlist: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Favourites ADD/REMOVE
  void toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });
    Provider.of<FavoriteManager>(context, listen: false)
        .setFavorite(widget.id, isFavorite);
    logger.d('Toggled favorite status for playlist ${widget.id}: $isFavorite');
  }

  // Display back button if there is NO scheduled playlists
  bool _shouldShowBackButton() {
    logger.d('Checking back button visibility:');
    final schedulerProvider =
        Provider.of<SchedulerProvider>(context, listen: false);
    final isScheduledPlaylist =
        schedulerProvider.getCurrentScheduledPlaylistId() == widget.playlistId;
    logger.d('isScheduledPlaylist: $isScheduledPlaylist');
    final shouldShow = !isScheduledPlaylist;
    logger.d('Should show back button: $shouldShow');
    return shouldShow;
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 70, 16, 16),
              child: Row(
                children: [
                  if (_shouldShowBackButton())
                    CircleAvatar(
                      backgroundColor: const Color.fromARGB(255, 242, 242, 242),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () {
                          // Check if we can pop
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const IndexPage(),
                              ),
                            );
                            // Navigate directly to IndexPage
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.65,
                height: MediaQuery.of(context).size.width * 0.65,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(153),
                      blurRadius: 56,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: CachedNetworkImage(
                    imageUrl: widget.cover,
                    width: MediaQuery.of(context).size.width * 0.65,
                    height: MediaQuery.of(context).size.width * 0.65,
                    fit: BoxFit.contain,
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 64, // Set the fixed height
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left-aligned Favorite Icon
                    CircleAvatar(
                      backgroundColor: const Color.fromARGB(255, 242, 242, 242),
                      child: FavoriteToggleIcon(
                        playlistId: widget.id,
                        isFavorite: isFavorite,
                        onToggle: (bool newFavoriteStatus) {
                          setState(() {
                            isFavorite = newFavoriteStatus;
                          });
                        },
                      ),
                    ),
                    // Right-aligned Play Button
                    IconButton(
                      icon: _isLoading
                          ? CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.secondary),
                            )
                          : SvgPicture.asset(
                              'assets/images/btn-play.svg',
                              width: 46.0,
                              height: 46.0,
                            ),
                      onPressed: () async {
                        setState(() {
                          _isLoading = true; // Start loading
                        });

                        await populatePlaylist(context, widget, logger);

                        if (!mounted) return;

                        setState(() {
                          _isLoading = false; // End loading
                        });

                        if (mounted) {
                          audioProvider.playAudio(
                            context: context,
                            songName: audioProvider.currentPlayingSongName,
                            playlistId: widget.playlistId,
                            playlistTitle: widget.title,
                            playlistCover: widget.cover,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: (audioProvider.isPlaying || audioProvider.isPaused)
          ? const AudioPlayerWidget()
          : null,
    );
  }
}
