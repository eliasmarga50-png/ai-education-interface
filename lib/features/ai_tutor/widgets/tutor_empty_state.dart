import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/tutor_context.dart';
import 'suggested_question.dart';

/// What a chat shows before the first message.
class TutorEmptyState extends StatelessWidget {
  final TutorContext? lesson;
  final List<String> suggestions;
  final ValueChanged<String> onSuggestionTap;

  const TutorEmptyState({
    super.key,
    required this.lesson,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lessonContext = lesson;

    final title = lessonContext == null
        ? 'Hi! I’m your AI Tutor 👋'
        : 'Let’s explore this lesson';

    final subtitle = lessonContext == null
        ? 'Ask about your lessons, get explanations, or practice what you '
            'have learned.'
        : '“${lessonContext.lessonTitle}” from ${lessonContext.courseTitle}. '
            'Ask me anything about it.';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 32,
              backgroundColor: AppTheme.primaryColor,
              child: Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final question in suggestions)
                  SuggestedQuestion(
                    question: question,
                    onTap: () => onSuggestionTap(question),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}