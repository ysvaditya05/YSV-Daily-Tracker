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

	  int _currentValue = 0;
	  int? _dailyGoal;
	  String _unit = '';
	  
	  Future<void> _setGoal() async {
		  final controller = TextEditingController(
		    text: _dailyGoal?.toString() ?? '',
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
			      final value = int.tryParse(controller.text);

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

		  if (result != null) {
			  setState(() {
			    _dailyGoal = result;
			    _unit = unitController.text.trim();
			  });
			}
		}

	  @override
	  Widget build(BuildContext context) {
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
		    '0 / 0',
		    textAlign: TextAlign.center,
		    style: Theme.of(context).textTheme.headlineMedium,
		  ),

		  const SizedBox(height: 12),

		  LinearProgressIndicator(
			  value: 0,
			),

		  const SizedBox(height: 32),

		  const Text(
		    'Current Value',
		    style: TextStyle(fontWeight: FontWeight.bold),
		  ),

		  const SizedBox(height: 12),

		  Text(
			  _unit.isEmpty
			      ? '$_currentValue'
			      : '$_currentValue $_unit',
		    textAlign: TextAlign.center,
		    style: Theme.of(context).textTheme.displaySmall,
		  ),

		  const SizedBox(height: 20),

		  Row(
		    children: [

		      Expanded(
		        child: FilledButton(
				  onPressed: () {
				    setState(() {
				      if (_currentValue > 0) {
					_currentValue--;
				      }
				    });
				  },
				  child: const Text('-'),
				),
		      ),

		      const SizedBox(width: 16),

		      Expanded(
		        child: FilledButton(
				  onPressed: () {
				    setState(() {
				      _currentValue++;
				    });
				  },
				  child: const Text('+'),
				),
		      ),

		    ],
		  ),

		  const SizedBox(height: 16),

		  OutlinedButton(
		    onPressed: null,
		    child: const Text('Add Custom Value'),
		  ),

		],
	      ),
	    ),
	  ),
	);
	}
}

