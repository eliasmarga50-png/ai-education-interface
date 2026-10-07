


import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/tutor_context.dart';
import 'mock_tutor_service.dart';
import 'tutor_service.dart';

/// Owns every AI Tutor conversation: history, sending, loading and error
/// state, clearing. Screens only read from it and call it.
///
/// Because the controller (not the screen) waits for the reply, an answer
/// still arrives and is saved if you leave the chat while it is thinking.
class TutorController extends ChangeNotifier {
  TutorController._();

  static final TutorController instance = TutorController._();

  /// Replace with an HTTP implementation when the Node.js API exists.
  TutorService service = MockTutorService();

  static const String _storageKey = 'tutor_conversations_v1';
  static const int _maxConversations = 30;

  final List<ChatConversation> _conversations = [];
  final Set<String> _responding = {};
  final Map<String, String> _errors = {};

  // Bumped when a conversation is cleared or deleted, so a reply that
  // arrives afterwards is thrown away instead of reappearing.
  final Map<String, int> _generations = {};

  /// Loads saved history. Call once before runApp.
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw != null) {
        final decoded = jsonDecode(raw) as List<dynamic>;

        _conversations
          ..clear()
          ..addAll(
            decoded.map(
              (item) => ChatConversation.fromJson(
                item as Map<String, dynamic>,
              ),
            ),
          );
      }
    } catch (error) {
      debugPrint('TUTOR → could not load history: $error');
      _conversations.clear();
    }

    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Reading
  // ---------------------------------------------------------------------

  /// Saved conversations with at least one message, newest first.
  List<ChatConversation> get conversations {
    final list = _conversations.where((c) => c.messages.isNotEmpty).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  bool contains(String conversationId) {
    return _conversations.any((c) => c.id == conversationId);
  }

  ChatConversation? latestForLesson(String lessonId) {
    for (final conversation in conversations) {
      if (conversation.lesson?.lessonId == lessonId) {
        return conversation;
      }
    }

    return null;
  }

  bool isResponding(String conversationId) {
    return _responding.contains(conversationId);
  }

  String? errorFor(String conversationId) {
    return _errors[conversationId];
  }

  // ---------------------------------------------------------------------
  // Conversations
  // ---------------------------------------------------------------------

  /// Creates a conversation that is only saved once the first message is sent,
  /// so opening the chat and leaving never leaves an empty entry in history.
  ChatConversation newConversation({TutorContext? lesson}) {
    final now = DateTime.now();

    return ChatConversation(
      id: 'chat-${now.microsecondsSinceEpoch}',
      lesson: lesson,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> sendMessage(ChatConversation conversation, String text) async {
    final question = text.trim();

    if (question.isEmpty || isResponding(conversation.id)) {
      return;
    }

    _register(conversation);

    final now = DateTime.now();

    conversation.messages.add(
      ChatMessage(
        id: 'user-${now.microsecondsSinceEpoch}',
        text: question,
        sender: MessageSender.user,
        timestamp: now,
      ),
    );

    conversation.updatedAt = now;

    if (conversation.messages.where((m) => m.isUser).length == 1) {
      conversation.title = _titleFrom(question);
    }

    _errors.remove(conversation.id);
    notifyListeners();
    unawaited(_save());

    await _requestReply(conversation);
  }

  /// Asks again after a failure. The user's message is already in the chat.
  Future<void> retry(ChatConversation conversation) async {
    final last = conversation.lastMessage;

    if (last == null || !last.isUser || isResponding(conversation.id)) {
      return;
    }

    _errors.remove(conversation.id);
    notifyListeners();

    await _requestReply(conversation);
  }

  /// Empties the messages but keeps the conversation (and its lesson).
  void clearConversation(ChatConversation conversation) {
    _invalidatePending(conversation.id);

    conversation.messages.clear();
    conversation.title = ChatConversation.defaultTitle;

    notifyListeners();
    unawaited(_save());
  }

  void deleteConversation(ChatConversation conversation) {
    _invalidatePending(conversation.id);
    _conversations.removeWhere((c) => c.id == conversation.id);

    notifyListeners();
    unawaited(_save());
  }

  /// Puts a deleted conversation back (used by the "Undo" snackbar).
  void restoreConversation(ChatConversation conversation) {
    _register(conversation);

    notifyListeners();
    unawaited(_save());
  }

  void clearAllHistory() {
    for (final conversation in _conversations) {
      _invalidatePending(conversation.id);
    }

    _conversations.clear();

    notifyListeners();
    unawaited(_save());
  }

  // ---------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------

  Future<void> _requestReply(ChatConversation conversation) async {
    final id = conversation.id;
    final generation = _generations[id] ?? 0;

    final question = conversation.messages.last.text;
    final history = conversation.messages.sublist(
      0,
      conversation.messages.length - 1,
    );

    _responding.add(id);
    notifyListeners();

    try {
      final reply = await service.getReply(
        question: question,
        history: history,
        lesson: conversation.lesson,
      );

      if ((_generations[id] ?? 0) != generation) {
        return;
      }

      final now = DateTime.now();

      conversation.messages.add(
        ChatMessage(
          id: 'ai-${now.microsecondsSinceEpoch}',
          text: reply,
          sender: MessageSender.ai,
          timestamp: now,
        ),
      );

      conversation.updatedAt = now;
    } on TutorServiceException catch (error) {
      if ((_generations[id] ?? 0) == generation) {
        _errors[id] = error.message;
      }
    } catch (error) {
      debugPrint('TUTOR → unexpected error: $error');

      if ((_generations[id] ?? 0) == generation) {
        _errors[id] = 'Something went wrong. Please try again.';
      }
    } finally {
      if ((_generations[id] ?? 0) == generation) {
        _responding.remove(id);
        notifyListeners();
        unawaited(_save());
      }
    }
  }

  void _invalidatePending(String conversationId) {
    _generations[conversationId] = (_generations[conversationId] ?? 0) + 1;
    _responding.remove(conversationId);
    _errors.remove(conversationId);
  }

  void _register(ChatConversation conversation) {
    if (_conversations.any((c) => c.id == conversation.id)) {
      return;
    }

    _conversations.add(conversation);

    if (_conversations.length > _maxConversations) {
      _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _conversations.removeRange(_maxConversations, _conversations.length);
    }
  }

  String _titleFrom(String question) {
    final singleLine = question.replaceAll('\n', ' ').trim();

    if (singleLine.length <= 48) {
      return singleLine;
    }

    return '${singleLine.substring(0, 45)}...';
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final encoded = jsonEncode(
        conversations.map((c) => c.toJson()).toList(),
      );

      await prefs.setString(_storageKey, encoded);
    } catch (error) {
      debugPrint('TUTOR → could not save history: $error');
    }
  }
}



