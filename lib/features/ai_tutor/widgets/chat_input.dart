



import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          12,
          8,
          12,
          10,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction:
                    TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Ask your AI Tutor...',
                  prefixIcon: const Icon(
                    Icons.chat_bubble_outline,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      controller.clear();
                    },
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) {
                  onSend();
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: IconButton(
                onPressed: onSend,
                color: Colors.white,
                tooltip: 'Send',
                icon: const Icon(
                  Icons.arrow_upward,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


