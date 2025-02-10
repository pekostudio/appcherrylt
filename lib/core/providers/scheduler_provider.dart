import 'package:appcherrylt/core/state/global_audio_state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../features/scheduler/data/get_scheduler.dart';
import 'package:logger/logger.dart';

class SchedulerProvider extends ChangeNotifier {
  final bool _hasActiveSchedule = false;
  DateTime? _lastScheduleCheck;
  Map<int, List<dynamic>>? _scheduledPlaylists;
  GetSchedule? _schedule;
  bool _isNavigatingToScheduledPlaylist = false;
  List<ScheduleItem>? _todayScheduleCache;
  DateTime? _todayScheduleCacheDate;
  final Logger _logger = Logger();

  // Getters
  bool get hasActiveSchedule => _hasActiveSchedule;
  DateTime? get lastScheduleCheck => _lastScheduleCheck;
  Map<int, List<dynamic>>? get scheduledPlaylists => _scheduledPlaylists;
  bool get isNavigatingToScheduledPlaylist => _isNavigatingToScheduledPlaylist;
  GetSchedule? get schedule => _schedule;
  List<ScheduleItem> get todaySchedule => _getTodaySchedule();

  // Set schedule data
  void setSchedule(GetSchedule schedule) {
    _schedule = schedule; // Always update the schedule
    _invalidateCache(); // Always invalidate cache
    _logger.d('Schedule updated, list length: ${schedule.list?.length ?? 0}');
    _logger.d('Today schedule length: ${_getTodaySchedule().length}');
    notifyListeners();
  }

  // Get today's schedule with caching
  List<ScheduleItem> _getTodaySchedule() {
    try {
      final now = DateTime.now();

      // Always invalidate cache if it's from a different day
      if (_todayScheduleCacheDate?.day != now.day) {
        _invalidateCache();
      }

      if (_todayScheduleCache != null) {
        return _todayScheduleCache!;
      }

      _todayScheduleCache =
          _schedule?.list?.where((item) => item.day == now.weekday).toList() ??
              [];
      _todayScheduleCacheDate = now;
      _logger.d(
          'Today schedule cache updated with ${_todayScheduleCache!.length} items');
      return _todayScheduleCache!;
    } catch (e) {
      _logger.e('Error getting today schedule: $e');
      return [];
    }
  }

  // Get schedule status
  ScheduleStatus getScheduleStatus(ScheduleItem schedule) {
    final currentTime = DateFormat('HH:mm').format(DateTime.now());

    if (schedule.start!.compareTo(currentTime) > 0) {
      return ScheduleStatus.upcoming;
    } else if (schedule.end!.compareTo(currentTime) < 0) {
      return ScheduleStatus.completed;
    } else {
      return ScheduleStatus.playing;
    }
  }

  // Get current playing schedule
  ScheduleItem? getCurrentPlayingSchedule() {
    try {
      final now = DateTime.now();
      final currentTime = DateFormat('HH:mm').format(now);

      return todaySchedule.firstWhere(
        (schedule) =>
            schedule.start != null &&
            schedule.end != null &&
            schedule.start!.compareTo(currentTime) <= 0 &&
            schedule.end!.compareTo(currentTime) > 0,
        orElse: () => ScheduleItem(),
      );
    } catch (e) {
      _logger.e('Error getting current playing schedule: $e');
      return null;
    }
  }

  // Check if schedule is active
  bool isScheduleActive(ScheduleItem schedule) {
    final now = DateTime.now();
    final today = DateTime.now();
    final startTime = DateFormat('HH:mm').parse(schedule.start!);
    final endTime = DateFormat('HH:mm').parse(schedule.end!);

    final scheduleStart = DateTime(
      today.year,
      today.month,
      today.day,
      startTime.hour,
      startTime.minute,
    );
    final scheduleEnd = DateTime(
      today.year,
      today.month,
      today.day,
      endTime.hour,
      endTime.minute,
    );

    return now.isAfter(scheduleStart) && now.isBefore(scheduleEnd);
  }

