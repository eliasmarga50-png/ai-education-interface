import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../ai_tutor/data/tutor_data.dart';
import '../../ai_tutor/models/chat_conversation.dart';

/// Quick way into the AI Tutor. When there is a lesson to continue, the
/// suggestions are about that lesson.
class AiTutorShortcutCard extends StatelessWidget {
  /// Title of the lesson on the hero card, or null.
  final String? lessonTitle;
  final ChatConversation? lastConversation;
  final ValueChanged<String> onAsk;
  final VoidCallback onOpenChat;

  const AiTutorShortcutCard({
    super.key,
    required this.lessonTitle,
    required this.lastConversation,
    required this.onAsk,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final suggestions = lessonTitle != null
        ? const [
            'Explain this lesson simply',
            'Give me an example',
            'Quiz me on this lesson',
          ]
        : TutorData.suggestedQuestions.take(3).toList();

    final last = lastConversation;

    final subtitle = last != null
        ? 'Pick up where you left off: “${last.title}”'
        : lessonTitle != null
            ? 'Stuck on “$lessonTitle”? Ask away.'
            : 'Get help with any lesson, any time.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primaryColor,
                child: Icon(
                  Icons.smart_toy_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ask your AI Tutor',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final question in suggestions)
                ActionChip(
                  onPressed: () => onAsk(question),
                  avatar: const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  label: Text(question),
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 13,
                  ),
                  backgroundColor: theme.cardTheme.color ??
                      theme.colorScheme.surface,
                  side: BorderSide(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onOpenChat,
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: Text(last != null ? 'Continue chat' : 'Open chat'),
            ),
          ),
        ],
      ),
    );
  }
}