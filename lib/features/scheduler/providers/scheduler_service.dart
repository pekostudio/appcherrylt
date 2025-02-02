import 'package:appcherrylt/features/scheduler/data/get_scheduler.dart';
import 'package:intl/intl.dart';

@Deprecated(
    'Use SchedulerProvider instead. This service will be removed in a future version.')
class SchedulerService {
  @Deprecated('Use SchedulerProvider.shouldNavigateToMusicPage() instead.')
  static bool shouldNavigateToMusicPage(GetSchedule schedule) {
    DateTime now = DateTime.now();
    int currentDay = now.weekday;
    String currentTime = DateFormat('HH:mm').format(now);

    for (ScheduleItem item in schedule.list!) {
      if (item.day == currentDay &&
          currentTime.compareTo(item.start!) >= 0 &&
          currentTime.compareTo(item.end!) < 0) {
        return true;
      }
    }

    return false;
  }

  @Deprecated('Use SchedulerProvider.getCurrentScheduledPlaylistId() instead.')
  static int? getPlaylistId(GetSchedule schedule) {
    DateTime now = DateTime.now();
    int currentDay = now.weekday;
    String currentTime = DateFormat('HH:mm').format(now);

    for (ScheduleItem item in schedule.list!) {
      if (item.day == currentDay &&
          currentTime.compareTo(item.start!) >= 0 &&
          currentTime.compareTo(item.end!) < 0) {
        return item.playlist;
      }
    }

    return null;
  }

  @Deprecated('Use SchedulerProvider.isPastEndTime() instead.')
  static bool isPastEndTime(GetSchedule schedule) {
    DateTime now = DateTime.now();
    int currentDay = now.weekday;
    String currentTime = DateFormat('HH:mm').format(now);

    for (ScheduleItem item in schedule.list!) {
      if (item.day == currentDay && currentTime.compareTo(item.end!) >= 0) {
        return true;
      }
    }

    return false;
  }
}
