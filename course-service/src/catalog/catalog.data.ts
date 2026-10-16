import { Level, ResourceType } from '../courses/courses.types';

export interface CatalogResource {
  title: string;
  url: string;
  type: ResourceType;
  description: string;
  provider: string;
  difficulty?: Level;
  language?: string; // defaults to 'en'
}

export interface CatalogCourse {
  slug: string;
  title: string; // the Flutter app looks lessons up by this exact title
  description: string;
  category: string;
  level: Level;
  lessonCount: number;
  rating: number | null;
  outcomes: string[];
  resources: CatalogResource[];
}

/** Array order is the display order. Resources are links only; no third-party content is copied. */
export const CATALOG: CatalogCourse[] = [
  {
    slug: 'flutter-development',
    title: 'Flutter Development',
    description: 'Learn how to build beautiful Flutter applications.',
    category: 'Programming',
    level: 'Beginner',
    lessonCount: 24,
    rating: 4.9,
    outcomes: [
      'Build responsive multi-screen apps from Flutter widgets and layouts',
      'Manage state and move between screens',
      'Load and display data from REST APIs',
      'Debug your app and prepare it for release',
    ],
    resources: [
      {
        title: 'Your first Flutter app',
        url: 'https://codelabs.developers.google.com/codelabs/flutter-codelab-first',
        type: 'tutorial',
        provider: 'Google Codelabs',
        difficulty: 'Beginner',
        description:
          'Build a responsive name-generator app and learn layouts, ChangeNotifier state, theming and accessibility.',
      },
      {
        title: 'Flutter codelabs',
        url: 'https://docs.flutter.dev/codelabs',
        type: 'interactive',
        provider: 'flutter.dev',
        difficulty: 'Beginner',
        description: 'Guided, hands-on codelabs; several run in DartPad so nothing needs installing.',
      },
      {
        title: 'Basic widgets',
        url: 'https://docs.flutter.dev/ui/widgets/basics',
        type: 'documentation',
        provider: 'flutter.dev',
        difficulty: 'Beginner',
        description: 'Reference for the essential widgets: Text, Image, Icon and buttons.',
      },
      {
        title: 'Navigate to a new screen and back',
        url: 'https://docs.flutter.dev/cookbook/navigation/navigation-basics',
        type: 'tutorial',
        provider: 'flutter.dev',
        difficulty: 'Beginner',
        description: 'The most basic navigation pattern, from the official Flutter cookbook.',
      },
      {
        title: 'Build a form with validation',
        url: 'https://docs.flutter.dev/cookbook/forms/validation',
        type: 'tutorial',
        provider: 'flutter.dev',
        difficulty: 'Beginner',
        description: 'Create a form and validate what the user types, step by step.',
      },
      {
        title: 'Dart codelabs',
        url: 'https://dart.dev/codelabs',
        type: 'interactive',
        provider: 'dart.dev',
        difficulty: 'Beginner',
        description: 'Learn Dart features such as collections, async/await, records and patterns in DartPad.',
      },
      {
        title: 'Flutter on YouTube',
        url: 'https://www.youtube.com/@flutterdev',
        type: 'video',
        provider: 'Flutter team',
        difficulty: 'Beginner',
        description: 'Official channel with widget explainers, release news and talks.',
      },
    ],
  },
  {
    slug: 'python-programming',
    title: 'Python Programming',
    description: 'Learn Python from the fundamentals to practical projects.',
    category: 'Programming',
    level: 'Beginner',
    lessonCount: 32,
    rating: 4.8,
    outcomes: [
      'Write programs with variables, control flow, functions and data structures',
      'Read and write files and handle errors',
      'Use the standard library and third-party packages',
      'Test and structure small projects',
    ],
    resources: [
      {
        title: 'CS50’s Introduction to Programming with Python',
        url: 'https://cs50.harvard.edu/python/2022/',
        type: 'course',
        provider: 'Harvard CS50',
        difficulty: 'Beginner',
        description:
          'Ten-week course for people with or without prior experience; free to follow online with problem sets.',
      },
      {
        title: 'The Python Tutorial',
        url: 'https://docs.python.org/3/tutorial/index.html',
        type: 'documentation',
        provider: 'Python Software Foundation',
        difficulty: 'Beginner',
        description:
          'The official tutorial. It moves quickly, so it suits readers who have programmed before.',
      },
      {
        title: 'Beginner’s Guide to Python',
        url: 'https://www.python.org/about/gettingstarted/',
        type: 'article',
        provider: 'python.org',
        difficulty: 'Beginner',
        description: 'How to install Python 3 and where to find beginner-friendly tutorials.',
      },
      {
        title: 'Automate the Boring Stuff with Python',
        url: 'https://automatetheboringstuff.com/',
        type: 'book',
        provider: 'Al Sweigart',
        difficulty: 'Beginner',
        description: 'Practical, project-style introduction to Python; readable free online.',
      },
      {
        title: 'Learn Python',
        url: 'https://www.learnpython.org/',
        type: 'interactive',
        provider: 'learnpython.org',
        difficulty: 'Beginner',
        description: 'Short interactive lessons with exercises you run in the browser.',
      },
    ],
  },
  {
    slug: 'ui-ux-design',
    title: 'UI/UX Design',
    description: 'Learn the principles of modern user interface design.',
    category: 'Design',
    level: 'Intermediate',
    lessonCount: 18,
    rating: 4.7,
    outcomes: [
      'Evaluate interfaces with established usability heuristics',
      'Use psychology-based principles to justify design decisions',
      'Follow platform design systems such as Material and Apple’s HIG',
      'Design interfaces that are accessible to more people',
    ],
    resources: [
      {
        title: '10 Usability Heuristics for User Interface Design',
        url: 'https://www.nngroup.com/articles/ten-usability-heuristics/',
        type: 'article',
        provider: 'Nielsen Norman Group',
        difficulty: 'Beginner',
        description: 'Jakob Nielsen’s ten rules of thumb for interaction design, with examples.',
      },
      {
        title: 'Heuristic Evaluation of User Interfaces',
        url: 'https://www.nngroup.com/videos/heuristic-evaluation/',
        type: 'video',
        provider: 'Nielsen Norman Group',
        difficulty: 'Intermediate',
        description: 'Jakob Nielsen explains how to judge a design against the ten heuristics.',
      },
      {
        title: 'Laws of UX',
        url: 'https://lawsofux.com/',
        type: 'article',
        provider: 'Jon Yablonski',
        difficulty: 'Beginner',
        description: 'A collection of psychology-based principles designers can apply to interfaces.',
      },
      {
        title: 'Material Design 3',
        url: 'https://m3.material.io/',
        type: 'documentation',
        provider: 'Google',
        difficulty: 'Intermediate',
        description: 'Google’s design system: foundations, components and guidance for Android, web and Flutter.',
      },
      {
        title: 'Human Interface Guidelines',
        url: 'https://developer.apple.com/design/human-interface-guidelines/',
        type: 'documentation',
        provider: 'Apple',
        difficulty: 'Intermediate',
        description: 'Apple’s design guidance for iOS, iPadOS, macOS and other platforms.',
      },
      {
        title: 'Introduction to Web Accessibility',
        url: 'https://www.w3.org/WAI/fundamentals/accessibility-intro/',
        type: 'article',
        provider: 'W3C WAI',
        difficulty: 'Beginner',
        description: 'What accessibility means and why it matters, from the W3C Web Accessibility Initiative.',
      },
    ],
  },
  {
    slug: 'machine-learning',
    title: 'Machine Learning',
    description: 'Explore the fundamentals of machine learning.',
    category: 'AI',
    level: 'Intermediate',
    lessonCount: 28,
    rating: 4.9,
    outcomes: [
      'Explain features, labels, loss and gradient descent',
      'Train and evaluate models with scikit-learn',
      'Recognise overfitting and data leakage',
      'Take a first step into neural networks and deep learning',
    ],
    resources: [
      {
        title: 'Machine Learning Crash Course',
        url: 'https://developers.google.com/machine-learning/crash-course',
        type: 'course',
        provider: 'Google for Developers',
        difficulty: 'Beginner',
        description: 'Google’s practical introduction with lessons, visualisations and exercises.',
      },
      {
        title: 'Intro to Machine Learning',
        url: 'https://www.kaggle.com/learn/intro-to-machine-learning',
        type: 'course',
        provider: 'Kaggle Learn',
        difficulty: 'Beginner',
        description: 'Short hands-on lessons where you build your first models in the browser.',
      },
      {
        title: 'Elements of AI',
        url: 'https://www.elementsofai.com/',
        type: 'course',
        provider: 'University of Helsinki',
        difficulty: 'Beginner',
        description: 'Non-technical introduction to what AI is and what it can and cannot do.',
      },
      {
        title: 'Create machine learning models',
        url: 'https://learn.microsoft.com/en-us/training/paths/create-machine-learn-models/',
        type: 'course',
        provider: 'Microsoft Learn',
        difficulty: 'Beginner',
        description: 'Learning path covering regression, classification and clustering with Python.',
      },
      {
        title: 'scikit-learn User Guide',
        url: 'https://scikit-learn.org/stable/user_guide.html',
        type: 'documentation',
        provider: 'scikit-learn',
        difficulty: 'Intermediate',
        description: 'Reference and explanations for the most widely used classical ML library.',
      },
      {
        title: 'Practical Deep Learning for Coders',
        url: 'https://course.fast.ai/',
        type: 'course',
        provider: 'fast.ai',
        difficulty: 'Intermediate',
        description: 'Free, project-first deep learning course for people who can already code.',
      },
      {
        title: 'Dive into Deep Learning',
        url: 'https://d2l.ai/',
        type: 'book',
        provider: 'd2l.ai',
        difficulty: 'Advanced',
        description: 'Interactive open book that combines theory, maths and runnable code.',
      },
    ],
  },
  {
    slug: 'web-development',
    title: 'Web Development',
    description: 'Build modern websites with HTML, CSS and JavaScript.',
    category: 'Programming',
    level: 'Beginner',
    lessonCount: 30,
    rating: 4.6,
    outcomes: [
      'Structure pages with semantic HTML and style them with CSS',
      'Build responsive layouts that work on any screen',
      'Add interactivity with JavaScript',
      'Use browser developer tools and follow web standards',
    ],
    resources: [
      {
        title: 'Learn web development',
        url: 'https://developer.mozilla.org/en-US/docs/Learn',
        type: 'documentation',
        provider: 'MDN Web Docs',
        difficulty: 'Beginner',
        description: 'Mozilla’s curriculum that takes you from beginner to comfortable with front-end basics.',
      },
      {
        title: 'freeCodeCamp curriculum',
        url: 'https://www.freecodecamp.org/learn',
        type: 'course',
        provider: 'freeCodeCamp',
        difficulty: 'Beginner',
        description: 'Free interactive lessons and projects, starting with HTML, CSS and JavaScript.',
      },
      {
        title: 'The Odin Project',
        url: 'https://www.theodinproject.com/',
        type: 'course',
        provider: 'The Odin Project',
        difficulty: 'Beginner',
        description: 'Open-source, project-based path from web foundations to full-stack JavaScript.',
      },
      {
        title: 'The Modern JavaScript Tutorial',
        url: 'https://javascript.info/',
        type: 'tutorial',
        provider: 'javascript.info',
        difficulty: 'Beginner',
        description: 'Detailed, example-driven tutorial covering the language, the browser and more.',
      },
      {
        title: 'Learn web development on web.dev',
        url: 'https://web.dev/learn',
        type: 'course',
        provider: 'Google web.dev',
        difficulty: 'Intermediate',
        description: 'Course series on HTML, CSS, responsive design, accessibility and performance.',
      },
    ],
  },
];