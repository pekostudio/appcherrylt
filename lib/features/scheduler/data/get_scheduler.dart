import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

class GetSchedule extends ChangeNotifier {
  List<ScheduleItem>? list;
  List<AdItem>? ads;
  final Logger logger = Logger();

  GetSchedule({this.list, this.ads});

  GetSchedule.fromJson(Map<String, dynamic> json) {
    if (json['list'] != null) {
      list = <ScheduleItem>[];
      json['list'].forEach((v) {
        list!.add(ScheduleItem.fromJson(v));
      });
    }
    if (json['ads'] != null) {
      ads = <AdItem>[];
      json['ads'].forEach((v) {
        ads!.add(AdItem.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (list != null) {
      data['list'] = list!.map((v) => v.toJson()).toList();
    }
    if (ads != null) {
      data['ads'] = ads!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  Future<void> fetchSchedulerData(String accessToken) async {
    String baseUrl = 'https://app.cherrymusic.lt/api';
    final url = Uri.parse('$baseUrl/schedule').replace(queryParameters: {
      'access_token': accessToken,
    });

    final headers = {
      'Authorization': 'Basic YXBwOnd5cWQ3eWdqbmpvOXVyaGdmem5yYmc4amI3OGI3bWZ1',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] == null) {
          final scheduleData = data['data'];
          if (scheduleData is Map<String, dynamic>) {
            list = scheduleData['list'] != null
                ? (scheduleData['list'] as List)
                    .map((item) =>
                        ScheduleItem.fromJson(item as Map<String, dynamic>))
                    .toList()
                : [];

            ads = scheduleData['ads'] != null
                ? (scheduleData['ads'] as List)
                    .map(
                        (item) => AdItem.fromJson(item as Map<String, dynamic>))
                    .toList()
                : [];
          } else if (scheduleData is List) {
            // Handle the case where scheduleData is a List
            list = [];
            ads = [];
          }

          notifyListeners();
        } else {
          logger.d('Error from API: ${data['error']['message']}');
          throw Exception('Error from API: ${data['error']['message']}');
        }
      } else {
        throw Exception('Failed to load scheduler data');
      }
    } catch (e) {
      // Handle the error gracefully, e.g., set list and ads to empty lists
      logger.e("Error fetching scheduler data: $e");
      list = [];
      ads = [];
      notifyListeners();
    }
  }

  ScheduleItem? getActiveSchedule() {
    DateTime now = DateTime.now();
    int currentDay = now.weekday;
    String currentTime = DateFormat('HH:mm').format(now);

    return list?.firstWhere(
      (schedule) =>
          schedule.day == currentDay &&
          schedule.start!.compareTo(currentTime) <= 0 &&
          schedule.end!.compareTo(currentTime) >
              0, // Changed >= to > for end time
      orElse: () => ScheduleItem(),
    );
  }

  ScheduleItem? getNextSchedule() {
    DateTime now = DateTime.now();
    int currentDay = now.weekday;
    String currentTime = DateFormat('HH:mm').format(now);

    var todaySchedules = list
        ?.where((schedule) => schedule.day == currentDay)
        .toList()
      ?..sort((a, b) => a.start!.compareTo(b.start!));

    return todaySchedules?.firstWhere(
      (schedule) => schedule.start!.compareTo(currentTime) > 0,
      orElse: () => ScheduleItem(),
    );
  }
}

class ScheduleItem {
  int? day;
  String? start;
  String? end;
  int? playlist;
  String? playlistName;
  ScheduleItem(
      {this.day, this.start, this.end, this.playlist, this.playlistName});

  ScheduleItem.fromJson(Map<String, dynamic> json) {
    day = json['day'] as int?;
    start = json['start'] as String?;
    end = json['end'] as String?;
    playlist = json['playlist'] as int?;
    playlistName = json['playlist_name'] as String?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['day'] = day;
    data['start'] = start;
    data['end'] = end;
    data['playlist'] = playlist;
    data['playlist_name'] = playlistName;
    return data;
  }
}

class AdItem {
  int? day;
  String? start;
  List<int>? tracks;

  AdItem({this.day, this.start, this.tracks});

  AdItem.fromJson(Map<String, dynamic> json) {
    day = json['day'] as int?;
    start = json['start'] as String?;
    tracks = (json['tracks'] as List).cast<int>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['day'] = day;
    data['start'] = start;
    data['tracks'] = tracks;
    return data;
  }
}
