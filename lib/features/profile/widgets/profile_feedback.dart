import 'package:flutter/material.dart';

/// One way to tell the user how a Profile action went.
///
/// A failure can offer "Try again" ([onRetry]), so a dropped connection
/// doesn't make the user retype anything.
void showProfileSnack(
  BuildContext context,
  String message, {
  VoidCallback? onRetry,
  bool isError = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final scheme = Theme.of(context).colorScheme;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? scheme.error : null,
        action: onRetry == null
            ? null
            : SnackBarAction(
                label: 'Try again',
                textColor: isError ? scheme.onError : null,
                onPressed: onRetry,
              ),
      ),
    );
}