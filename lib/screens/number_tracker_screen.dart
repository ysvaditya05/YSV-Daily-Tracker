import 'dart:async';
import 'package:flutter/material.dart';

import '../models/tracker.dart';
import '../widgets/number_weekly_progress_chart.dart';
import '../models/number_entry.dart';
import '../widgets/tracker_detail_scaffold.dart';

import '../services/tracker_database.dart';

class NumberTrackerScreen extends StatefulWidget {
  const NumberTrackerScreen({super.key, required this.tracker});

  final Tracker tracker;

  @override
	State<NumberTrackerScreen> createState() => _NumberTrackerScreenState();
	}

	class _NumberTrackerScreenState extends State<NumberTrackerScreen> {
	
		final _database = TrackerDatabase.instance;

	  double _currentValue = 0;
		double? _dailyGoal;
		String _unit = '';

		bool _isLoading = true;
		Timer? _midnightTimer;
		List<NumberEntry> _entries = [];
		bool _showAllEntries = false;
		
		final List<double> _weeklyProgress = List.filled(
			  7,
			  0,
			);
		
	@override
	void initState() {
	  super.initState();
	  _loadSettings();
	  _scheduleMidnightRefresh();
	}

	Future<void> _loadSettings() async {
	  final trackerId = widget.tracker.id;

	  if (trackerId == null) {
	    setState(() {
	      _isLoading = false;
	    });
	    return;
	  }

	  final settings =
	      await _database.getNumberTrackerSettings(trackerId);

	  if (!mounted) return;

	  if (settings != null) {
	    _currentValue = settings.currentValue;
	    _dailyGoal = settings.dailyGoal;
	    _unit = settings.unit;
	  }

	  setState(() {
	    _isLoading = false;
	  });
	  await _loadEntries();
	}
	
	Future<void> _loadEntries() async {
		  final trackerId = widget.tracker.id;

		  if (trackerId == null) return;

		  final entries = await _database.getTodayNumberEntries(trackerId);

		  if (!mounted) return;

		  double total = 0;
		  for (final entry in entries) {
		    total += entry.value;
		  }

		  _weeklyProgress[DateTime.now().weekday - 1] = total;

		  setState(() {
		    _entries = entries;
		    _currentValue = total;
		  });
		}
	
	void _scheduleMidnightRefresh() {
		  _midnightTimer?.cancel();

		  final now = DateTime.now();

		  final nextMidnight = DateTime(
		    now.year,
		    now.month,
		    now.day + 1,
		  );

		  final duration = nextMidnight.difference(now);

		  _midnightTimer = Timer(duration, () async {
		    if (!mounted) return;

		    await _loadSettings();
		    await _loadEntries();

		    _scheduleMidnightRefresh();
		  });
		}
	
	Future<void> _deleteEntry(NumberEntry entry) async {
		  final shouldDelete = await showDialog<bool>(
		    context: context,
		    builder: (context) {
		      return AlertDialog(
			title: const Text('Delete Entry'),
			content: const Text(
			  'Are you sure you want to delete this entry?',
			),
			actions: [
			  TextButton(
			    onPressed: () => Navigator.pop(context, false),
			    child: const Text('Cancel'),
			  ),
			  FilledButton(
			    onPressed: () => Navigator.pop(context, true),
			    child: const Text('Delete'),
			  ),
			],
		      );
		    },
		  );

		  if (shouldDelete != true) {
		    return;
		  }

		  await _database.deleteNumberEntry(entry.id!);

		  await _loadEntries();
		  await _saveSettings();
		}
	Future<void> _saveSettings() async {
	  final trackerId = widget.tracker.id;

	  if (trackerId == null) return;

	  await _database.saveNumberTrackerSettings(
	    trackerId: trackerId,
	    currentValue: _currentValue,
	    dailyGoal: _dailyGoal,
	    unit: _unit,
	  );
	}
	
	Future<void> _showCustomValueDialog() async {
		  final valueController = TextEditingController();
		  final descriptionController = TextEditingController();

		  final result = await showDialog<(double, String?)>(
		    context: context,
		    builder: (context) {
		      return AlertDialog(
			title: const Text('Add Entry'),
			content: Column(
			  mainAxisSize: MainAxisSize.min,
			  children: [
			    TextField(
			      controller: valueController,
			      keyboardType: const TextInputType.numberWithOptions(
				decimal: true,
			      ),
			      decoration: InputDecoration(
				labelText: _unit.isEmpty
				    ? 'Amount'
				    : 'Amount ($_unit)',
			      ),
			    ),
			    const SizedBox(height: 16),
			    TextField(
			      controller: descriptionController,
			      decoration: const InputDecoration(
				labelText: 'Description (optional)',
			      ),
			    ),
			  ],
			),
			actions: [
			  TextButton(
			    onPressed: () => Navigator.pop(context),
			    child: const Text('Cancel'),
			  ),
			  FilledButton(
			    onPressed: () {
			      final value =
				  double.tryParse(valueController.text.trim());

			      if (value != null) {
				Navigator.pop(
				  context,
				  (
				    value,
				    descriptionController.text.trim().isEmpty
				        ? null
				        : descriptionController.text.trim(),
				  ),
				);
			      }
			    },
			    child: const Text('Add'),
			  ),
			],
		      );
		    },
		  );

		  if (result == null) return;

		  await _database.createNumberEntry(
			  trackerId: widget.tracker.id!,
			  value: result.$1,
			  description: result.$2,
			);

			setState(() {
			  _currentValue += result.$1;
			});

			await _saveSettings();
			await _loadEntries();

		  // Description will be stored once we implement
		  // the Number Entry log.
		}
	  
	  Future<void> _setGoal() async {
		  final controller = TextEditingController(
			  text: _dailyGoal == null
			      ? ''
			      : _dailyGoal!.toInt().toString(),
			);
		  final unitController = TextEditingController(
			  text: _unit,
			);

		  final result = await showDialog<int>(
		    context: context,
		    builder: (context) {
		      return AlertDialog(
			title: const Text('Set Daily Goal'),
			content: Column(
				  mainAxisSize: MainAxisSize.min,
				  children: [

				    TextField(
				      controller: controller,
				      keyboardType: TextInputType.number,
				      decoration: const InputDecoration(
					labelText: 'Goal',
				      ),
				    ),

				    const SizedBox(height: 16),

				    TextField(
				      controller: unitController,
				      decoration: const InputDecoration(
					labelText: 'Unit (optional)',
				      ),
				    ),

				  ],
				),
			actions: [
			  TextButton(
			    onPressed: () => Navigator.pop(context),
			    child: const Text('Cancel'),
			  ),
			  FilledButton(
				  onPressed: () {
				    final text = controller.text.trim();

				    if (text.isEmpty) {
				      Navigator.pop<int?>(context, null);
				      return;
				    }

				    final value = int.tryParse(text);

				    if (value != null && value >= 0) {
				      Navigator.pop(context, value);
				    }
				  },
				  child: const Text('Save'),
				),
			],
		      );
		    },
		  );

		  setState(() {
			  _dailyGoal = result?.toDouble();
			  _unit = unitController.text.trim();
			});

			await _saveSettings();
		}
		
	@override
	void dispose() {
	  _midnightTimer?.cancel();
	  super.dispose();
	}

	  @override
	  Widget build(BuildContext context) {
		  if (_isLoading) {
			  return const Center(
			    child: CircularProgressIndicator(),
			  );
			}
		    return TrackerDetailScaffold(
	  tracker: widget.tracker,
	  body: Padding(
	    padding: const EdgeInsets.all(16),
	    child: SingleChildScrollView(
	      child: Column(
		crossAxisAlignment: CrossAxisAlignment.stretch,
		children: [

		  const Text(
		    'Daily Goal',
		    style: TextStyle(fontWeight: FontWeight.bold),
		  ),

		  const SizedBox(height: 8),

		  Text(
			  _dailyGoal == null
			      ? 'No goal set'
			      : _unit.isEmpty
				  ? 'Daily Goal: $_dailyGoal'
				  : 'Daily Goal: $_dailyGoal $_unit',
			),

		  Align(
		    alignment: Alignment.centerLeft,
		    child: TextButton(
		      onPressed: _setGoal,
		      child: const Text('Set Goal'),
		    ),
		  ),

		  const SizedBox(height: 24),

		  const Text(
		    "Today's Progress",
		    style: TextStyle(fontWeight: FontWeight.bold),
		  ),

		  const SizedBox(height: 8),

		  Text(
			  _dailyGoal == null
			      ? (_unit.isEmpty
				  ? _currentValue.toStringAsFixed(
				      _currentValue == _currentValue.roundToDouble() ? 0 : 1,
				    )
				  : '${_currentValue.toStringAsFixed(_currentValue == _currentValue.roundToDouble() ? 0 : 1)} $_unit')
			      : (_unit.isEmpty
				  ? '${_currentValue.toStringAsFixed(_currentValue == _currentValue.roundToDouble() ? 0 : 1)} / ${_dailyGoal!.toStringAsFixed(_dailyGoal == _dailyGoal!.roundToDouble() ? 0 : 1)}'
				  : '${_currentValue.toStringAsFixed(_currentValue == _currentValue.roundToDouble() ? 0 : 1)} / ${_dailyGoal!.toStringAsFixed(_dailyGoal == _dailyGoal!.roundToDouble() ? 0 : 1)} $_unit'),
			  textAlign: TextAlign.center,
			  style: Theme.of(context).textTheme.headlineMedium,
			),

		  const SizedBox(height: 12),

		  _dailyGoal == null
			    ? const LinearProgressIndicator(value: 0)
			    : LinearProgressIndicator(
				value: (_currentValue / _dailyGoal!)
				    .clamp(0.0, 1.0),
			      ),

		  const SizedBox(height: 32),

		  const Text(
			  'Current Value',
			  style: TextStyle(fontWeight: FontWeight.bold),
			),

			const SizedBox(height: 12),

			Text(
			  _unit.isEmpty
			      ? _currentValue.toStringAsFixed(
				  _currentValue == _currentValue.roundToDouble() ? 0 : 1,
				)
			      : '${_currentValue.toStringAsFixed(_currentValue == _currentValue.roundToDouble() ? 0 : 1)} $_unit',
			  textAlign: TextAlign.center,
			  style: Theme.of(context).textTheme.displaySmall,
			),

			const SizedBox(height: 20),

			OutlinedButton.icon(
			  onPressed: _showCustomValueDialog,
			  icon: const Icon(Icons.add),
			  label: const Text('Add Entry'),
			),
		const SizedBox(height: 32),

		const Text(
		  "Today's Entries",
		  style: TextStyle(fontWeight: FontWeight.bold),
		),

		_entries.isEmpty
		    ? const Center(
			child: Text('No entries yet.'),
		      )
		    : Column(
			children: [

			  ...(_showAllEntries
				  ? _entries
				  : _entries.take(2))
			      .map((entry) {
			    return Column(
			      children: [

				ListTile(
				  contentPadding: EdgeInsets.zero,
				  title: Text(
				    _unit.isEmpty
				        ? entry.value.toString()
				        : '${entry.value} $_unit',
				  ),
				  subtitle: entry.description == null
				      ? null
				      : Text(entry.description!),
				  trailing: IconButton(
				    icon: const Icon(Icons.delete),
				    onPressed: () => _deleteEntry(entry),
				  ),
				),

				const Divider(),

			      ],
			    );
			  }),

			  if (_entries.length > 2)
			    Align(
				  alignment: Alignment.centerLeft,
				  child: TextButton(
				onPressed: () {
				  setState(() {
				    _showAllEntries = !_showAllEntries;
				  });
				},
				child: Text(
				  _showAllEntries
				      ? 'Show Less'
				      : 'Show All (${_entries.length})',
				),
			      ),
			    ),

			],
		      ),
		      const SizedBox(height: 24),

			const Text(
			  'Weekly Progress',
			  style: TextStyle(fontWeight: FontWeight.bold),
			),

			const SizedBox(height: 8),

			NumberWeeklyProgressChart(
				  dailyValues: _weeklyProgress,
				  todayIndex: DateTime.now().weekday - 1,
				  unit: _unit,
				),

			const SizedBox(height: 8),
		],
	      ),
	    ),
	  ),
	);
	}
}

