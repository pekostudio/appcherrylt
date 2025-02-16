import 'package:appcherrylt/features/scheduler/data/get_scheduler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';

class API {
  static const String baseUrl = 'https://app.cherrymusic.lt/api';
  final Logger logger = Logger();

  // Aaccess token
  Future<String?> getAccessToken(String login, String password) async {
    try {
      var url = Uri.parse('$baseUrl/access_token').replace(queryParameters: {
        'login': login,
        'password': password,
      });

      var headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization':
            'Basic YXBwOnd5cWQ3eWdqbmpvOXVyaGdmem5yYmc4amI3OGI3bWZ1',
      };

      var body =
          'login=${Uri.encodeComponent(login)}&password=${Uri.encodeComponent(password)}';

      var response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['error'] == null) {
          String accessToken = data['data']['access_token'];
          //print('Access Token: $accessToken');
          return accessToken;
        } else {
          logger.d('Error from API: ${data['error']['message']}');
          throw Exception(data['error']['message'] ?? 'Login failed');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Invalid credentials');
      } else {
        logger.d('Failed to get token: ${response.body}');
        throw Exception('Server error occurred');
      }
    } catch (e) {
      logger.d('Error occurred: $e');
      rethrow;
    }
    return null;
  }

  // Get Playlists
  Future<List<dynamic>?> getPlaylists(String accessToken) async {
    try {
      var url = Uri.parse('$baseUrl/playlists').replace(queryParameters: {
        'access_token': accessToken,
      });

      var headers = {
        'Authorization':
            'Basic YXBwOnd5cWQ3eWdqbmpvOXVyaGdmem5yYmc4amI3OGI3bWZ1',
      };

      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['error'] == null) {
          List<dynamic> tracks = data['data'];
          //print('Tracks: $tracks');
          return tracks;
        } else {
          logger.d('Error from API: ${data['error']['message']}');
        }
      } else {
        logger.d('Failed to get playlist tracks: ${response.body}');
      }
    } catch (e) {
      logger.d('Error occurred: $e');
    }
    return null;
  }

  // Favourites ADD/REMOVE playlist
  Future<bool> toggleFavoriteStatus(
      int playlistId, bool isFavorite, String accessToken) async {
    var url = Uri.parse('$baseUrl/playlists/$playlistId/favorite')
        .replace(queryParameters: {
      'access_token': accessToken,
    });

    var headers = {
      'Authorization': 'Basic YXBwOnd5cWQ3eWdqbmpvOXVyaGdmem5yYmc4amI3OGI3bWZ1',
    };

    var body = jsonEncode({"data": true});

    try {
      http.Response response;
      if (isFavorite) {
        // Use POST to add to favorites
        response = await http.post(url, headers: headers, body: body);
      } else {
        // Use DELETE to remove from favorites, no body required
        response = await http.delete(url, headers: headers);
      }

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Fetch the favorite status of a playlist
  Future<bool> getFavoriteStatus(int playlistId, String accessToken) async {
    var url =
        Uri.parse('$baseUrl/playlists/$playlistId/').replace(queryParameters: {
      'access_token': accessToken,
    });

    var headers = {
      'Authorization': 'Basic YXBwOnd5cWQ3eWdqbmpvOXVyaGdmem5yYmc4amI3OGI3bWZ1',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data[
            'favorite']; // Extracting the 'favorite' boolean field from the response
      } else {
        throw Exception('Failed to load favorite status');
      }
    } catch (e) {
      return false; // Handle error or throw an exception as needed
    }
  }

  // Like or dislike a track
  Future<bool> setTrackLikeDislike(
      int trackId, int value, int playlistId, String accessToken) async {
    var url =
        Uri.parse('$baseUrl/tracks/$trackId/likes').replace(queryParameters: {
      'access_token': accessToken,
    });

    var headers = {
      'Authorization': 'Basic YXBwOnd5cWQ3eWdqbmpvOXVyaGdmem5yYmc4amI3OGI3bWZ1',
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    var body = 'value=$value&playlist=$playlistId';

    try {
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Get Schedule
  Future<GetSchedule?> getSchedule(String accessToken) async {
    try {
      var url = Uri.parse('$baseUrl/schedule').replace(queryParameters: {
        'access_token': accessToken,
      });

      var headers = {
        'Authorization':
            'Basic YXBwOnd5cWQ3eWdqbmpvOXVyaGdmem5yYmc4amI3OGI3bWZ1',
      };

      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['error'] == null) {
          GetSchedule scheduleData = GetSchedule.fromJson(data['data']);
          return scheduleData;
        } else {
          logger.d('Error from API: ${data['error']['message']}');
        }
      } else {
        logger.d('Failed to get schedule data: ${response.body}');
      }
    } catch (e) {
      logger.d('Error occurred: $e');
    }
    return null;
  }

  // Add more methods for other endpoints
}
