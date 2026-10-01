import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class SuggestedQuestion extends StatelessWidget {
  final String question;
  final VoidCallback onTap;

  const SuggestedQuestion({
    super.key,
    required this.question,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: const Icon(
        Icons.auto_awesome,
        size: 16,
        color: AppTheme.primaryColor,
      ),
      label: Text(question),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      side: BorderSide(
        color: AppTheme.primaryColor.withValues(
          alpha: 0.15,
        ),
      ),
      backgroundColor:
          AppTheme.primaryColor.withValues(
        alpha: 0.05,
      ),
      labelStyle: const TextStyle(
        color: AppTheme.textPrimaryColor,
      ),
    );
  }
}