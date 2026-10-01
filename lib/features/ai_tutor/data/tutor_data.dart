import '../models/chat_message.dart';

class TutorData {
  TutorData._();

  static const List<String> suggestedQuestions = [
    'Explain Flutter widgets',
    'How does navigation work?',
    'What is StatefulWidget?',
    'Give me a Flutter practice exercise',
  ];

  static const List<ChatMessage> welcomeMessages = [
    ChatMessage(
      id: 'welcome-1',
      text:
          'Hi Elias! 👋 I’m your AI Tutor. '
          'I can help you understand lessons, explain difficult concepts, '
          'and give you practice questions.',
      sender: MessageSender.ai,
      timestamp: DateTime(2026, 1, 1, 9, 0),
    ),
  ];

  static String responseFor(String question) {
    final normalizedQuestion = question.toLowerCase();

    if (normalizedQuestion.contains('widget')) {
      return 'In Flutter, everything you see on the screen is built from widgets. '
          'For example, Text displays text, Icon displays an icon, and '
          'Container can control layout and decoration.\n\n'
          'The two important widget types are StatelessWidget and StatefulWidget.';
    }

    if (normalizedQuestion.contains('navigation')) {
      return 'Flutter navigation allows users to move between screens.\n\n'
          'A common approach is Navigator.push() to open another screen '
          'and Navigator.pop() to return to the previous screen.';
    }

    if (normalizedQuestion.contains('stateful')) {
      return 'A StatefulWidget is useful when part of your interface can change '
          'while the application is running.\n\n'
          'For example, a counter that changes from 1 to 2 needs state. '
          'setState() tells Flutter that the UI needs to rebuild.';
    }

    if (normalizedQuestion.contains('practice')) {
      return 'Here is a practice exercise:\n\n'
          'Build a Flutter screen containing a title, an image, a description, '
          'and a button. When the button is pressed, display a SnackBar.\n\n'
          'Try building it yourself before looking for a solution.';
    }

    return 'That is a great question! Based on what you are learning, '
        'I would break the problem into smaller concepts and work through '
        'each one step by step.\n\n'
        'Try asking me about Flutter widgets, navigation, state management, '
        'or ask for a practice exercise.';
  }
}