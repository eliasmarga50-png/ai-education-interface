import '../models/chat_message.dart';
import '../models/tutor_context.dart';

class TutorData {
  TutorData._();

  static const List<String> suggestedQuestions = [
    'Explain Flutter widgets',
    'How does navigation work?',
    'What is StatefulWidget?',
    'Give me a Flutter practice exercise',
  ];

  /// Starter chips for a chat about one lesson.
  static List<String> lessonSuggestedQuestions(TutorContext lesson) {
    return const [
      'Explain this lesson simply',
      'Give me an example',
      'Summarize the key points',
      'Quiz me on this lesson',
    ];
  }

  /// Quick follow-ups shown above the input once a chat has started.
  static List<String> followUpQuestions(TutorContext? lesson) {
    if (lesson != null) {
      return const [
        'Give me an example',
        'Summarize the key points',
        'Quiz me on this lesson',
        'Why does this matter?',
      ];
    }

    return const [
      'Explain it more simply',
      'Give me a practice exercise',
    ];
  }

  /// No longer used by ChatScreen (it now shows an empty state instead).
  /// Safe to delete.
  static final List<ChatMessage> welcomeMessages = [
    ChatMessage(
      id: 'welcome-1',
      text:
          'Hi! 👋 I’m your AI Tutor. '
          'I can help you understand lessons, explain difficult concepts, '
          'and give you practice questions.',
      sender: MessageSender.ai,
      timestamp: DateTime(2026, 1, 1, 9, 0),
    ),
  ];

  static String lessonExample(TutorContext lesson) {
    return _lessonExamples[lesson.lessonId] ??
        'Try applying “${lesson.lessonTitle}” to a tiny example of your own, '
            'then ask me to check it.';
  }

