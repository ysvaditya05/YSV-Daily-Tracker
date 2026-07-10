import 'package:flutter/material.dart';

import 'confirmation_dialog.dart';

Future<bool> showDeleteSessionDialog(BuildContext context) {
  return showConfirmationDialog(
    context: context,
    title: 'Delete Session',
    message: 'Are you sure you want to permanently delete this session?',
    confirmLabel: 'Delete',
  );
}
