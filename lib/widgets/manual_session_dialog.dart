import 'package:flutter/material.dart';

Future<Duration?> showManualSessionDialog(BuildContext context) {
  return showDialog<Duration>(
    context: context,
    builder: (context) => const _ManualSessionDialog(),
  );
}

class _ManualSessionDialog extends StatefulWidget {
  const _ManualSessionDialog();

  @override
  State<_ManualSessionDialog> createState() => _ManualSessionDialogState();
}

class _ManualSessionDialogState extends State<_ManualSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  int? _parseNonNegativeInteger(String? value, {int? maximum}) {
    if (value == null || value.isEmpty) {
      return 0;
    }
    final number = int.tryParse(value);
    if (number == null || number < 0 || maximum != null && number > maximum) {
      return null;
    }
    return number;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final hours = _parseNonNegativeInteger(_hoursController.text)!;
    final minutes = _parseNonNegativeInteger(
      _minutesController.text,
      maximum: 59,
    )!;
    Navigator.of(context).pop(Duration(hours: hours, minutes: minutes));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Manual Session'),
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
                  if (_parseNonNegativeInteger(value) == null) {
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
                  if (_parseNonNegativeInteger(value, maximum: 59) == null) {
                    return 'Enter 0–59.';
                  }
                  if (_parseNonNegativeInteger(_hoursController.text) == 0 &&
                      _parseNonNegativeInteger(value, maximum: 59) == 0) {
                    return 'Enter a duration.';
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
