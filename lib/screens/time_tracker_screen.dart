import 'dart:async';

import 'package:flutter/material.dart';

import '../models/tracker.dart';
import '../models/time_session.dart';
import '../models/time_tracker_goal.dart';
import '../services/tracker_database.dart';
import '../widgets/delete_session_dialog.dart';
import '../widgets/manual_session_dialog.dart';
import '../widgets/set_time_goal_dialog.dart';
import '../widgets/tracker_detail_scaffold.dart';
import '../widgets/weekly_progress_chart.dart';

class TimeTrackerScreen extends StatelessWidget {
  const TimeTrackerScreen({super.key, required this.tracker});

  final Tracker tracker;

  @override
  Widget build(BuildContext context) {
    return TrackerDetailScaffold(
      tracker: tracker,
      body: TimeTrackerContent(tracker: tracker),
    );
  }
}

class TimeTrackerContent extends StatefulWidget {
  const TimeTrackerContent({super.key, required this.tracker});

  final Tracker tracker;

  @override
  State<TimeTrackerContent> createState() => _TimeTrackerContentState();
}

class _TimeTrackerContentState extends State<TimeTrackerContent> {
  final _database = TrackerDatabase.instance;
  TimeSession? _runningSession;
  List<TimeSession> _completedSessions = [];
  List<Duration> _weeklyDurations = List.filled(7, Duration.zero);
  TimeTrackerGoal? _goal;
  Timer? _timer;
  bool _isLoading = true;
  bool _isChangingSession = false;
  bool _showAllSessions = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final trackerId = widget.tracker.id;
    if (trackerId == null) {
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final results = await Future.wait([
      _database.getRunningTimeSession(trackerId),
      _database.getTodayCompletedTimeSessions(trackerId),
      _database.getTimeTrackerGoalForDate(trackerId, today),
      _database.getTimeSessionDurationsByDate(
        trackerId: trackerId,
        startDate: startOfWeek,
        endDate: startOfWeek.add(const Duration(days: 6)),
      ),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _runningSession = results[0] as TimeSession?;
      _completedSessions = results[1] as List<TimeSession>;
      _goal = results[2] as TimeTrackerGoal?;
      final weeklyTotals = results[3] as Map<DateTime, Duration>;
      _weeklyDurations = List.generate(
        7,
        (index) =>
            weeklyTotals[startOfWeek.add(Duration(days: index))] ??
            Duration.zero,
      );
      _isLoading = false;
    });

    if (_runningSession != null) {
      _startTimerUpdates();
    }
  }

  void _startTimerUpdates() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _startSession() async {
    final trackerId = widget.tracker.id;
    if (trackerId == null || _isChangingSession) {
      return;
    }

    setState(() {
      _isChangingSession = true;
    });

    try {
      final session = await _database.startTimeSession(trackerId);
      if (!mounted) {
        return;
      }

      setState(() {
        _runningSession = session;
      });
      _startTimerUpdates();
    } finally {
      if (mounted) {
        setState(() {
          _isChangingSession = false;
        });
      }
    }
  }

  Future<void> _stopSession() async {
    final session = _runningSession;
    final sessionId = session?.id;
    if (sessionId == null || _isChangingSession) {
      return;
    }

    setState(() {
      _isChangingSession = true;
    });

    try {
      await _database.stopTimeSession(sessionId);
      _timer?.cancel();
      await _loadData();
    } finally {
      if (mounted) {
        setState(() {
          _isChangingSession = false;
        });
      }
    }
  }

  Duration get _todayProgress {
    final completedDuration = _completedSessions.fold<Duration>(
      Duration.zero,
      (total, session) => total + session.duration,
    );
    final runningSession = _runningSession;
    if (runningSession == null) {
      return completedDuration;
    }

    return completedDuration +
        DateTime.now().difference(runningSession.startedAt!);
  }

  Duration get _runningDuration {
    final session = _runningSession;
    if (session == null) {
      return Duration.zero;
    }

    return DateTime.now().difference(session.startedAt!);
  }

