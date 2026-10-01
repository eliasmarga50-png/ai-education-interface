



import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/tutor_data.dart';
import 'chat_screen.dart';

class AITutorScreen extends StatelessWidget {
  const AITutorScreen({super.key});

  void _openChat(
    BuildContext context, {
    String? question,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          initialQuestion: question,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tutor'),
        actions: [
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

          const _CapabilityCard(
            icon: Icons.quiz_outlined,
            title: 'Practice with questions',
            description:
                'Test your understanding with practice questions.',
          ),

          const SizedBox(height: 12),

          const _CapabilityCard(
            icon: Icons.lightbulb_outline,
            title: 'Learn step by step',
            description:
                'Work through challenging problems with guidance.',
          ),

          const SizedBox(height: 28),

          _RecentConversationCard(
            onTap: () {
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

  const _CapabilityCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
          ],
        ),
      ),
    );
  }
}

class _RecentConversationCard
    extends StatelessWidget {
  final VoidCallback onTap;

  const _RecentConversationCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                child: Icon(
                  Icons.chat_bubble_outline,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue learning',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Open your AI Tutor conversation',
                      style: TextStyle(
                        color:
                            AppTheme
                                .textSecondaryColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


