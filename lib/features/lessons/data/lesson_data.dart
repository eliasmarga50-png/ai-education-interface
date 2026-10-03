

import 'package:ai_education_interface/shared/models/lesson.dart';

class LessonData {
  LessonData._();

  static List<CourseModule> modulesForCourse(String courseTitle) {
    switch (courseTitle) {
      case 'Flutter Development':
        return flutterModules;

      case 'Python Programming':
        return pythonModules;

      case 'UI/UX Design':
        return uiUxModules;

      case 'Machine Learning':
        return machineLearningModules;

      case 'Web Development':
        return webDevelopmentModules;

      default:
        return flutterModules;
    }
  }

  static const List<CourseModule> flutterModules = [
    CourseModule(
      id: 'flutter-module-1',
      title: 'Getting Started with Flutter',
      description: 'Learn the fundamentals of Flutter and Dart.',
      lessons: [
        Lesson(
          id: 'flutter-lesson-1',
          title: 'What is Flutter?',
          description: 'Understand Flutter and how it works.',
          durationMinutes: 8,
          content:
              'Flutter is Google’s UI toolkit for building beautiful '
              'and responsive applications from a single codebase.\n\n'
              'In this lesson, you will learn what Flutter is, why '
              'developers use it, and how Flutter applications are structured.',
        ),
        Lesson(
          id: 'flutter-lesson-2',
          title: 'Understanding Widgets',
          description: 'Learn the building blocks of Flutter applications.',
          durationMinutes: 12,
          content:
              'Everything in Flutter is a widget.\n\n'
              'Widgets describe what the user interface should look like. '
              'Flutter combines widgets together to create complete screens '
              'and applications.\n\n'
              'You will learn about StatelessWidget, StatefulWidget, '
              'and how widgets are composed together.',
        ),
        Lesson(
          id: 'flutter-lesson-3',
          title: 'Building Your First Screen',
          description: 'Create your first Flutter user interface.',
          durationMinutes: 15,
          content:
              'Now that you understand widgets, it is time to build a '
              'real screen.\n\n'
              'You will work with Scaffold, AppBar, Column, Row, '
              'Text, Icon, Container, and other fundamental widgets.',
        ),
      ],
    ),

    CourseModule(
      id: 'flutter-module-2',
      title: 'Layouts and UI',
      description: 'Build responsive and attractive interfaces.',
      lessons: [
        Lesson(
          id: 'flutter-lesson-4',
          title: 'Rows and Columns',
          description: 'Arrange widgets horizontally and vertically.',
          durationMinutes: 10,
          content:
              'Rows and Columns are two of the most important layout '
              'widgets in Flutter.\n\n'
              'A Row arranges children horizontally while a Column '
              'arranges children vertically.',
        ),
        Lesson(
          id: 'flutter-lesson-5',
          title: 'Responsive Layouts',
          description: 'Make your interfaces work across screen sizes.',
          durationMinutes: 14,
          content:
              'Responsive design allows your application to adapt to '
              'different screen sizes.\n\n'
              'You will learn how to use constraints, Expanded, Flexible, '
              'and MediaQuery to create flexible layouts.',
        ),
        Lesson(
          id: 'flutter-lesson-6',
          title: 'Cards and Lists',
          description: 'Create reusable course and content lists.',
          durationMinutes: 11,
          content:
              'Lists are essential for education applications because '
              'courses contain modules, modules contain lessons, and '
              'students need to navigate through large amounts of content.',
        ),
      ],
    ),

    CourseModule(
      id: 'flutter-module-3',
      title: 'Navigation and State',
      description: 'Learn how applications move between screens.',
      lessons: [
        Lesson(
          id: 'flutter-lesson-7',
          title: 'Navigation',
          description: 'Move between screens using Navigator.',
          durationMinutes: 13,
          content:
              'Navigation allows users to move through your application.\n\n'
              'You will learn how Navigator.push and Navigator.pop work '
              'and how screens can pass data to one another.',
        ),
        Lesson(
          id: 'flutter-lesson-8',
          title: 'Understanding State',
          description: 'Learn how Flutter manages changing information.',
          durationMinutes: 16,
          content:
              'State represents information that can change while an '
              'application is running.\n\n'
              'You will learn when to use StatefulWidget and how setState '
              'causes Flutter to rebuild the affected interface.',
        ),
      ],
    ),
  ];

