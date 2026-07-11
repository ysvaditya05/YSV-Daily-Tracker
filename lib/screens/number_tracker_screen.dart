import 'package:flutter/material.dart';

import '../models/tracker.dart';
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
		
	@override
	void initState() {
	  super.initState();
	  _loadSettings();
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

		  setState(() {
		    _currentValue += result.$1;
		  });

		  await _saveSettings();

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

		const SizedBox(height: 8),

		const Center(
		  child: Text(
		    'Entry log coming next',
		    style: TextStyle(color: Colors.grey),
		  ),
		),
		],
	      ),
	    ),
	  ),
	);
	}
}