  String _formatTimer(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatProgress(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) {
      return '$hours h $minutes m';
    }
    if (hours > 0) {
      return '$hours h';
    }
    return '$minutes m';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _setGoal() async {
    final trackerId = widget.tracker.id;
    if (trackerId == null) {
      return;
    }

    final saved = await showSetTimeGoalDialog(
      context: context,
      initialGoal: _goal == null
          ? null
          : Duration(seconds: _goal!.dailyGoalSeconds),
      onSave: (goal) {
        return _database.createTimeTrackerGoal(
          trackerId: trackerId,
          dailyGoal: goal,
          effectiveDate: DateTime.now(),
        );
      },
    );

    if (saved && mounted) {
      await _loadData();
    }
  }

  Future<void> _addManualSession() async {
    final trackerId = widget.tracker.id;
    if (trackerId == null || _isChangingSession) {
      return;
    }

    final duration = await showManualSessionDialog(context);
    if (duration == null || !mounted) {
      return;
    }

    setState(() {
      _isChangingSession = true;
    });

    try {
      await _database.createManualTimeSession(
        trackerId: trackerId,
        duration: duration,
      );
      await _loadData();
    } finally {
      if (mounted) {
        setState(() {
          _isChangingSession = false;
        });
      }
    }
  }

  Future<void> _deleteSession(TimeSession session) async {
    final sessionId = session.id;
    if (sessionId == null) {
      return;
    }

    final shouldDelete = await showDeleteSessionDialog(context);
    if (!shouldDelete || !mounted) {
      return;
    }

    await _database.deleteTimeSession(sessionId);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final runningSession = _runningSession;
    final goal = _goal;
    final progress = _todayProgress;
    final displayedSessions =
	    _showAllSessions || _completedSessions.length <= 2
		? _completedSessions
		: _completedSessions.take(2).toList();
    return SingleChildScrollView(
	  padding: const EdgeInsets.all(16),
	  child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Daily Goal'),
          if (goal == null) ...[
            const Text('No goal set'),
          ] else ...[
            Text(_formatProgress(Duration(seconds: goal.dailyGoalSeconds))),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _setGoal,
              child: const Text('Set Goal'),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _formatTimer(_runningDuration),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isChangingSession
                ? null
                : (runningSession == null ? _startSession : _stopSession),
            child: Text(runningSession == null ? 'Start' : 'Stop'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _isChangingSession ? null : _addManualSession,
            child: const Text('Add Manual Session'),
          ),
          const SizedBox(height: 32),
          const Text("Today's Progress"),
          Text(
            goal == null
                ? _formatProgress(progress)
                : '${_formatProgress(progress)} / ${_formatProgress(Duration(seconds: goal.dailyGoalSeconds))}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (goal != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (progress.inSeconds / goal.dailyGoalSeconds)
                  .clamp(0.0, 1.0)
                  .toDouble(),
            ),
          ],
          const SizedBox(height: 24),
          Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Today's Sessions"),
                const SizedBox(height: 8),
                if (_completedSessions.isEmpty)
			  const Padding(
			    padding: EdgeInsets.symmetric(vertical: 24),
			    child: Center(
			      child: Text('No sessions yet.'),
			    ),
			  )
			else
			  Column(
			    children: displayedSessions.map((session) {
			      return ListTile(
				contentPadding: EdgeInsets.zero,
				title: Text(
				  session.isManual
				      ? 'Manual • ${_formatProgress(session.duration)}'
				      : '${_formatTime(session.startedAt!)} – ${_formatTime(session.endedAt!)}',
				),
				trailing: IconButton(
				  icon: const Icon(Icons.delete),
				  onPressed: () => _deleteSession(session),
				),
			      );
			    }).toList(),
			  ),
		  if (_completedSessions.length > 2)
			  Align(
			    alignment: Alignment.centerLeft,
			    child: TextButton.icon(
			      onPressed: () {
				setState(() {
				  _showAllSessions = !_showAllSessions;
				});
			      },
			      icon: Icon(
				_showAllSessions
				    ? Icons.keyboard_arrow_up
				    : Icons.keyboard_arrow_down,
			      ),
			      label: Text(
				_showAllSessions
				    ? 'Show fewer sessions'
				    : 'Show all sessions (${_completedSessions.length})',
			      ),
			    ),
			  ),
                const SizedBox(height: 16),
                const Text('Weekly Progress'),
                const SizedBox(height: 8),
                WeeklyProgressChart(
                  dailyDurations: _weeklyDurations,
                  todayIndex: now.weekday - 1,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
