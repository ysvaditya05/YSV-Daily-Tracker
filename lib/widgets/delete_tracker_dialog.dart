import 'package:flutter/material.dart';

import 'confirmation_dialog.dart';

Future<bool> showDeleteTrackerDialog(
  BuildContext context,
  String trackerName,
) async {
  return showConfirmationDialog(
    context: context,
    title: 'Delete Tracker',
    message: 'Are you sure you want to permanently delete "$trackerName"?',
    confirmLabel: 'Delete',
  );
}
