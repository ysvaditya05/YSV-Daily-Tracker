import 'package:flutter/material.dart';

import '../models/tracker.dart';
import '../services/tracker_database.dart';
import '../widgets/delete_tracker_dialog.dart';
import 'checklist_tracker_screen.dart';
import 'create_tracker_screen.dart';
import 'list_tracker_screen.dart';
import 'number_tracker_screen.dart';
import 'time_tracker_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _database = TrackerDatabase.instance;
  late Future<List<Tracker>> _trackers;

  @override
  void initState() {
    super.initState();
    _trackers = _database.getTrackers();
  }

  void _reloadTrackers() {
    setState(() {
      _trackers = _database.getTrackers();
    });
  }

  Future<void> _openCreateTracker() async {
    final wasCreated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => const CreateTrackerScreen(),
      ),
    );

    if (wasCreated == true) {
      _reloadTrackers();
    }
  }

  Future<void> _openTracker(Tracker tracker) async {
    final Widget screen;

    switch (tracker.type) {
      case 'Time':
        screen = TimeTrackerScreen(tracker: tracker);
      case 'Number':
        screen = NumberTrackerScreen(tracker: tracker);
      case 'Checklist':
        screen = ChecklistTrackerScreen(tracker: tracker);
      case 'List':
        screen = ListTrackerScreen(tracker: tracker);
      default:
        return;
    }

    final wasDeleted = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute<bool>(builder: (context) => screen));

    if (wasDeleted == true) {
      _reloadTrackers();
    }
  }

  Future<void> _deleteTracker(Tracker tracker) async {
    final id = tracker.id;
    if (id == null) {
      return;
    }

    final shouldDelete = await showDeleteTrackerDialog(context, tracker.name);
    if (!shouldDelete || !mounted) {
      return;
    }

    await _database.deleteTracker(id);
    _reloadTrackers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('YSV Daily')),
      body: FutureBuilder<List<Tracker>>(
        future: _trackers,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load trackers.'));
          }

          final trackers = snapshot.data ?? [];
          if (trackers.isEmpty) {
            return const Center(
              child: Text(
                'No trackers yet.\n\nTap + to create your first tracker.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trackers.length,
            itemBuilder: (context, index) {
              final tracker = trackers[index];
              return Card(
                child: ListTile(
                  title: Text(tracker.name),
                  subtitle: Text(tracker.type),
                  onTap: () => _openTracker(tracker),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteTracker(tracker),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateTracker,
        child: const Icon(Icons.add),
      ),
    );
  }
}
