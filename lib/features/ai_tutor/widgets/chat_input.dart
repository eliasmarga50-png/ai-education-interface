



import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  /// True while the tutor is answering; sending is disabled.
  final bool isBusy;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final canSend = value.text.trim().isNotEmpty && !isBusy;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Ask your AI Tutor...',
                      prefixIcon: const Icon(Icons.chat_bubble_outline),
                      suffixIcon: value.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear',
                              onPressed: controller.clear,
                              icon: const Icon(Icons.close, size: 18),
                            ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: canSend
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    onPressed: canSend ? onSend : null,
                    color: Colors.white,
                    disabledColor: Colors.white70,
                    tooltip: 'Send',
                    icon: isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.arrow_upward),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}