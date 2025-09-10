import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Unique name for the background port
const String _backgroundName = 'background_scheduler_isolate';

// Alarm IDs
const int scheduleCheckAlarmId = 0;
const int schedulePlaylistAlarmId = 1;

// This class handles all background scheduling tasks
class BackgroundService {
  // Initialize the background service
  static Future<bool> initialize() async {
    // Only initialize Android Alarm Manager on Android platform
    bool initialized = true;

    // Check if the platform is Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      initialized = await AndroidAlarmManager.initialize();
    }

    // Register port for background communication
    final ReceivePort port = ReceivePort();
    IsolateNameServer.registerPortWithName(
      port.sendPort,
      _backgroundName,
    );

    return initialized;
  }

  // Start periodic schedule check (every minute)
  static Future<bool> startPeriodicScheduleCheck() async {
    // Only schedule alarms on Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await AndroidAlarmManager.periodic(
        const Duration(minutes: 1),
        scheduleCheckAlarmId,
        _checkScheduleCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
    }

    // Return true for other platforms
    return true;
  }

  // Schedule a one-time check for a specific playlist at a specific time
  static Future<bool> schedulePlaylistStartAlarm(
      DateTime startTime, int playlistId, String playlistName) async {
    // Store playlist info in shared preferences for the callback to use
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('scheduled_playlist_id', playlistId);
    await prefs.setString('scheduled_playlist_name', playlistName);

    // Only schedule alarms on Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await AndroidAlarmManager.oneShotAt(
        startTime,
        schedulePlaylistAlarmId,
        _startScheduledPlaylistCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
    }

    // Return true for other platforms
    return true;
  }

  // Cancel an alarm
  static Future<bool> cancelAlarm(int id) async {
    // Only cancel alarms on Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await AndroidAlarmManager.cancel(id);
    }

    // Return true for other platforms
    return true;
  }
}

// Callback function that runs in the background to check schedule
@pragma('vm:entry-point')
Future<void> _checkScheduleCallback() async {
  // Get port for communication with main isolate
  SendPort? sendPort = IsolateNameServer.lookupPortByName(_backgroundName);

  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('access_token');

  // Skip if no token available
  if (token == null) return;

  try {
    // Fetch schedule data
    final scheduleData = await _fetchScheduleData(token);
    if (scheduleData == null) return;

    // Check for active playlists
    final now = DateTime.now();
    final currentDay = now.weekday;
    final currentTime = DateFormat('HH:mm').format(now);

    final activeSchedule =
        _getActiveSchedule(scheduleData, currentDay, currentTime);

    if (activeSchedule != null) {
      // Store active playlist for main app to use
      await prefs.setInt('active_playlist_id', activeSchedule['playlist']);
      await prefs.setString(
          'active_playlist_name', activeSchedule['playlist_name']);
      await prefs.setBool('has_active_schedule', true);

      // Send message to main isolate if port available
      if (sendPort != null) {
        sendPort.send({
          'type': 'active_schedule',
          'playlist_id': activeSchedule['playlist'],
          'playlist_name': activeSchedule['playlist_name']
        });
      }
    } else {
      await prefs.setBool('has_active_schedule', false);
    }

    // Also check for upcoming schedules and set an alarm for them
    final nextSchedule =
        _getNextSchedule(scheduleData, currentDay, currentTime);
    if (nextSchedule != null) {
      // Parse start time
      final startTimeParts = nextSchedule['start'].split(':');
      final startTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(startTimeParts[0]),
        int.parse(startTimeParts[1]),
      );

      // If startTime is in the future, schedule an alarm
      if (startTime.isAfter(now)) {
        await BackgroundService.schedulePlaylistStartAlarm(
          startTime,
          nextSchedule['playlist'],
          nextSchedule['playlist_name'],
        );
      }
    }
  } catch (e) {
    print('Error in background check: $e');
  }
}

// Callback function that runs when a scheduled playlist should start
@pragma('vm:entry-point')
Future<void> _startScheduledPlaylistCallback() async {
  // Get port for communication with main isolate
  SendPort? sendPort = IsolateNameServer.lookupPortByName(_backgroundName);

  final prefs = await SharedPreferences.getInstance();
  final int? playlistId = prefs.getInt('scheduled_playlist_id');
  final String? playlistName = prefs.getString('scheduled_playlist_name');

  if (playlistId != null && playlistName != null) {
    // Set active playlist
    await prefs.setInt('active_playlist_id', playlistId);
    await prefs.setString('active_playlist_name', playlistName);
    await prefs.setBool('has_active_schedule', true);

    // Message main isolate
    if (sendPort != null) {
      sendPort.send({
        'type': 'start_playlist',
        'playlist_id': playlistId,
        'playlist_name': playlistName
      });
    }
  }
}

// Helper function to fetch schedule data
Future<Map<String, dynamic>?> _fetchScheduleData(String accessToken) async {
  final url = Uri.parse('https://app.cherrymusic.lt/api/schedule')
      .replace(queryParameters: {'access_token': accessToken});

  final headers = {
    'Authorization': 'Basic YXBwOnd5cWQ3eWdqbmpvOXVyaGdmem5yYmc4amI3OGI3bWZ1',
  };

  try {
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['error'] == null && data['data'] != null) {
        return data['data'];
      }
    }
  } catch (e) {
    print('Error fetching schedule data: $e');
  }

  return null;
}

// Helper function to find active schedule
Map<String, dynamic>? _getActiveSchedule(
    Map<String, dynamic> scheduleData, int currentDay, String currentTime) {
  if (scheduleData['list'] == null) return null;

  for (var schedule in scheduleData['list']) {
    if (schedule['day'] == currentDay &&
        schedule['start'] != null &&
        schedule['end'] != null &&
        schedule['start'].compareTo(currentTime) <= 0 &&
        schedule['end'].compareTo(currentTime) > 0) {
      return schedule;
    }
  }

  return null;
}

// Helper function to find next schedule
Map<String, dynamic>? _getNextSchedule(
    Map<String, dynamic> scheduleData, int currentDay, String currentTime) {
  if (scheduleData['list'] == null) return null;

  // Filter schedules for today
  final todaySchedules = (scheduleData['list'] as List)
      .where((schedule) => schedule['day'] == currentDay)
      .toList();

  // Sort by start time
  todaySchedules.sort((a, b) => a['start'].compareTo(b['start']));

  // Find first schedule that hasn't started yet
  for (var schedule in todaySchedules) {
    if (schedule['start'].compareTo(currentTime) > 0) {
      return schedule;
    }
  }

  return null;
}
