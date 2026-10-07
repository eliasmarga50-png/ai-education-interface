import 'package:flutter/material.dart';

import '../utils/chat_time.dart';

/// "Today" / "Yesterday" / "Monday, Mar 3" pill between messages.
class ChatDateSeparator extends StatelessWidget {
  final DateTime date;

  const ChatDateSeparator({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          ChatTime.dayLabel(date),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}