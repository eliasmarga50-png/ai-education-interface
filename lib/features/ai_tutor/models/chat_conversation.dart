



import 'chat_message.dart';
import 'tutor_context.dart';

/// One chat with the tutor. Mutable on purpose: [TutorController] appends
/// messages to it and notifies listeners.
class ChatConversation {
  static const String defaultTitle = 'New conversation';

  final String id;
  String title;

  /// Set when the chat is about one specific lesson.
  final TutorContext? lesson;

  final DateTime createdAt;
  DateTime updatedAt;
  final List<ChatMessage> messages;

  ChatConversation({
    required this.id,
    this.title = defaultTitle,
    this.lesson,
    required this.createdAt,
    required this.updatedAt,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];

  bool get isEmpty => messages.isEmpty;

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lesson': lesson?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((message) => message.toJson()).toList(),
    };
  }

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final lessonJson = json['lesson'];

    return ChatConversation(
      id: json['id'] as String,
      title: json['title'] as String,
      lesson: lessonJson == null
          ? null
          : TutorContext.fromJson(lessonJson as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      messages: (json['messages'] as List<dynamic>)
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}



