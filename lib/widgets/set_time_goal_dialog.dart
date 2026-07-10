import 'package:flutter/material.dart';

Future<bool> showSetTimeGoalDialog({
  required BuildContext context,
  required Duration? initialGoal,
  required Future<void> Function(Duration goal) onSave,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return _SetTimeGoalDialog(initialGoal: initialGoal, onSave: onSave);
    },
  ).then((saved) => saved ?? false);
}

class _SetTimeGoalDialog extends StatefulWidget {
  const _SetTimeGoalDialog({required this.initialGoal, required this.onSave});

  final Duration? initialGoal;
  final Future<void> Function(Duration goal) onSave;

  @override
  State<_SetTimeGoalDialog> createState() => _SetTimeGoalDialogState();
}

class _SetTimeGoalDialogState extends State<_SetTimeGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hoursController;
  late final TextEditingController _minutesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initialGoal = widget.initialGoal;
    _hoursController = TextEditingController(
      text: initialGoal == null ? '' : initialGoal.inHours.toString(),
    );
    _minutesController = TextEditingController(
      text: initialGoal == null
          ? ''
          : initialGoal.inMinutes.remainder(60).toString(),
    );
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  int? _readNumber(String? value, {int? maximum}) {
    if (value == null || value.isEmpty) {
      return 0;
    }
    final number = int.tryParse(value);
    if (number == null || number < 0 || maximum != null && number > maximum) {
      return null;
    }
    return number;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final hours = _readNumber(_hoursController.text)!;
    final minutes = _readNumber(_minutesController.text, maximum: 59)!;
    final goal = Duration(hours: hours, minutes: minutes);
    if (goal == Duration.zero) {
      setState(() {});
      _formKey.currentState!.validate();
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSave(goal);
      if (mounted) {
        Navigator.of(context).pop(true);
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
    return AlertDialog(
      title: const Text('Daily Goal'),
      content: Form(
        key: _formKey,
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _hoursController,
                decoration: const InputDecoration(labelText: 'Hours'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_readNumber(value) == null) {
                    return 'Enter a whole number.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _minutesController,
                decoration: const InputDecoration(labelText: 'Minutes'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_readNumber(value, maximum: 59) == null) {
                    return 'Enter 0–59.';
                  }
                  if (_readNumber(_hoursController.text) == 0 &&
                      _readNumber(value, maximum: 59) == 0) {
                    return 'Enter a goal.';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
