import 'package:appcherrylt/core/providers/audio_provider_offline.dart';
import 'package:appcherrylt/core/state/global_audio_state.dart';
import 'package:appcherrylt/core/widgets/cherry_top_nav.dart';
import 'package:appcherrylt/core/widgets/media_controls_offline.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appcherrylt/features/offline/data/offline_playlist_data.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:logger/logger.dart';

class OfflinePlaylistsPage extends StatefulWidget {
  const OfflinePlaylistsPage({super.key});

  @override
  State<OfflinePlaylistsPage> createState() => OfflinePlaylistsPageState();
}

class OfflinePlaylistsPageState extends State<OfflinePlaylistsPage> {
  List<int> offlinePlaylistIds = [];
  List<Map<String, dynamic>> offlinePlaylists = [];

  @override
  void initState() {
    super.initState();
    _initOfflinePlaylists();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadOfflinePlaylists();
  }

  Future<void> _initOfflinePlaylists() async {
    await OfflinePlaylistData.cleanupOrphanedFiles();
    await _loadOfflinePlaylists();
  }

  Future<void> _loadOfflinePlaylists() async {
    try {
      final offlineIds = await OfflinePlaylistData.getOfflinePlaylists();

      // Verify and cleanup invalid cover paths
      for (var id in offlineIds) {
        await OfflinePlaylistData.verifyAndCleanupCoverPath(id);
      }

      List<Map<String, dynamic>> offlinePlaylists = [];
      for (var id in offlineIds) {
        // Get name and cover path using the dedicated methods
        final name = await OfflinePlaylistData.getPlaylistName(id) ?? 'Unknown';
        final coverPath = await OfflinePlaylistData.getCoverImagePath(id);

        offlinePlaylists.add({
          'id': id,
          'name': name,
          'cover': coverPath ?? '',
        });

        logger.d(
            'Loaded offline playlist - ID: $id, Name: $name, Cover: ${coverPath ?? "no cover"}');
      }

      if (mounted) {
        // Check if widget is still mounted
        setState(() {
          this.offlinePlaylists = offlinePlaylists;
        });
      }
    } catch (e) {
      logger.e('Error loading offline playlists: $e');
    }
  }

