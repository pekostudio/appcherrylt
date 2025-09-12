import 'package:appcherrylt/core/providers/audio_provider.dart';
import 'package:appcherrylt/features/audio/presentation/music_page.dart';
import 'package:flutter/material.dart';
import 'package:appcherrylt/features/home/data/get_playlists.dart';
import 'package:provider/provider.dart';
import 'package:appcherrylt/core/widgets/favourite_toggle_icon.dart';
import 'package:appcherrylt/core/models/favourites.dart';

class FavoritePlaylists extends StatelessWidget {
  final GetPlaylists getPlaylists;

  const FavoritePlaylists({super.key, required this.getPlaylists});

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteManager>(
      builder: (context, favoriteManager, child) {
        var favoritePlaylists =
            getPlaylists.favoritePlaylists?.where((playlist) {
          return favoriteManager.isFavorite(playlist['id']);
        }).toList();

        if (favoritePlaylists == null || favoritePlaylists.isEmpty) {
          return Container(); // Return an empty container if there are no favorite playlists
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 0, 8),
              child: Text(
                "Favorites",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            SizedBox(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  itemCount: favoritePlaylists.length,
                  itemBuilder: (context, index) {
                    var playlist = favoritePlaylists[index];
                    return GestureDetector(
                      onTap: () {
                        final audioProvider =
                            Provider.of<AudioProvider>(context, listen: false);
                        audioProvider.setPlaylistDetails(
                          playlist['id'] ?? 0,
                          playlist['title'] ?? 'Unknown Playlist',
                          playlist['cover'] ?? '',
                        );
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
                              child: FavoriteToggleIcon(
                                playlistId: playlist['id'],
                                isFavorite: playlist['favorite'],
                                onToggle: (newStatus) {
                                  // Handle the toggle action if needed
                                  favoriteManager.setFavorite(
                                      playlist['id'], newStatus);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
