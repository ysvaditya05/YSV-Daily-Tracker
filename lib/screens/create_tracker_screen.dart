import 'package:flutter/material.dart';

import '../services/tracker_database.dart';

class CreateTrackerScreen extends StatefulWidget {
  const CreateTrackerScreen({super.key});

  @override
  State<CreateTrackerScreen> createState() => _CreateTrackerScreenState();
}

class _CreateTrackerScreenState extends State<CreateTrackerScreen> {
  static const _trackerTypes = ['Time', 'Number', 'Checklist', 'List'];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _trackerType = _trackerTypes.first;
  bool _isSaving = false;
  String? _duplicateNameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createTracker() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await TrackerDatabase.instance.createTracker(
        name: _nameController.text.trim(),
        type: _trackerType,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on DuplicateTrackerNameException {
      if (mounted) {
        setState(() {
          _duplicateNameError = 'Tracker already exists.';
        });
        _formKey.currentState!.validate();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tracker Name'),
                onChanged: (_) {
                  if (_duplicateNameError != null) {
                    setState(() {
                      _duplicateNameError = null;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a tracker name.';
                  }
                  if (_duplicateNameError != null) {
                    return _duplicateNameError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _trackerType,
                decoration: const InputDecoration(labelText: 'Tracker Type'),
                items: _trackerTypes
                    .map(
                      (type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      ),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (type) {
                        if (type != null) {
                          setState(() {
                            _trackerType = type;
                          });
                        }
                      },
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isSaving ? null : _createTracker,
                    child: const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
