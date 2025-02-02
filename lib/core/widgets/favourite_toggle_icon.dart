import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appcherrylt/api/api.dart';
import 'package:appcherrylt/core/models/user_session.dart';
import 'package:appcherrylt/core/models/favourites.dart';

class FavoriteToggleIcon extends StatelessWidget {
  final int playlistId;
  final bool isFavorite;
  final ValueChanged<bool> onToggle;

  const FavoriteToggleIcon({
    super.key,
    required this.playlistId,
    required this.isFavorite,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteManager>(
      builder: (context, favoriteManager, child) {
        bool isFavorite = favoriteManager.isFavorite(playlistId);
        return IconButton(
          alignment: Alignment.center,
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red.shade600 : Colors.black,
            size: 24,
          ),
          onPressed: () async {
            final favoriteManager =
                Provider.of<FavoriteManager>(context, listen: false);
            final newFavoriteStatus = !isFavorite;
            favoriteManager.setFavorite(playlistId, newFavoriteStatus);
            onToggle(newFavoriteStatus);

            // Toggle the favorite status
            String accessToken =
                Provider.of<UserSession>(context, listen: false).globalToken;
            bool success = await _toggleFavoriteStatus(
                playlistId, newFavoriteStatus, accessToken);

            if (success) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      textAlign: TextAlign.center,
                      newFavoriteStatus
                          ? 'Added to favorites'
                          : 'Removed from favorites',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: -0.6,
                      ),
                    ),
                    duration: const Duration(seconds: 1),
                    backgroundColor: Colors.black,
                  ),
                );
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to update favorite status'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
          },
          tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
        );
      },
    );
  }

  Future<bool> _toggleFavoriteStatus(
      int playlistId, bool isFavorite, String accessToken) async {
    return await API()
        .toggleFavoriteStatus(playlistId, isFavorite, accessToken);
  }
}