  // Get day name
  String getDayName(int day) {
    switch (day) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  // Check current time against schedule
  bool shouldNavigateToMusicPage() {
    if (_schedule?.list == null) return false;
    return todaySchedule.any((item) => isScheduleActive(item));
  }

  // Get current scheduled playlist ID
  int? getCurrentScheduledPlaylistId() {
    final currentSchedule = getCurrentPlayingSchedule();
    return currentSchedule?.playlist;
  }

  // Check if past end time
  bool isPastEndTime() {
    if (_schedule?.list == null) return false;
    final currentTime = DateFormat('HH:mm').format(DateTime.now());
    return todaySchedule.any((item) => currentTime.compareTo(item.end!) >= 0);
  }

  // Get current ad if any
  AdItem? getCurrentAd() {
    if (_schedule?.ads == null) return null;
    final now = DateTime.now();
    return _schedule!.ads!.firstWhere(
      (ad) =>
          ad.day == now.weekday &&
          ad.start == "${now.hour}:${now.minute.toString().padLeft(2, '0')}",
      orElse: () => AdItem(day: 0, start: '', tracks: []),
    );
  }

  // Set navigation state
  void setNavigatingToScheduledPlaylist(bool value) {
    if (_isNavigatingToScheduledPlaylist != value) {
      _isNavigatingToScheduledPlaylist = value;
      _logger.d('Setting navigating to scheduled playlist: $value');
      notifyListeners();
    }
  }

  // Check if there are schedules for today
  bool hasScheduledPlaylistsToday() {
    final now = DateTime.now();
    final currentDay = now.weekday;

    // Check if there are any playlists scheduled for today, regardless of time
    final hasSchedules =
        todaySchedule.any((schedule) => schedule.day == currentDay);

    logger.d('Has scheduled playlists today: $hasSchedules');

    return hasSchedules;
  }

  // Invalidate cache
  void _invalidateCache() {
    _todayScheduleCache = null;
    _todayScheduleCacheDate = null;
  }

  // Add this method to check if current playlist should stop
  bool shouldStopCurrentPlaylist() {
    try {
      final now = DateTime.now();
      final currentTime = DateFormat('HH:mm').format(now);

      // Get currently playing schedule
      final currentSchedule = getCurrentPlayingSchedule();
      if (currentSchedule?.end == null) return false;

      // Check if we've passed the end time
      final shouldStop = currentTime.compareTo(currentSchedule!.end!) >= 0;
      _logger.d(
          'Checking if should stop playlist: $shouldStop (Current: $currentTime, End: ${currentSchedule.end})');

      return shouldStop;
    } catch (e) {
      _logger.e('Error checking if playlist should stop: $e');
      return false;
    }
  }

  // Get next scheduled playlist that should start now
  ScheduleItem? getNextScheduledPlaylist() {
    try {
      final now = DateTime.now();
      final currentTime = DateFormat('HH:mm').format(now);

      return todaySchedule.firstWhere(
        (schedule) =>
            schedule.start != null &&
            schedule.end != null &&
            schedule.start!.compareTo(currentTime) <=
                0 && // Should have started
            schedule.end!.compareTo(currentTime) > 0 && // Hasn't ended yet
            getScheduleStatus(schedule) ==
                ScheduleStatus.playing, // Is currently active
        orElse: () => ScheduleItem(),
      );
    } catch (e) {
      _logger.e('Error getting next scheduled playlist: $e');
      return null;
    }
  }

  bool isTimeInSchedule(ScheduleItem schedule, DateTime currentTime) {
    final scheduleStart = _parseTime(schedule.start!);
    final scheduleEnd = _parseTime(schedule.end!);
    final currentTimeOfDay = TimeOfDay.fromDateTime(currentTime);

    return _isTimeInRange(currentTimeOfDay, scheduleStart, scheduleEnd);
  }

  bool _isTimeInRange(TimeOfDay time, TimeOfDay start, TimeOfDay end) {
    final now = time.hour * 60 + time.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return now >= startMinutes && now < endMinutes;
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  ScheduleItem? getCurrentScheduledPlaylist() {
    if (_todayScheduleCache == null) return null;
    final now = DateTime.now();
    for (var schedule in _todayScheduleCache!) {
      if (isTimeInSchedule(schedule, now)) {
        return schedule;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _invalidateCache();
    _schedule = null;
    super.dispose();
  }
}

enum ScheduleStatus { upcoming, playing, completed }