  static String responseFor(String question) {
    final text = question.toLowerCase();

    // Topic answers for the other courses.
    if (text.contains('python') ||
        text.contains('variable') ||
        text.contains('loop')) {
      return 'In Python, a variable is a name that points to a value, '
          'like age = 20. Loops such as for and while repeat code, and '
          'if statements choose between paths.\n\n'
          'Try writing a loop that prints the numbers 1 to 5.';
    }

    if (text.contains('html') || text.contains('css')) {
      return 'HTML gives a web page its structure (headings, paragraphs, '
          'links) and CSS controls how it looks (colors, spacing, layout).\n\n'
          'A good first exercise: build a page with a heading, a paragraph '
          'and a link, then style it with CSS.';
    }

    if (text.contains('machine learning') ||
        text.contains('training data') ||
        text.contains('model')) {
      return 'Machine learning lets a system learn patterns from data '
          'instead of following hand-written rules.\n\n'
          'A model is trained on examples (the training data), then used '
          'to make predictions on new data. Better data usually means a '
          'better model.';
    }

    if (text.contains('ui/ux') ||
        text.contains('user interface') ||
        text.contains('user experience') ||
        text.contains('design') ||
        text.contains('color')) {
      return 'UI is how a product looks; UX is how it feels to use. '
          'Good design uses clear hierarchy, readable typography and enough '
          'color contrast so people can finish their task easily.';
    }

    // Flutter answers. "stateful" must be checked before "widget", because
    // "statefulwidget" contains the word "widget".
    if (text.contains('stateful')) {
      return 'A StatefulWidget is useful when part of your interface can change '
          'while the application is running.\n\n'
          'For example, a counter that changes from 1 to 2 needs state. '
          'setState() tells Flutter that the UI needs to rebuild.';
    }

    if (text.contains('widget')) {
      return 'In Flutter, everything you see on the screen is built from widgets. '
          'For example, Text displays text, Icon displays an icon, and '
          'Container can control layout and decoration.\n\n'
          'The two important widget types are StatelessWidget and StatefulWidget.';
    }

    if (text.contains('navigation')) {
      return 'Flutter navigation allows users to move between screens.\n\n'
          'A common approach is Navigator.push() to open another screen '
          'and Navigator.pop() to return to the previous screen.';
    }

    if (text.contains('simply') || text.contains('simpler')) {
      return 'Think of it like building with blocks: each small piece does one '
          'job, and you combine pieces to make something bigger.\n\n'
          'Tell me which part felt confusing and I will explain just that part.';
    }

    if (text.contains('practice')) {
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

  static const Map<String, String> _lessonExamples = {
    'flutter-lesson-1':
        "Here is the smallest possible Flutter app:\n\n"
        "void main() {\n"
        "  runApp(const MaterialApp(home: Text('Hello Flutter')));\n"
        "}\n\n"
        "runApp() takes a widget and makes it the root of your app. "
        "Everything else you build sits inside that root widget.",
    'flutter-lesson-2':
        "A simple widget that never changes:\n\n"
        "class Greeting extends StatelessWidget {\n"
        "  const Greeting({super.key});\n\n"
        "  @override\n"
        "  Widget build(BuildContext context) {\n"
        "    return const Text('Hello!');\n"
        "  }\n"
        "}\n\n"
        "build() describes what the widget looks like. Use a StatefulWidget "
        "instead when the UI needs to change.",
    'flutter-lesson-3':
        "A basic screen:\n\n"
        "Scaffold(\n"
        "  appBar: AppBar(title: const Text('Home')),\n"
        "  body: const Center(child: Text('Welcome')),\n"
        ")\n\n"
        "Scaffold gives the page its structure, AppBar adds the title bar, "
        "and Center places the Text in the middle.",
    'flutter-lesson-4':
        "A title above a row of two items:\n\n"
        "Column(\n"
        "  children: [\n"
        "    const Text('Rating'),\n"
        "    Row(\n"
        "      children: [\n"
        "        const Icon(Icons.star),\n"
        "        const Text('4.9'),\n"
        "      ],\n"
        "    ),\n"
        "  ],\n"
        ")\n\n"
        "Column stacks children vertically and Row places them side by side.",
    'flutter-lesson-5':
        "Let one child take the leftover space:\n\n"
        "Row(\n"
        "  children: [\n"
        "    const Icon(Icons.menu),\n"
        "    Expanded(child: Text('I fill the remaining width')),\n"
        "  ],\n"
        ")\n\n"
        "To react to screen size, read MediaQuery.sizeOf(context).width and "
        "choose a layout.",
    'flutter-lesson-6':
        "A scrollable list built on demand:\n\n"
        "ListView.builder(\n"
        "  itemCount: titles.length,\n"
        "  itemBuilder: (context, index) {\n"
        "    return Card(\n"
        "      child: ListTile(title: Text(titles[index])),\n"
        "    );\n"
        "  },\n"
        ")\n\n"
        "Items are created only when they scroll into view, which keeps long "
        "lists fast.",
    'flutter-lesson-7':
        "Open a screen, then go back:\n\n"
        "Navigator.push(\n"
        "  context,\n"
        "  MaterialPageRoute(\n"
        "    builder: (context) => const DetailScreen(),\n"
        "  ),\n"
        ");\n\n"
        "// on DetailScreen:\n"
        "Navigator.pop(context);\n\n"
        "push adds a screen on top of the stack and pop removes it.",
    'flutter-lesson-8':
        "A counter that changes over time:\n\n"
        "int _count = 0;\n\n"
        "ElevatedButton(\n"
        "  onPressed: () {\n"
        "    setState(() {\n"
        "      _count++;\n"
        "    });\n"
        "  },\n"
        "  child: Text('Tapped ' + _count.toString() + ' times'),\n"
        ")\n\n"
        "setState() runs your change and asks Flutter to rebuild the widget.",
    'python-lesson-1':
        "print('Hello, Python!')\n\n"
        "name = input('Your name? ')\n"
        "print('Nice to meet you, ' + name)\n\n"
        "Python reads almost like English, which is why it is a popular "
        "first language.",
    'python-lesson-2':
        "name = 'Ada'       # str\n"
        "age = 36           # int\n"
        "height = 1.65      # float\n"
        "is_student = True  # bool\n\n"
        "print(type(age))   # shows the data type\n\n"
        "A variable is a name that points to a value, and every value has "
        "a type.",
    'python-lesson-3':
        "score = 72\n\n"
        "if score >= 60:\n"
        "    print('Passed')\n"
        "else:\n"
        "    print('Try again')\n\n"
        "for number in [1, 2, 3]:\n"
        "    print(number)\n\n"
        "if chooses a path, and for repeats an action for each item.",
    'uiux-lesson-1':
        "Example: a login screen.\n\n"
        "UI decisions: the button color, spacing and font.\n"
        "UX decisions: asking for as few fields as possible, showing clear "
        "error messages, and letting people reveal their password.\n\n"
        "UI is how it looks; UX is how it works for the person using it.",
    'uiux-lesson-2':
        "Example: text readability.\n\n"
        "Dark gray text on a white background is easy to read. Light gray "
        "text on white is hard to read, especially for people with low "
        "vision.\n\n"
        "Pair a clear heading size with a smaller body size and keep high "
        "contrast so the most important text stands out first.",
    'ml-lesson-1':
        "Example: a spam filter.\n\n"
        "Instead of writing rules by hand, you show the model thousands of "
        "emails labeled spam or not spam. It learns patterns, like "
        "suspicious words, and then predicts whether a new email is spam.",
    'ml-lesson-2':
        "Example: predicting house prices.\n\n"
        "Training data might list the size, location and price of 10,000 "
        "houses. The model learns how those features relate to price.\n\n"
        "If the data only covers big houses, it will predict small houses "
        "badly, which is why representative data matters.",
    'web-lesson-1':
        "A tiny web page:\n\n"
        "<h1>My Page</h1>\n"
        "<p>Welcome to my site.</p>\n"
        "<a href='https://example.com'>Visit a link</a>\n\n"
        "h1 is the main heading, p is a paragraph, and a creates a link.",
    'web-lesson-2':
        "Style every paragraph:\n\n"
        "p {\n"
        "  color: #333333;\n"
        "  margin: 16px 0;\n"
        "  padding: 8px;\n"
        "}\n\n"
        "color changes the text color, margin adds space outside the "
        "element, and padding adds space inside it.",
  };
}