  static const List<CourseModule> pythonModules = [
    CourseModule(
      id: 'python-module-1',
      title: 'Python Fundamentals',
      description: 'Learn the foundations of Python programming.',
      lessons: [
        Lesson(
          id: 'python-lesson-1',
          title: 'Introduction to Python',
          description: 'Understand Python and its common uses.',
          durationMinutes: 10,
          content:
              'Python is a general-purpose programming language known for '
              'its readable syntax and large ecosystem.',
        ),
        Lesson(
          id: 'python-lesson-2',
          title: 'Variables and Data Types',
          description: 'Store and work with different types of data.',
          durationMinutes: 12,
          content:
              'Variables allow programs to store information.\n\n'
              'Python provides several built-in data types including '
              'strings, integers, floating-point numbers, lists, and dictionaries.',
        ),
        Lesson(
          id: 'python-lesson-3',
          title: 'Conditions and Loops',
          description: 'Control how your Python programs execute.',
          durationMinutes: 15,
          content:
              'Conditional statements allow a program to make decisions, '
              'while loops allow a program to repeat operations.',
        ),
      ],
    ),
  ];

  static const List<CourseModule> uiUxModules = [
    CourseModule(
      id: 'uiux-module-1',
      title: 'Design Fundamentals',
      description: 'Learn the principles behind effective interfaces.',
      lessons: [
        Lesson(
          id: 'uiux-lesson-1',
          title: 'Introduction to UI/UX',
          description: 'Understand the difference between UI and UX.',
          durationMinutes: 9,
          content:
              'User Interface design focuses on the visual interface, '
              'while User Experience focuses on how people interact with '
              'a product and how that experience feels.',
        ),
        Lesson(
          id: 'uiux-lesson-2',
          title: 'Color and Typography',
          description: 'Learn how visual choices affect usability.',
          durationMinutes: 13,
          content:
              'Color and typography are fundamental parts of visual design. '
              'Good choices improve readability, hierarchy, and accessibility.',
        ),
      ],
    ),
  ];

  static const List<CourseModule> machineLearningModules = [
    CourseModule(
      id: 'ml-module-1',
      title: 'Machine Learning Fundamentals',
      description: 'Understand the foundations of machine learning.',
      lessons: [
        Lesson(
          id: 'ml-lesson-1',
          title: 'What is Machine Learning?',
          description: 'Understand the basic idea behind machine learning.',
          durationMinutes: 12,
          content:
              'Machine learning allows computer systems to learn patterns '
              'from data and use those patterns to make predictions or decisions.',
        ),
        Lesson(
          id: 'ml-lesson-2',
          title: 'Training Data',
          description: 'Learn why data is important for machine learning.',
          durationMinutes: 14,
          content:
              'Training data is used by machine learning algorithms to '
              'learn relationships and patterns.',
        ),
      ],
    ),
  ];

  static const List<CourseModule> webDevelopmentModules = [
    CourseModule(
      id: 'web-module-1',
      title: 'Web Fundamentals',
      description: 'Understand the building blocks of the web.',
      lessons: [
        Lesson(
          id: 'web-lesson-1',
          title: 'HTML Fundamentals',
          description: 'Learn the structure of web pages.',
          durationMinutes: 11,
          content:
              'HTML provides the structure and meaning of content on a web page.',
        ),
        Lesson(
          id: 'web-lesson-2',
          title: 'CSS Fundamentals',
          description: 'Style and design modern web pages.',
          durationMinutes: 13,
          content:
              'CSS controls the presentation and visual appearance of HTML elements.',
        ),
      ],
    ),
  ];
}