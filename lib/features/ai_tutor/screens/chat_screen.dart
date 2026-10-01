


import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/tutor_data.dart';
import '../models/chat_message.dart';
import '../widgets/chat_input.dart';
import '../widgets/chat_message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String? initialQuestion;

  const ChatScreen({
    super.key,
    this.initialQuestion,
  });

  @override
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  late final List<ChatMessage> _messages;

  bool _isTyping = false;

  @override
  void initState() {
    super.initState();

    _messages = [
      ...TutorData.welcomeMessages,
    ];

    if (widget.initialQuestion != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          _controller.text =
              widget.initialQuestion!;
          _sendMessage();
        },
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();

    if (text.isEmpty || _isTyping) {
      return;
    }

    final userMessage = ChatMessage(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      text: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _controller.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    Future.delayed(
      const Duration(milliseconds: 900),
      () {
        if (!mounted) {
          return;
        }

        final aiMessage = ChatMessage(
          id: 'ai-${DateTime.now().microsecondsSinceEpoch}',
          text: TutorData.responseFor(text),
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        );

        setState(() {
          _messages.add(aiMessage);
          _isTyping = false;
        });

        _scrollToBottom();
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!_scrollController.hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration:
              const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  AppTheme.primaryColor,
              child: Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Tutor',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Your learning assistant',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'New conversation',
            onPressed: () {
              setState(() {
                _messages
                  ..clear()
                  ..addAll(
                    TutorData.welcomeMessages,
                  );
              });

              _scrollToBottom();
            },
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                16,
                20,
                16,
                12,
              ),
              itemCount:
                  _messages.length +
                  (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const _TypingIndicator();
                }

                return ChatMessageBubble(
                  message: _messages[index],
                );
              },
            ),
          ),
          ChatInput(
            controller: _controller,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 14,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'AI Tutor is thinking...',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


