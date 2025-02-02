import 'package:appcherrylt/api/api.dart';
import 'package:appcherrylt/features/scheduler/data/get_scheduler.dart';
import 'package:appcherrylt/core/models/user_session.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScheduleScreen extends StatefulWidget {
  final String accessToken;

  const ScheduleScreen({super.key, required this.accessToken});

  @override
  ScheduleScreenState createState() => ScheduleScreenState();
}

class ScheduleScreenState extends State<ScheduleScreen> {
  late Future<GetSchedule?> _scheduleFuture;

  @override
  void initState() {
    super.initState();
    String accessToken =
        Provider.of<UserSession>(context, listen: false).globalToken;
    _scheduleFuture = API().getSchedule(accessToken);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<GetSchedule?>(
              future: _scheduleFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  GetSchedule? schedule = snapshot.data;
                  if (schedule != null) {
                    return ScheduleList(schedule: schedule);
                  } else {
                    return const Center(
                        child: Text('No schedule data available'));
                  }
                } else {
                  return const Center(child: Text('No data'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ScheduleList extends StatelessWidget {
  final GetSchedule schedule;

  const ScheduleList({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    List<ScheduleItem>? scheduleItems = schedule.list;
    List<AdItem>? adItems = schedule.ads;

    return ListView(
      children: [
        if (scheduleItems != null)
          ...scheduleItems.map((item) => ScheduleItemTile(item: item)),
        if (adItems != null) ...adItems.map((item) => AdItemTile(item: item)),
      ],
    );
  }
}

class ScheduleItemTile extends StatelessWidget {
  final ScheduleItem item;

  const ScheduleItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Day: ${item.day}'),
      subtitle: Text('Start - End: ${item.start} - ${item.end}'),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Playlist: ${item.playlist}'),
        ],
      ),
    );
  }
}

class AdItemTile extends StatelessWidget {
  final AdItem item;

  const AdItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Day ${item.day}'),
      subtitle: Text('Start: ${item.start}'),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Track: ${item.tracks}'),
        ],
      ),
    );
  }
}
