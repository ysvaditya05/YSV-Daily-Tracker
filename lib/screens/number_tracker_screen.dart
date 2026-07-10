import 'package:flutter/material.dart';

import '../models/tracker.dart';
import '../widgets/tracker_detail_scaffold.dart';

class NumberTrackerScreen extends StatelessWidget {
  const NumberTrackerScreen({super.key, required this.tracker});

  final Tracker tracker;

  @override
  Widget build(BuildContext context) {
    return TrackerDetailScaffold(
      tracker: tracker,
      body: const Center(child: Text('This is a Number Tracker.')),
    );
  }
}
