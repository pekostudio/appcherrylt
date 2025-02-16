import 'dart:async';
import 'package:appcherrylt/core/providers/ads_provider.dart';
import 'package:appcherrylt/core/data/cache_manager.dart';
import 'package:appcherrylt/core/widgets/audio_player_widget.dart';
import 'package:appcherrylt/features/audio/presentation/music_page.dart';
import 'package:appcherrylt/features/scheduler/data/get_scheduler.dart';
import 'package:appcherrylt/features/scheduler/presentation/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appcherrylt/core/widgets/cherry_top_nav.dart';
import 'package:appcherrylt/core/widgets/favourites_playlists.dart';
import 'package:appcherrylt/core/models/user_session.dart';
import 'package:appcherrylt/features/home/data/get_playlists.dart';
import 'package:appcherrylt/main.dart';
import 'package:appcherrylt/core/models/favourites.dart';
import 'package:appcherrylt/core/providers/audio_provider.dart';
//import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:appcherrylt/core/providers/scheduler_provider.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  IndexPageState createState() => IndexPageState();
}

class IndexPageState extends State<IndexPage> with RouteAware {
  bool shouldLoadPlaylistsAndFavorites = true;
  bool displayPlaylistsAndFavorites = true;
  bool _isLoading = true;
  bool _hasRedirected = false;

  Timer? _periodicTimer;

  final CacheManager cacheManager = CacheManager();
  final Logger logger = Logger();

  @override
  void dispose() {
    _periodicTimer?.cancel();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeIndexPage();
  }

