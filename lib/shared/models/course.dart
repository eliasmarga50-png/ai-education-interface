class Course {
  final String title;
  final String description;
  final String category;
  final String level;
  final int lessons;
  final double rating;
  final String imageUrl;

  const Course({
    required this.title,
    required this.description,
    required this.category,
    required this.level,
    required this.lessons,
    required this.rating,
    required this.imageUrl,
  });
}