import 'package:flutter/material.dart';

import '../models/tracker.dart';
import '../widgets/tracker_detail_scaffold.dart';
import '../models/checklist_item.dart';
import '../services/tracker_database.dart';
import 'dart:async';

class ChecklistTrackerScreen extends StatefulWidget {
  const ChecklistTrackerScreen({
    super.key,
    required this.tracker,
  });

  final Tracker tracker;

@override
State<ChecklistTrackerScreen> createState() =>
    _ChecklistTrackerScreenState();
}

Timer? _midnightTimer;

class _ChecklistTrackerScreenState
    extends State<ChecklistTrackerScreen> {
    final _database = TrackerDatabase.instance;

	List<ChecklistItem> _items = [];
	
	@override
	void initState() {
	  super.initState();
	  _loadItems();
	  _scheduleMidnightRefresh();
	}
	
	Future<void> _loadItems() async {
	  final trackerId = widget.tracker.id;

	  if (trackerId == null) return;

	  final items =
	      await _database.getTodayChecklistItems(trackerId);

	  if (!mounted) return;

	  setState(() {
	    _items = items;
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

	  _midnightTimer = Timer(
	    nextMidnight.difference(now),
	    () async {
	      if (!mounted) return;

	      await _database.resetChecklistForToday(
		widget.tracker.id!,
	      );

	      await _loadItems();

	      _scheduleMidnightRefresh();
	    },
	  );
	}
	
	Future<void> _deleteItem(ChecklistItem item) async {
	  final shouldDelete = await showDialog<bool>(
	    context: context,
	    builder: (context) {
	      return AlertDialog(
		title: const Text('Delete Item'),
		content: Text(
		  'Delete "${item.title}"?',
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

	  if (shouldDelete != true) return;

	  await _database.deleteChecklistItem(item.id!);
	  await _loadItems();
	}
    
   Future<void> _addItem() async {
	  final controller = TextEditingController();

	  final result = await showDialog<String>(
	    context: context,
	    builder: (context) {
	      return AlertDialog(
		title: const Text('Add Checklist Item'),
		content: TextField(
		  controller: controller,
		  autofocus: true,
		  decoration: const InputDecoration(
		    labelText: 'Item',
		  ),
		),
		actions: [
		  TextButton(
		    onPressed: () => Navigator.pop(context),
		    child: const Text('Cancel'),
		  ),
		  FilledButton(
		    onPressed: () {
		      final text = controller.text.trim();

		      if (text.isNotEmpty) {
		        Navigator.pop(context, text);
		      }
		    },
		    child: const Text('Add'),
		  ),
		],
	      );
	    },
	  );

	  if (result == null) return;

	  await _database.createChecklistItem(
		  trackerId: widget.tracker.id!,
		  title: result,
		);

		await _loadItems();
	}
	
	int get _completedCount =>
	    _items.where((item) => item.isCompleted).length;

  @override
  Widget build(BuildContext context) {
    return TrackerDetailScaffold(
      tracker: widget.tracker,
      body: Padding(
	  padding: const EdgeInsets.all(16),
	  child: Column(
	    crossAxisAlignment: CrossAxisAlignment.stretch,
	    children: [

	      const Text(
		'Daily Progress',
		style: TextStyle(fontWeight: FontWeight.bold),
	      ),

	      const SizedBox(height: 8),

	      Text(
  		'$_completedCount / ${_items.length}',
		textAlign: TextAlign.center,
		style: Theme.of(context).textTheme.headlineMedium,
	      ),

	      const SizedBox(height: 12),

	      LinearProgressIndicator(
		  value: _items.isEmpty
		      ? 0
		      : _completedCount / _items.length,
		),

	      const SizedBox(height: 32),

	      const Text(
		"Today's Checklist",
		style: TextStyle(fontWeight: FontWeight.bold),
	      ),

	      const SizedBox(height: 12),

	      Expanded(
		  child: _items.isEmpty
		      ? const Center(
			  child: Text(
			    'No checklist items yet.',
			  ),
			)
		      : ListView.builder(
			  itemCount: _items.length,
			  itemBuilder: (context, index) {
			    return Column(
				  children: [

					  Row(
					    children: [

					      Checkbox(
						value: _items[index].isCompleted,
						activeColor: Theme.of(context).colorScheme.primary,
						onChanged: (value) async {
						  final updatedItem = ChecklistItem(
						    id: _items[index].id,
						    trackerId: _items[index].trackerId,
						    title: _items[index].title,
						    isCompleted: value ?? false,
						    date: _items[index].date,
						  );

						  await _database.updateChecklistItem(updatedItem);
						  await _loadItems();
						},
					      ),

					      Expanded(
						  child: Text(
						    _items[index].title,
						    style: TextStyle(
						      decoration: _items[index].isCompleted
							  ? TextDecoration.lineThrough
							  : null,
						      color: _items[index].isCompleted
							  ? Colors.grey
							  : null,
						    ),
						  ),
						),

					      IconButton(
						icon: const Icon(Icons.delete),
						onPressed: () => _deleteItem(_items[index]),
					      ),

					    ],
					  ),

					  const Divider(),

					],
				);
			  },
			),
		),

	      FilledButton.icon(
		onPressed: _addItem,
		icon: Icon(Icons.add),
		label: Text('Add Item'),
	      ),

	    ],
	  ),
	),
    );
  }
  @override
	void dispose() {
	  _midnightTimer?.cancel();
	  super.dispose();
	}
}
