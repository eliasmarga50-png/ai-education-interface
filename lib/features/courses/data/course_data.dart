import '../../../shared/models/course.dart';

class CourseData {
  CourseData._();

  static const List<Course> courses = [
    Course(
      title: 'Flutter Development',
      description: 'Learn how to build beautiful Flutter applications.',
      category: 'Programming',
      level: 'Beginner',
      lessons: 24,
      rating: 4.9,
      imageUrl: '',
    ),
    Course(
      title: 'Python Programming',
      description: 'Learn Python from the fundamentals to practical projects.',
      category: 'Programming',
      level: 'Beginner',
      lessons: 32,
      rating: 4.8,
      imageUrl: '',
    ),
    Course(
      title: 'UI/UX Design',
      description: 'Learn the principles of modern user interface design.',
      category: 'Design',
      level: 'Intermediate',
      lessons: 18,
      rating: 4.7,
      imageUrl: '',
    ),
    Course(
      title: 'Machine Learning',
      description: 'Explore the fundamentals of machine learning.',
      category: 'AI',
      level: 'Intermediate',
      lessons: 28,
      rating: 4.9,
      imageUrl: '',
    ),
    Course(
      title: 'Web Development',
      description: 'Build modern websites with HTML, CSS and JavaScript.',
      category: 'Programming',
      level: 'Beginner',
      lessons: 30,
      rating: 4.6,
      imageUrl: '',
    ),
  ];
}