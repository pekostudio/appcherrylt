import 'package:appcherrylt/core/widgets/cherry_top_nav_offline.dart';
import 'package:appcherrylt/features/audio/presentation/music_page.dart';
import 'package:appcherrylt/features/home/data/get_playlists.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appcherrylt/features/offline/data/offline_playlist_data.dart';

class OfflinePlaylistsPage extends StatefulWidget {
  const OfflinePlaylistsPage({super.key});

  @override
  State<OfflinePlaylistsPage> createState() => _OfflinePlaylistsPageState();
}

class _OfflinePlaylistsPageState extends State<OfflinePlaylistsPage> {
  List<int> offlinePlaylistIds = [];

  @override
  void initState() {
    super.initState();
    _loadOfflinePlaylists();
  }

  Future<void> _loadOfflinePlaylists() async {
    try {
      final offlineIds = await OfflinePlaylistData.getOfflinePlaylists();
      setState(() {
        offlinePlaylistIds = offlineIds;
      });
    } catch (e) {
      // Handle error, e.g., show a message to the user
      print('Error loading offline playlists: $e');
    }
  }

  Future<void> _removeOfflinePlaylist(int playlistId) async {
    try {
      await OfflinePlaylistData.removeOfflinePlaylist(playlistId);
      await OfflinePlaylistData.deletePlaylistFiles(playlistId);
      setState(() {
        offlinePlaylistIds.remove(playlistId);
      });
    } catch (e) {
      // Handle error, e.g., show a message to the user
      print('Error removing offline playlist: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final allPlaylists = Provider.of<GetPlaylists>(context).playlists ?? [];

    final offlinePlaylists = allPlaylists
        .where((playlist) => offlinePlaylistIds.contains(playlist['id']))
        .toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: const CherryTopNavigationOffline(),
      ),
      body: offlinePlaylists.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0), // Adjust padding as needed
                child: Text(
                  'You can download playlists to your device. At the moment you do not have offline playlists available.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                itemCount: offlinePlaylists.length,
                itemBuilder: (context, index) {
                  final playlist = offlinePlaylists[index];
                  return GestureDetector(
                    onTap: () {
                      // Navigate to InnerPage (your details page)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MusicPage(
                            id: playlist['id'],
                            playlistId: playlist['id'],
                            name: playlist['name'],
                            title: playlist['title'],
                            description: playlist['description'],
                            cover: playlist['cover'],
                            categoryId: playlist['category_id'],
                            categoryName: playlist['category_name'],
                            favorite: playlist['favorite'],
                            labelNew: playlist['label_new'],
                            labelUpdated: playlist['label_updated'],
                          ),
                        ),
                      );
                    },
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(playlist['cover']),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withOpacity(0.5),
                                  BlendMode.darken,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(
                                  playlist['title'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  onPressed: () {
                                    _removeOfflinePlaylist(playlist['id']);
                                  })),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
