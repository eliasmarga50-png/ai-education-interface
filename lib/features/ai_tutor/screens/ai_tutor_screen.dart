import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../quizzes/screens/quiz_list_screen.dart';
import '../data/tutor_data.dart';
import '../models/chat_conversation.dart';
import '../services/tutor_controller.dart';
import '../utils/chat_time.dart';
import 'chat_history_screen.dart';
import 'chat_screen.dart';

class AITutorScreen extends StatelessWidget {
  const AITutorScreen({super.key});

  void _openChat(
    BuildContext context, {
    String? question,
    ChatConversation? conversation,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          initialQuestion: question,
          conversation: conversation,
        ),
      ),
    );
  }

  Future<void> _openHistory(BuildContext context) async {
    final selected = await Navigator.push<ChatConversation>(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatHistoryScreen(),
      ),
    );

    if (selected == null || !context.mounted) {
      return;
    }

    _openChat(context, conversation: selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tutor'),
        actions: [
          IconButton(
            tooltip: 'Chat history',
            onPressed: () {
              _openHistory(context);
            },
            icon: const Icon(
              Icons.history,
            ),
          ),
          IconButton(
            tooltip: 'Chat',
            onPressed: () {
              _openChat(context);
            },
            icon: const Icon(
              Icons.chat_outlined,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          30,
        ),
        children: [
          _WelcomeCard(
            onStartChat: () {
              _openChat(context);
            },
          ),

          const SizedBox(height: 28),

          Text(
            'What can I help you with?',
            style: Theme.of(context)
                .textTheme
                .titleLarge,
          ),

          const SizedBox(height: 12),

          Text(
            'Ask questions about your lessons, '
            'get explanations, or practice what '
            'you have learned.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
                  height: 1.5,
                ),
          ),

          const SizedBox(height: 18),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                TutorData.suggestedQuestions
                    .map(
                      (question) => ActionChip(
                        onPressed: () {
                          _openChat(
                            context,
                            question: question,
                          );
                        },
                        avatar: const Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color:
                              AppTheme.primaryColor,
                        ),
                        label: Text(question),
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    )
                    .toList(),
          ),

          const SizedBox(height: 32),

          Text(
            'Tutor capabilities',
            style: Theme.of(context)
                .textTheme
                .titleLarge,
          ),

          const SizedBox(height: 14),

          const _CapabilityCard(
            icon: Icons.school_outlined,
            title: 'Explain concepts',
            description:
                'Get simple explanations for difficult topics.',
          ),

          const SizedBox(height: 12),

          _CapabilityCard(
            icon: Icons.quiz_outlined,
            title: 'Practice with questions',
            description:
                'Test your understanding with practice questions.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuizListScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          const _CapabilityCard(
            icon: Icons.lightbulb_outline,
            title: 'Learn step by step',
            description:
                'Work through challenging problems with guidance.',
          ),

          const SizedBox(height: 28),

          _RecentConversations(
            onOpen: (conversation) {
              _openChat(context, conversation: conversation);
            },
            onViewAll: () {
              _openHistory(context);
            },
            onStartNew: () {
              _openChat(context);
            },
          ),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final VoidCallback onStartChat;

  const _WelcomeCard({
    required this.onStartChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.15,
              ),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Learn with your AI Tutor',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Ask questions, understand difficult '
            'concepts, and practice your skills '
            'with personalized guidance.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: onStartChat,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor:
                  AppTheme.primaryColor,
            ),
            icon: const Icon(
              Icons.chat_outlined,
            ),
            label: const Text(
              'Start a Conversation',
            ),
          ),
        ],
      ),
    );
  }
}

class _CapabilityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  /// When set, the card is tappable and shows a chevron.
  final VoidCallback? onTap;

  const _CapabilityCard({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color:
                    AppTheme.primaryColor.withValues(
                  alpha: 0.08,
                ),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),

            if (onTap != null) const Icon(Icons.chevron_right),
          ],
        ),
      ),
      ),
    );
  }
}
class _RecentConversations extends StatelessWidget {
  final ValueChanged<ChatConversation> onOpen;
  final VoidCallback onViewAll;
  final VoidCallback onStartNew;

  const _RecentConversations({
    required this.onOpen,
    required this.onViewAll,
    required this.onStartNew,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: TutorController.instance,
      builder: (context, child) {
        final recent = TutorController.instance.conversations.take(3).toList();

        if (recent.isEmpty) {
          return Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              onTap: onStartNew,
              leading: const CircleAvatar(
                child: Icon(Icons.chat_bubble_outline),
              ),
              title: const Text(
                'Start your first conversation',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Ask your AI Tutor anything'),
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent conversations',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final conversation in recent)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  onTap: () => onOpen(conversation),
                  leading: CircleAvatar(
                    child: Icon(
                      conversation.lesson == null
                          ? Icons.chat_bubble_outline
                          : Icons.menu_book_outlined,
                    ),
                  ),
                  title: Text(
                    conversation.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    conversation.lesson?.lessonTitle ?? 'General chat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    ChatTime.relative(conversation.updatedAt),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}