  Future<void> _removeOfflinePlaylist(int playlistId) async {
    try {
      // First delete the physical files
      await OfflinePlaylistData.deletePlaylistFiles(playlistId);

      // Then remove from SharedPreferences and UI
      await OfflinePlaylistData.removeOfflinePlaylist(playlistId);

      setState(() {
        offlinePlaylists
            .removeWhere((playlist) => playlist['id'] == playlistId);
      });
    } catch (e) {
      logger.e('Error removing offline playlist: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing playlist: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Add method to refresh UI after download
  void refreshAfterDownload() {
    _loadOfflinePlaylists();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProviderOffline>(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.of(context).size.height * 0.06,
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        flexibleSpace: SafeArea(
          child: const CherryTopNavigation(isOffline: true),
        ),
      ),
      body: offlinePlaylists.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'This is Offline Playlists page. You can download playlists to use as offline playlists on your device. At the moment you do not have offline playlists available.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                      child: Text(
                        'Offline Playlists',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: offlinePlaylists.length,
                      itemBuilder: (context, index) {
                        final playlist = offlinePlaylists[index];
                        final playlistId = playlist['id'];
                        final coverPath = playlist['cover'];

                        return GestureDetector(
                          onTap: () async {
                            logger.d(
                                'Tapped on offline playlist ${playlist['id']}');

                            // Create a new AudioProviderOffline instance for this playlist
                            final playlistAudioProvider =
                                AudioProviderOffline(context);

                            final tracks =
                                await OfflinePlaylistData.getOfflineTracks(
                                    playlistId);

                            if (tracks.isEmpty) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'No tracks found in this playlist'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                              return;
                            }

                            if (!mounted) return;

                            logger.d(
                                'Setting offline playlist ${playlist['id']} with ${tracks.length} tracks');
                            await playlistAudioProvider
                                .setOfflinePlaylist(tracks);

                            playlistAudioProvider.setPlaylistDetails(
                              playlistId,
                              playlist['name'],
                              playlist['cover'],
                            );

                            if (!mounted) return;

                            // Stop the current global audio provider
                            await audioProvider.stop();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChangeNotifierProvider.value(
                                  value: playlistAudioProvider,
                                  child: OfflinePlaylistDetailPage(
                                    playlist: playlist,
                                    audioProvider: playlistAudioProvider,
                                  ),
                                ),
                              ),
                            );

                            // Start playing immediately
                            playlistAudioProvider.play();
                            logger.d(
                                'Started playing offline playlist ${playlist['id']} with ${tracks.length} tracks');
                          },
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Stack(
                                children: [
                                  ColorFiltered(
                                    colorFilter: const ColorFilter.mode(
                                      Color.fromRGBO(0, 0, 0, 0.5),
                                      BlendMode.darken,
                                    ),
                                    child: coverPath.isNotEmpty
                                        ? Image.file(
                                            File(coverPath),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const Icon(
                                                  Icons.music_note,
                                                  size: 50);
                                            },
                                          )
                                        : const Icon(Icons.music_note,
                                            size: 50),
                                  ),
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        playlist['name'],
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
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text(
                                                    'Remove Playlist'),
                                                content: const Text(
                                                    'Are you sure you want to remove this offline playlist?'),
                                                actions: [
                                                  TextButton(
                                                    child: const Text('Cancel'),
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(),
                                                  ),
                                                  TextButton(
                                                    child: const Text('Remove'),
                                                    onPressed: () {
                                                      _removeOfflinePlaylist(
                                                          playlistId);
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(
                                            Icons.delete_outline,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
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
                  ],
                ),
              ),
            ),
      bottomNavigationBar: audioProvider.isPlaying || audioProvider.isPaused
          ? MediaControlsOffline(
              playlistId: audioProvider.currentPlaylistId ?? 0)
          : null,
    );
  }
}

class OfflinePlaylistDetailPage extends StatelessWidget {
  final Map<String, dynamic> playlist;
  final AudioProviderOffline audioProvider;
  static final Logger logger = Logger();

  const OfflinePlaylistDetailPage({
    super.key,
    required this.playlist,
    required this.audioProvider,
  });

  Future<void> _handleBack(BuildContext context) async {
    await audioProvider.stop();
    audioProvider.dispose();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const OfflinePlaylistsPage(),
          settings: const RouteSettings(name: '/offline'),
        ),
      );
    }
  }

  Future<void> _loadAndPlayTracks(BuildContext context) async {
    try {
      final playlistId = playlist['id'];
      logger.d('Loading tracks for playlist ID: $playlistId');

      // Get tracks specifically for this playlist
      final tracks = await OfflinePlaylistData.getOfflineTracks(playlistId);

      if (tracks.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No tracks found in this playlist'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Ensure each track has the correct playlist ID
      final tracksWithPlaylistId = tracks
          .map((track) => {
                ...track,
                'playlistId': playlistId, // Explicitly set the playlist ID
              })
          .toList();

      logger.d(
          'Setting offline playlist $playlistId with ${tracks.length} tracks');
      await audioProvider.setOfflinePlaylist(tracksWithPlaylistId);

      audioProvider.setPlaylistDetails(
        playlistId,
        playlist['name'],
        playlist['cover'],
      );

      // Start playing
      audioProvider.play();
      logger.d(
          'Started playing offline playlist $playlistId with ${tracks.length} tracks');
    } catch (e) {
      logger.e('Error loading offline tracks: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tracks: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Load tracks when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadAndPlayTracks(context);
    });

    return WillPopScope(
      onWillPop: () async {
        await _handleBack(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleBack(context),
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.65,
                height: MediaQuery.of(context).size.width * 0.65,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 56,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: playlist['cover'].isNotEmpty
                      ? Image.file(
                          File(playlist['cover']),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            logger.e('Error loading cover image: $error');
                            return const Icon(Icons.music_note, size: 100);
                          },
                        )
                      : const Icon(Icons.music_note, size: 100),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              playlist['name'],
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            MediaControlsOffline(playlistId: playlist['id']),
          ],
        ),
      ),
    );
  }
}