  Future<void> _initializeIndexPage() async {
    if (!mounted) return;

    final userSession = Provider.of<UserSession>(context, listen: false);
    final getPlaylists = Provider.of<GetPlaylists>(context, listen: false);
    final favoriteManager =
        Provider.of<FavoriteManager>(context, listen: false);
    final getSchedule = Provider.of<GetSchedule>(context, listen: false);
    final schedulerProvider =
        Provider.of<SchedulerProvider>(context, listen: false);

    logger.d('Initializing IndexPage');

    try {
      // Set initial loading state
      setState(() {
        _isLoading = true;
        displayPlaylistsAndFavorites = false;
      });

      // Load schedule data first
      await getSchedule.fetchSchedulerData(userSession.globalToken);
      schedulerProvider.setSchedule(getSchedule);

      // Check if we have any schedules for today (active, upcoming, or completed)
      final hasScheduledPlaylistsToday =
          schedulerProvider.hasScheduledPlaylistsToday();
      logger.d('Has scheduled playlists today: $hasScheduledPlaylistsToday');

      // Redirect to scheduler page if there are any schedules for today
      if (hasScheduledPlaylistsToday && !_hasRedirected) {
        _hasRedirected = true;
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SchedulerPage()),
          );
        }
        return;
      }

      // If no schedules, load playlists and show home page
      if (shouldLoadPlaylistsAndFavorites) {
        await getPlaylists.fetchTracks(
            userSession.globalToken, favoriteManager);
      }

      // Start periodic checks only if we're staying on this page
      if (mounted) {
        _startPeriodicTimer();
        setState(() {
          _isLoading = false;
          displayPlaylistsAndFavorites = true;
        });
      }
    } catch (e) {
      logger.e('Error initializing IndexPage: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          displayPlaylistsAndFavorites = true;
        });
      }
    }
  }

  void _startPeriodicTimer() {
    _periodicTimer?.cancel();

    _periodicTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      await _checkSchedule();
    });
  }

  Future<void> _checkSchedule() async {
    if (!mounted) return;

    final userSession = Provider.of<UserSession>(context, listen: false);
    final getSchedule = Provider.of<GetSchedule>(context, listen: false);
    final schedulerProvider =
        Provider.of<SchedulerProvider>(context, listen: false);

    try {
      await getSchedule.fetchSchedulerData(userSession.globalToken);
      schedulerProvider.setSchedule(getSchedule);

      // Handle ads
      final currentAd = schedulerProvider.getCurrentAd();
      if (currentAd?.tracks?.isNotEmpty == true) {
        final adsProvider = Provider.of<AdsProvider>(context, listen: false);
        adsProvider.setContext(context);
        try {
          adsProvider.createAdsSource(currentAd!.tracks!.first.toString());
        } catch (e) {
          logger.e('Error creating ad source: $e');
        }
      }

      // Check for any schedules today (active, upcoming, or completed)
      final hasSchedules = schedulerProvider.hasScheduledPlaylistsToday();
      if (hasSchedules && !_hasRedirected) {
        _hasRedirected = true;
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SchedulerPage()),
          );
        }
      }
    } catch (e) {
      logger.e('Error checking schedule: $e');
    }
  }

  Future<void> ensurePlaylistsLoaded(String accessToken) async {
    final getPlaylists = Provider.of<GetPlaylists>(context, listen: false);
    if (getPlaylists.playlists == null || getPlaylists.playlists!.isEmpty) {
      final favoriteManager =
          Provider.of<FavoriteManager>(context, listen: false);
      await getPlaylists.fetchTracks(accessToken, favoriteManager);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }

    // Add this to ensure audio state is preserved
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    if (audioProvider.isPlaying || audioProvider.isPaused) {
      setState(() {}); // Trigger rebuild to show AudioPlayerWidget
    }
  }

  @override
  void didPopNext() {
    final userSession = Provider.of<UserSession>(context, listen: false);
    final getPlaylists = Provider.of<GetPlaylists>(context, listen: false);
    final favoriteManager =
        Provider.of<FavoriteManager>(context, listen: false);

    // Reset hasRedirected flag when returning to index page
    setState(() {
      _hasRedirected = false;
    });

    if (shouldLoadPlaylistsAndFavorites) {
      getPlaylists.fetchTracks(userSession.globalToken, favoriteManager);
    }
  }

  Widget buildCategoryPlaylists(int categoryId, GetPlaylists getPlaylists) {
    var categoryPlaylists = getPlaylists.getPlaylistsByCategoryId(categoryId);
    String categoryName =
        getPlaylists.categoryNames[categoryId] ?? 'Unknown Category';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 32, 0, 8),
          child: Text(
            categoryName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        SizedBox(
          height: 160,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 1,
              ),
              itemCount: categoryPlaylists.length,
              itemBuilder: (context, index) {
                var playlist = categoryPlaylists[index];

                return GestureDetector(
                  onTap: () => _navigateMusicPage(playlist),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Stack(
                        children: [
                          ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              Color.fromRGBO(0, 0, 0, 0.5),
                              BlendMode.darken,
                            ),
                            child: CachedNetworkImage(
                              imageUrl: playlist['cover'],
                              fit: BoxFit.cover,
                              progressIndicatorBuilder:
                                  (context, url, downloadProgress) => Center(
                                child: CircularProgressIndicator(
                                  value: downloadProgress.progress,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.red),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                playlist['title'],
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _navigateMusicPage(dynamic playlist) async {
    if (!mounted) return;

    logger.d('Navigating to inner page with playlist: ${playlist.toString()}');
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    audioProvider.setPlaylistDetails(playlist['id'] ?? 0,
        playlist['title'] ?? 'Unknown Playlist', playlist['cover'] ?? '',
        isScheduled: false);

    final isFavorite = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicPage(
          id: playlist['id'],
          name: playlist['name'],
          title: playlist['title'],
          description: playlist['description'],
          cover: playlist['cover'],
          categoryId: playlist['category_id'],
          categoryName: playlist['category_name'],
          labelNew: playlist['label_new'],
          labelUpdated: playlist['label_updated'],
          playlistId: playlist['id'],
          favorite: true,
        ),
      ),
    );

    if (isFavorite != null && mounted) {
      setFavorite(playlist['id'], isFavorite);
    }
  }

  void setFavorite(int playlistId, bool isFavorite) {
    final favoriteManager =
        Provider.of<FavoriteManager>(context, listen: false);
    favoriteManager.setFavorite(playlistId, isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final audioProvider = Provider.of<AudioProvider>(context);
    final getPlaylists = Provider.of<GetPlaylists>(context);

    bool isPlaying = audioProvider.isPlaying;
    bool isPaused = audioProvider.isPaused;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.of(context).size.height * 0.06,
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        flexibleSpace: SafeArea(
          child: const CherryTopNavigation(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (displayPlaylistsAndFavorites) ...[
              FavoritePlaylists(getPlaylists: getPlaylists),
              ...?getPlaylists.playlistsCategoryId?.map(
                (categoryId) =>
                    buildCategoryPlaylists(categoryId, getPlaylists),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar:
          (isPlaying || isPaused) ? const AudioPlayerWidget() : null,
    );
  }
}
