import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:appcherrylt/core/models/user_session.dart';
import 'package:logger/logger.dart';

class GetTracks with ChangeNotifier {
  List<dynamic> _tracks = [];
  List<dynamic> get tracks => _tracks;
  final Logger logger = Logger();

  Future<void> fetchAndNotifyTracks(
      BuildContext context, int playlistId) async {
    try {
      _tracks = await fetchTracks(context, playlistId);
      notifyListeners();
    } catch (e) {
      logger.d("Failed to fetch tracks: $e");
    }
  }

  Future<List<dynamic>> fetchTracks(
      BuildContext context, int playlistId) async {
    String accessToken =
        Provider.of<UserSession>(context, listen: false).globalToken;
    var url = Uri.parse(
        'https://app.cherrymusic.lt/api/playlists/$playlistId/tracks?access_token=$accessToken');

    var headers = {
      'Authorization': 'Basic YXBwOnd5cWQ3eWdqbmpvOXVyaGdmem5yYmc4amI3OGI3bWZ1',
    };

    var response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data != null && data['data'] != null) {
        return List<dynamic>.from(data['data']);
      } else {
        logger.d('API Response: ${response.body}');
        return [];
      }
    } else {
      throw Exception('Failed to load tracks: ${response.body}');
    }
  }
}
