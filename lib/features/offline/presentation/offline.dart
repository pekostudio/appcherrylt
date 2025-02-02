import 'package:appcherrylt/core/providers/audio_provider.dart';
import 'package:appcherrylt/core/state/global_audio_state.dart';
import 'package:appcherrylt/core/widgets/cherry_top_nav_offline.dart';
import 'package:appcherrylt/features/audio/presentation/music_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appcherrylt/features/offline/data/offline_playlist_data.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
//import 'package:logger/logger.dart';

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
    _loadOfflinePlaylists();
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
      await OfflinePlaylistData.removeOfflinePlaylist(playlistId);
      await OfflinePlaylistData.deletePlaylistFiles(playlistId);
      setState(() {
        offlinePlaylists
            .removeWhere((playlist) => playlist['id'] == playlistId);
      });
    } catch (e) {
      // Handle error, e.g., show a message to the user
      print('Error removing offline playlist: $e');
    }
  }

  // Add method to refresh UI after download
  void refreshAfterDownload() {
    _loadOfflinePlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: const CherryTopNavigationOffline(),
      ),
      body: offlinePlaylists.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'You can download playlists to your device. At the moment you do not have offline playlists available.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<List<int>>(
                future: OfflinePlaylistData.getOfflinePlaylists(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text('No offline playlists available.');
                  } else {
                    final playlistIds = snapshot.data!;
                    return ListView.builder(
                      itemCount: playlistIds.length,
                      itemBuilder: (context, index) {
                        final playlistId = playlistIds[index];
                        return FutureBuilder<String?>(
                          future:
                              OfflinePlaylistData.getCoverImagePath(playlistId),
                          builder: (context, coverSnapshot) {
                            if (coverSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              print(
                                  'DEBUG: Loading cover image for playlist $playlistId...');
                              return const CircularProgressIndicator();
                            } else if (coverSnapshot.hasError) {
                              print(
                                  'DEBUG: Error loading cover image for playlist $playlistId: ${coverSnapshot.error}');
                              return Text('Error loading cover image.');
                            } else {
                              final coverPath = coverSnapshot.data;
                              print(
                                  'DEBUG: Cover path for playlist $playlistId: ${coverPath ?? "null"}');
                              if (coverPath != null) {
                                final file = File(coverPath);
                                print(
                                    'DEBUG: Cover file exists: ${file.existsSync()}');
                              }

                              final playlist = offlinePlaylists.firstWhere(
                                (p) => p['id'] == playlistId,
                                orElse: () => {'name': 'Unknown Playlist'},
                              );

                              return ListTile(
                                title: Text(playlist['name']),
                                leading: coverPath != null
                                    ? Builder(
                                        builder: (context) {
                                          logger.d(
                                              'Loading cover image from: $coverPath');
                                          return Image.file(
                                            File(coverPath),
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              logger.e(
                                                  'Error displaying cover image: $error');
                                              return const Icon(Icons.error);
                                            },
                                          );
                                        },
                                      )
                                    : const Icon(Icons.music_note),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () async {
                                    await _removeOfflinePlaylist(playlistId);
                                  },
                                ),
                                onTap: () async {
                                  final tracks = await OfflinePlaylistData
                                      .getOfflineTracks(playlistId);
                                  if (tracks.isNotEmpty) {
                                    final audioProvider =
                                        Provider.of<AudioProvider>(context,
                                            listen: false);
                                    await audioProvider
                                        .setOfflinePlaylist(tracks);
                                    // Navigate to a page that shows the audio player, if needed
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MusicPage(
                                            id: playlistId,
                                            name: 'Playlist $playlistId',
                                            title: 'Playlist $playlistId',
                                            description: '',
                                            cover: coverPath ?? '',
                                            categoryId: 0,
                                            categoryName: '',
                                            labelNew: 'false',
                                            labelUpdated: 'false',
                                            playlistId: playlistId,
                                            favorite: false,
                                          ),
                                        ));
                                  } else {
                                    print(
                                        'No tracks available for this playlist');
                                  }
                                },
                              );
                            }
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ),
    );
  }
}
