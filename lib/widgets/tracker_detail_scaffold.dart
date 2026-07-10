import 'package:flutter/material.dart';

import '../models/tracker.dart';
import '../services/tracker_database.dart';
import 'delete_tracker_dialog.dart';

class TrackerDetailScaffold extends StatelessWidget {
  const TrackerDetailScaffold({
    super.key,
    required this.tracker,
    required this.body,
  });

  final Tracker tracker;
  final Widget body;

  Future<void> _deleteTracker(BuildContext context) async {
    final id = tracker.id;
    if (id == null) {
      return;
    }

    final shouldDelete = await showDeleteTrackerDialog(context, tracker.name);
    if (!shouldDelete || !context.mounted) {
      return;
    }

    await TrackerDatabase.instance.deleteTracker(id);

    if (context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tracker.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteTracker(context),
          ),
        ],
      ),
      body: body,
    );
  }
}
