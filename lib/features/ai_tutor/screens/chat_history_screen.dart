import 'package:flutter/material.dart';

import '../models/chat_conversation.dart';
import '../services/tutor_controller.dart';
import '../utils/chat_time.dart';

/// Past conversations. Tapping one pops this screen with that conversation,
/// and the caller opens it. "Start a conversation" pops with a new, empty one.
class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({super.key});

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear all history?'),
          content: const Text(
            'Every conversation with the AI Tutor will be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      TutorController.instance.clearAllHistory();
    }
  }

  void _delete(BuildContext context, ChatConversation conversation) {
    final controller = TutorController.instance;

    controller.deleteConversation(conversation);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Conversation deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => controller.restoreConversation(conversation),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final controller = TutorController.instance;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final conversations = controller.conversations;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chat History'),
            actions: [
              IconButton(
                tooltip: 'Clear all',
                onPressed: conversations.isEmpty
                    ? null
                    : () => _confirmClearAll(context),
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
            ],
          ),
          body: conversations.isEmpty
              ? _EmptyHistory(
                  onStart: () {
                    Navigator.pop(context, controller.newConversation());
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];

                    return Dismissible(
                      key: ValueKey(conversation.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _delete(context, conversation),
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.only(right: 20),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                      child: _ConversationTile(
                        conversation: conversation,
                        onTap: () => Navigator.pop(context, conversation),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lesson = conversation.lesson;
    final last = conversation.lastMessage;

    final preview = last == null
        ? ''
        : '${last.isUser ? 'You: ' : ''}'
            '${last.text.replaceAll('\n', ' ')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        isThreeLine: lesson != null,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(
            lesson == null
                ? Icons.chat_bubble_outline
                : Icons.menu_book_outlined,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          conversation.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lesson != null)
              Text(
                'Lesson: ${lesson.lessonTitle}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            Text(
              preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Text(
          ChatTime.relative(conversation.updatedAt),
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final VoidCallback onStart;

  const _EmptyHistory({
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Your chats with the AI Tutor will show up here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Start a conversation'),
            ),
          ],
        ),
      ),
    );
  }
}