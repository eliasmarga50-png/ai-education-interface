


import '../models/quiz.dart';
import '../models/quiz_question.dart';

/// Mock quizzes used until a real backend exists. There is one quiz per
/// lesson, matched by [Quiz.lessonId] (see lesson_data.dart for the ids).
class MockQuizData {
  MockQuizData._();

  /// Returns the quiz for [lessonId], or null when the lesson has none.
  static Quiz? quizForLesson(String lessonId) {
    for (final quiz in quizzes) {
      if (quiz.lessonId == lessonId) {
        return quiz;
      }
    }

    return null;
  }

  static const List<Quiz> quizzes = [
    Quiz(
      id: 'quiz-flutter-lesson-1',
      title: 'What is Flutter? Quiz',
      description: '3 questions to check what you learned in this lesson.',
      lessonId: 'flutter-lesson-1',
      questions: [
        QuizQuestion(
          id: 'flutter-lesson-1-q1',
          question: 'Which company created Flutter?',
          options: [
            'Google',
            'Microsoft',
            'Apple',
            'Meta',
          ],
          correctAnswer: 'Google',
        ),
        QuizQuestion(
          id: 'flutter-lesson-1-q2',
          question: 'Which programming language do you use to write Flutter apps?',
          options: [
            'Kotlin',
            'Dart',
            'Swift',
            'Java',
          ],
          correctAnswer: 'Dart',
        ),
        QuizQuestion(
          id: 'flutter-lesson-1-q3',
          question: 'What is a key advantage of Flutter?',
          options: [
            'It only runs on Android',
            'It needs separate code for every screen',
            'One codebase can target multiple platforms',
            'It is only used for backend servers',
          ],
          correctAnswer: 'One codebase can target multiple platforms',
        ),
      ],
    ),
    Quiz(
      id: 'quiz-flutter-lesson-2',
      title: 'Understanding Widgets Quiz',
      description: '3 questions to check what you learned in this lesson.',
      lessonId: 'flutter-lesson-2',
      questions: [
        QuizQuestion(
          id: 'flutter-lesson-2-q1',
          question: 'In Flutter, almost everything you see on screen is a...',
          options: [
            'Fragment',
            'Activity',
            'Template',
            'Widget',
          ],
          correctAnswer: 'Widget',
        ),
        QuizQuestion(
          id: 'flutter-lesson-2-q2',
          question: 'Which widget type is meant for UI that changes while the app runs?',
          options: [
            'StatefulWidget',
            'StatelessWidget',
            'Container',
            'Scaffold',
          ],
          correctAnswer: 'StatefulWidget',
        ),
        QuizQuestion(
          id: 'flutter-lesson-2-q3',
          question: 'How are complete Flutter screens created?',
          options: [
            'By writing one giant widget only',
            'By composing smaller widgets together',
            'By editing XML layout files',
            'By using HTML templates',
          ],
          correctAnswer: 'By composing smaller widgets together',
        ),
      ],
    ),
    Quiz(
      id: 'quiz-flutter-lesson-3',
      title: 'Building Your First Screen Quiz',
      description: '3 questions to check what you learned in this lesson.',
      lessonId: 'flutter-lesson-3',
      questions: [
        QuizQuestion(
          id: 'flutter-lesson-3-q1',
          question: 'Which widget provides the basic page structure, such as an app bar and a body?',
          options: [
            'Container',
            'Padding',
            'Scaffold',
            'Center',
          ],
          correctAnswer: 'Scaffold',
        ),
        QuizQuestion(
          id: 'flutter-lesson-3-q2',
          question: 'Which widget shows a title bar at the top of a screen?',
          options: [
            'Drawer',
            'Card',
            'SizedBox',
            'AppBar',
          ],
          correctAnswer: 'AppBar',
        ),
        QuizQuestion(
          id: 'flutter-lesson-3-q3',
          question: 'Which widget displays a piece of text?',
          options: [
            'Text',
            'Icon',
            'Image',
            'Divider',
          ],
          correctAnswer: 'Text',
        ),
      ],
    ),
    Quiz(
      id: 'quiz-flutter-lesson-4',
      title: 'Rows and Columns Quiz',
      description: '3 questions to check what you learned in this lesson.',
      lessonId: 'flutter-lesson-4',
      questions: [
        QuizQuestion(
          id: 'flutter-lesson-4-q1',
          question: 'Which widget arranges its children vertically?',
          options: [
            'Row',
            'Column',
            'Stack',
            'Wrap',
          ],
          correctAnswer: 'Column',
        ),
        QuizQuestion(
          id: 'flutter-lesson-4-q2',
          question: 'Which widget arranges its children horizontally?',
          options: [
            'Column',
            'ListView',
            'Row',
            'Align',
          ],
          correctAnswer: 'Row',
        ),
        QuizQuestion(
          id: 'flutter-lesson-4-q3',
          question: 'In a Column, which property controls alignment along the vertical axis?',
          options: [
            'crossAxisAlignment',
            'textAlign',
            'scrollDirection',
            'mainAxisAlignment',
          ],
          correctAnswer: 'mainAxisAlignment',
        ),
      ],
    ),
    Quiz(
      id: 'quiz-flutter-lesson-5',
      title: 'Responsive Layouts Quiz',
      description: '3 questions to check what you learned in this lesson.',
      lessonId: 'flutter-lesson-5',
      questions: [
        QuizQuestion(
          id: 'flutter-lesson-5-q1',
          question: 'Which widget makes a child fill the remaining space in a Row or Column?',
          options: [
            'Expanded',
            'SizedBox',
            'Padding',
            'Opacity',
          ],
          correctAnswer: 'Expanded',
        ),
        QuizQuestion(
          id: 'flutter-lesson-5-q2',
          question: 'Which class lets you read the size of the screen?',
          options: [
            'Navigator',
            'MediaQuery',
            'Theme',
            'Scaffold',
          ],
          correctAnswer: 'MediaQuery',
        ),
        QuizQuestion(
          id: 'flutter-lesson-5-q3',
          question: 'What is the main goal of responsive design?',
          options: [
            'Making the app start faster',
            'Reducing the app file size',
            'Adapting the layout to different screen sizes',
            'Adding more animations',
          ],
          correctAnswer: 'Adapting the layout to different screen sizes',
        ),
      ],
    ),
    Quiz(
      id: 'quiz-flutter-lesson-6',
      title: 'Cards and Lists Quiz',
      description: '3 questions to check what you learned in this lesson.',
      lessonId: 'flutter-lesson-6',
      questions: [
        QuizQuestion(
          id: 'flutter-lesson-6-q1',
          question: 'Which widget efficiently builds a long scrollable list of items?',
          options: [
            'Column',
            'Row',
            'Stack',
            'ListView.builder',
          ],
          correctAnswer: 'ListView.builder',
        ),
        QuizQuestion(
          id: 'flutter-lesson-6-q2',
          question: 'Which widget groups related content in a rounded, slightly raised surface?',
          options: [
            'Card',
            'Divider',
            'Spacer',
            'Placeholder',
          ],
          correctAnswer: 'Card',
        ),
        QuizQuestion(
          id: 'flutter-lesson-6-q3',
          question: 'Why create a reusable widget for list items?',
          options: [
            'To make the app bigger',
            'To avoid repeating code and keep the UI consistent',
            'To prevent scrolling',
            'To disable hot reload',
          ],
          correctAnswer: 'To avoid repeating code and keep the UI consistent',
        ),
      ],
    ),
    Quiz(
      id: 'quiz-flutter-lesson-7',
      title: 'Navigation Quiz',
      description: '3 questions to check what you learned in this lesson.',
      lessonId: 'flutter-lesson-7',
      questions: [
        QuizQuestion(
          id: 'flutter-lesson-7-q1',
          question: 'Which method opens a new screen?',
          options: [
            'Navigator.pop',
            'setState',
            'Navigator.push',
            'runApp',
          ],
          correctAnswer: 'Navigator.push',
        ),
        QuizQuestion(
          id: 'flutter-lesson-7-q2',
          question: 'Which method returns to the previous screen?',
          options: [
            'Navigator.push',
            'build',
            'initState',
            'Navigator.pop',
          ],
          correctAnswer: 'Navigator.pop',
        ),
        QuizQuestion(
          id: 'flutter-lesson-7-q3',
          question: 'How can one screen pass data to another?',
          options: [
            'Through constructor parameters',
            'By editing pubspec.yaml',
            'By restarting the app',
            'It is not possible',
          ],
          correctAnswer: 'Through constructor parameters',
        ),
      ],
    ),
    Quiz(
      id: 'quiz-flutter-lesson-8',
      title: 'Understanding State Quiz',
      description: '3 questions to check what you learned in this lesson.',
      lessonId: 'flutter-lesson-8',
      questions: [
        QuizQuestion(
          id: 'flutter-lesson-8-q1',
          question: 'What is state in a Flutter app?',
          options: [
            'A fixed constant',
            'Information that can change while the app runs',
            'A type of image',
            'The name of a screen',
          ],
          correctAnswer: 'Information that can change while the app runs',
        ),
        QuizQuestion(
          id: 'flutter-lesson-8-q2',
          question: 'What does setState do?',
          options: [
            'Saves data to disk',
            'Closes the app',
            'Tells Flutter to rebuild the affected widget',
            'Opens a new screen',
          ],
          correctAnswer: 'Tells Flutter to rebuild the affected widget',
        ),
        QuizQuestion(
          id: 'flutter-lesson-8-q3',
          question: 'Which widget type should you use when part of the UI changes over time?',
          options: [
            'StatelessWidget',
            'Icon',
            'SizedBox',
            'StatefulWidget',
          ],
          correctAnswer: 'StatefulWidget',
        ),
      ],
    ),
    Quiz(
      id: 'quiz-python-lesson-1',
      title: 'Introduction to Python Quiz',
      description: '3 questions to check what you learned in this lesson.',
      lessonId: 'python-lesson-1',
      questions: [
        QuizQuestion(
          id: 'python-lesson-1-q1',
          question: 'Python is best described as...',
          options: [
            'A general-purpose programming language',
            'A database engine',
            'A web browser',
            'A design tool',
          ],
          correctAnswer: 'A general-purpose programming language',
        ),
        QuizQuestion(
          id: 'python-lesson-1-q2',
          question: 'Which is a well-known strength of Python?',
          options: [
            'Mandatory semicolons everywhere',
            'Readable syntax',
            'It only runs on Windows',
            'It cannot use libraries',
          ],
          correctAnswer: 'Readable syntax',
        ),
        QuizQuestion(
          id: 'python-lesson-1-q3',
          question: 'Which of these is a common use of Python?',
          options: [
            'Formatting hard drives',
            'Replacing the operating system',
            'Data analysis and automation',
            'Printing documents',
          ],
          correctAnswer: 'Data analysis and automation',
        ),
      ],
    ),
    Quiz(
      id: 'quiz-python-lesson-2',
      title: 'Variables and Data Types Quiz',
      description: '3 questions to check what you learned in this lesson.',
      lessonId: 'python-lesson-2',
      questions: [
        QuizQuestion(
          id: 'python-lesson-2-q1',
          question: 'Which data type stores whole numbers?',
          options: [
            'str',
            'list',
            'dict',
            'int',
          ],
          correctAnswer: 'int',
        ),
        QuizQuestion(
          id: 'python-lesson-2-q2',
          question: 'What type of value is \'Ada\' in Python?',
          options: [
            'str',
            'int',
            'float',
            'bool',
          ],
          correctAnswer: 'str',
        ),
        QuizQuestion(
          id: 'python-lesson-2-q3',
          question: 'Which data type stores key-value pairs?',
          options: [
            'list',
            'dict',
            'int',
            'float',
          ],
          correctAnswer: 'dict',
        ),
      ],
    ),
    Quiz(
      id: 'quiz-python-lesson-3',
      title: 'Conditions and Loops Quiz',
      description: '3 questions to check what you learned in this lesson.',
      lessonId: 'python-lesson-3',
      questions: [
        QuizQuestion(
          id: 'python-lesson-3-q1',
          question: 'Which keyword starts a conditional check?',
          options: [
            'loop',
            'repeat',
            'if',
            'when',
          ],
          correctAnswer: 'if',
        ),
        QuizQuestion(
          id: 'python-lesson-3-q2',
          question: 'Which loop repeats once for each item in a list?',
          options: [
            'if',
            'def',
            'import',
            'for',
          ],
          correctAnswer: 'for',
        ),
        QuizQuestion(
          id: 'python-lesson-3-q3',
          question: 'What does a while loop do?',
          options: [
            'Repeats while a condition is true',
            'Runs exactly once',
            'Defines a function',
            'Imports a module',
          ],
          correctAnswer: 'Repeats while a condition is true',
        ),
      ],
    ),
    Quiz(
      id: 'quiz-uiux-lesson-1',
      title: 'Introduction to UI/UX Quiz',
      description: '3 questions to check what you learned in this lesson.',
      lessonId: 'uiux-lesson-1',
      questions: [
        QuizQuestion(
          id: 'uiux-lesson-1-q1',
          question: 'UI design focuses mainly on...',
          options: [
            'Server performance',
            'The visual interface',
            'Database structure',
            'Network speed',
          ],
          correctAnswer: 'The visual interface',
        ),
        QuizQuestion(
          id: 'uiux-lesson-1-q2',
          question: 'UX design focuses mainly on...',
          options: [
            'Only the colors',
            'Only the fonts',
            'How people interact with a product and how it feels',
            'The code structure',
          ],
          correctAnswer: 'How people interact with a product and how it feels',
        ),
        QuizQuestion(
          id: 'uiux-lesson-1-q3',
          question: 'Which of these is a UX concern?',
          options: [
            'The exact hex value of a button',
            'The size of a font file',
            'The pixel size of an icon',
            'How easily a user can complete a task',
          ],
          correctAnswer: 'How easily a user can complete a task',
        ),
      ],
    ),
    Quiz(
      id: 'quiz-uiux-lesson-2',
      title: 'Color and Typography Quiz',
      description: '3 questions to check what you learned in this lesson.',
      lessonId: 'uiux-lesson-2',
      questions: [
        QuizQuestion(
          id: 'uiux-lesson-2-q1',
          question: 'Good color and typography choices improve...',
          options: [
            'Readability and hierarchy',
            'Battery life',
            'Download speed',
            'Storage size',
          ],
          correctAnswer: 'Readability and hierarchy',
        ),
        QuizQuestion(
          id: 'uiux-lesson-2-q2',
          question: 'What is visual hierarchy?',
          options: [
            'Sorting files alphabetically',
            'Arranging elements so the most important ones stand out',
            'Using as many colors as possible',
            'Hiding secondary information',
          ],
          correctAnswer: 'Arranging elements so the most important ones stand out',
        ),
        QuizQuestion(
          id: 'uiux-lesson-2-q3',
          question: 'Which is an accessibility concern for color?',
          options: [
            'Using only very bright colors',
            'Using one color for all text',
            'Enough contrast between text and background',
            'Avoiding text completely',
          ],
          correctAnswer: 'Enough contrast between text and background',
        ),
      ],
    ),
    Quiz(
      id: 'quiz-ml-lesson-1',
      title: 'What is Machine Learning? Quiz',
      description: '3 questions to check what you learned in this lesson.',
      lessonId: 'ml-lesson-1',
      questions: [
        QuizQuestion(
          id: 'ml-lesson-1-q1',
          question: 'Machine learning lets systems learn...',
          options: [
            'Only rules written by hand',
            'Only from printed manuals',
            'Hardware drivers',
            'Patterns from data',
          ],
          correctAnswer: 'Patterns from data',
        ),
        QuizQuestion(
          id: 'ml-lesson-1-q2',
          question: 'What can a trained model do?',
          options: [
            'Make predictions or decisions',
            'Replace the power supply',
            'Print documents',
            'Format hard drives',
          ],
          correctAnswer: 'Make predictions or decisions',
        ),
        QuizQuestion(
          id: 'ml-lesson-1-q3',
          question: 'Machine learning is a field within...',
          options: [
            'Graphic design',
            'Artificial intelligence',
            'Networking hardware',
            'Database administration',
          ],
          correctAnswer: 'Artificial intelligence',
        ),
      ],
    ),
    Quiz(
      id: 'quiz-ml-lesson-2',
      title: 'Training Data Quiz',
      description: '3 questions to check what you learned in this lesson.',
      lessonId: 'ml-lesson-2',
      questions: [
        QuizQuestion(
          id: 'ml-lesson-2-q1',
          question: 'What is training data used for?',
          options: [
            'Styling the interface',
            'Compressing files',
            'Teaching an algorithm patterns and relationships',
            'Encrypting passwords',
          ],
          correctAnswer: 'Teaching an algorithm patterns and relationships',
        ),
        QuizQuestion(
          id: 'ml-lesson-2-q2',
          question: 'What usually happens when training data is poor quality?',
          options: [
            'The model becomes perfect',
            'Nothing changes',
            'The model deletes the data',
            'The model learns poor patterns and performs worse',
          ],
          correctAnswer: 'The model learns poor patterns and performs worse',
        ),
        QuizQuestion(
          id: 'ml-lesson-2-q3',
          question: 'Which statement is true?',
          options: [
            'Relevant, representative data helps models learn better',
            'Data quality does not matter',
            'One example is always enough',
            'Data must always be images',
          ],
          correctAnswer: 'Relevant, representative data helps models learn better',
        ),
      ],
    ),
    Quiz(
      id: 'quiz-web-lesson-1',
      title: 'HTML Fundamentals Quiz',
      description: '3 questions to check what you learned in this lesson.',
      lessonId: 'web-lesson-1',
      questions: [
        QuizQuestion(
          id: 'web-lesson-1-q1',
          question: 'What does HTML provide?',
          options: [
            'Only visual styling',
            'The structure and meaning of content',
            'Server logic',
            'Database storage',
          ],
          correctAnswer: 'The structure and meaning of content',
        ),
        QuizQuestion(
          id: 'web-lesson-1-q2',
          question: 'Which tag creates the largest standard heading?',
          options: [
            '<p>',
            '<div>',
            '<h1>',
            '<span>',
          ],
          correctAnswer: '<h1>',
        ),
        QuizQuestion(
          id: 'web-lesson-1-q3',
          question: 'Which tag creates a hyperlink?',
          options: [
            '<img>',
            '<ul>',
            '<br>',
            '<a>',
          ],
          correctAnswer: '<a>',
        ),
      ],
    ),
    Quiz(
      id: 'quiz-web-lesson-2',
      title: 'CSS Fundamentals Quiz',
      description: '3 questions to check what you learned in this lesson.',
      lessonId: 'web-lesson-2',
      questions: [
        QuizQuestion(
          id: 'web-lesson-2-q1',
          question: 'What does CSS control?',
          options: [
            'Presentation and visual appearance',
            'Database queries',
            'Server routing',
            'Operating system settings',
          ],
          correctAnswer: 'Presentation and visual appearance',
        ),
        QuizQuestion(
          id: 'web-lesson-2-q2',
          question: 'Which CSS property changes text color?',
          options: [
            'font-style',
            'color',
            'display',
            'margin',
          ],
          correctAnswer: 'color',
        ),
        QuizQuestion(
          id: 'web-lesson-2-q3',
          question: 'Which CSS property adds space outside an element\'s border?',
          options: [
            'padding',
            'border-radius',
            'margin',
            'opacity',
          ],
          correctAnswer: 'margin',
        ),
      ],
    ),
  ];
}