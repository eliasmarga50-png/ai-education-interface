


import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/tutor_data.dart';
import '../models/chat_conversation.dart';
import '../models/tutor_context.dart';
import '../services/tutor_controller.dart';
import '../utils/chat_time.dart';
import '../widgets/chat_date_separator.dart';
import '../widgets/chat_error_banner.dart';
import '../widgets/chat_input.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/suggested_question.dart';
import '../widgets/tutor_empty_state.dart';
import '../widgets/typing_indicator.dart';
import 'chat_history_screen.dart';

enum _ChatMenuAction {
  history,
  clear,
}

class ChatScreen extends StatefulWidget {
  /// Resume this conversation. When null a new one is started.
  final ChatConversation? conversation;

  /// Makes a new conversation about one lesson.
  final TutorContext? lesson;

  /// Sent automatically as the first message.
  final String? initialQuestion;

  const ChatScreen({
    super.key,
    this.conversation,
    this.lesson,
    this.initialQuestion,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  TutorController get _tutor => TutorController.instance;

  late ChatConversation _conversation;

  @override
  void initState() {
    super.initState();

    _conversation = widget.conversation ??
        _tutor.newConversation(lesson: widget.lesson);

    _tutor.addListener(_scrollToBottom);

    final initialQuestion = widget.initialQuestion;

    if (initialQuestion != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _send(initialQuestion);
      });
    } else if (_conversation.messages.isNotEmpty) {
      _scrollToBottom(animate: false);
    }
  }

  @override
  void dispose() {
    _tutor.removeListener(_scrollToBottom);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final message = text ?? _controller.text;

    if (message.trim().isEmpty || _tutor.isResponding(_conversation.id)) {
      return;
    }

    _controller.clear();
    _tutor.sendMessage(_conversation, message);
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      final target = _scrollController.position.maxScrollExtent;

      if (animate) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  void _newConversation() {
    if (_conversation.isEmpty) {
      return;
    }

    _controller.clear();

    setState(() {
      _conversation = _tutor.newConversation(lesson: _conversation.lesson);
    });
  }

  Future<void> _openHistory() async {
    final selected = await Navigator.push<ChatConversation>(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatHistoryScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      if (selected != null) {
        _conversation = selected;
      } else if (!_conversation.isEmpty && !_tutor.contains(_conversation.id)) {
        // The chat on screen was deleted from the history screen.
        _conversation = _tutor.newConversation(lesson: _conversation.lesson);
      }
    });

    _scrollToBottom(animate: false);
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear conversation?'),
          content: const Text(
            'All messages in this conversation will be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _tutor.clearConversation(_conversation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _tutor,
      builder: (context, _) {
        final messages = _conversation.messages;
        final lesson = _conversation.lesson;
        final isResponding = _tutor.isResponding(_conversation.id);
        final error = _tutor.errorFor(_conversation.id);

        final showFollowUps =
            messages.isNotEmpty && !isResponding && error == null;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(
                    Icons.smart_toy_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Tutor',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isResponding
                            ? 'Typing...'
                            : (lesson?.lessonTitle ??
                                'Your learning assistant'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'New conversation',
                onPressed: messages.isEmpty ? null : _newConversation,
                icon: const Icon(Icons.add_comment_outlined),
              ),
              PopupMenuButton<_ChatMenuAction>(
                tooltip: 'More',
                onSelected: (action) {
                  switch (action) {
                    case _ChatMenuAction.history:
                      _openHistory();
                    case _ChatMenuAction.clear:
                      _confirmClear();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _ChatMenuAction.history,
                    child: Row(
                      children: [
                        Icon(Icons.history, size: 20),
                        SizedBox(width: 12),
                        Text('Chat history'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _ChatMenuAction.clear,
                    enabled: messages.isNotEmpty,
                    child: const Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20),
                        SizedBox(width: 12),
                        Text('Clear conversation'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              if (lesson != null) _LessonBanner(lesson: lesson),
              Expanded(
                child: messages.isEmpty && !isResponding
                    ? TutorEmptyState(
                        lesson: lesson,
                        suggestions: lesson == null
                            ? TutorData.suggestedQuestions
                            : TutorData.lessonSuggestedQuestions(lesson),
                        onSuggestionTap: _send,
                      )
                    : ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        children: [
                          for (var i = 0; i < messages.length; i++) ...[
                            if (i == 0 ||
                                !ChatTime.isSameDay(
                                  messages[i - 1].timestamp,
                                  messages[i].timestamp,
                                ))
                              ChatDateSeparator(date: messages[i].timestamp),
                            ChatMessageBubble(
                              key: ValueKey(messages[i].id),
                              message: messages[i],
                            ),
                          ],
                          if (isResponding) const TypingIndicator(),
                          if (error != null && !isResponding)
                            ChatErrorBanner(
                              message: error,
                              onRetry: () => _tutor.retry(_conversation),
                            ),
                        ],
                      ),
              ),
              if (showFollowUps)
                _FollowUpRow(
                  questions: TutorData.followUpQuestions(lesson),
                  onTap: _send,
                ),
              ChatInput(
                controller: _controller,
                onSend: _send,
                isBusy: isResponding,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LessonBanner extends StatelessWidget {
  final TutorContext lesson;

  const _LessonBanner({
    required this.lesson,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${lesson.lessonTitle} · ${lesson.courseTitle}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowUpRow extends StatelessWidget {
  final List<String> questions;
  final ValueChanged<String> onTap;

  const _FollowUpRow({
    required this.questions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: questions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final question = questions[index];

          return Center(
            child: SuggestedQuestion(
              question: question,
              onTap: () => onTap(question),
            ),
          );
        },
      ),
    );
  }
}