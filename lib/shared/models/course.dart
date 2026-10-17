class Course {
  final String id;
  final String slug;
  final String title;
  final String description;
  final String category;
  final String level;
  final int lessons;
  final double rating;
  final String imageUrl;
  final List<String> outcomes;
  final int resourceCount;

  const Course({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.category,
    required this.level,
    required this.lessons,
    required this.rating,
    required this.imageUrl,
    this.outcomes = const [],
    this.resourceCount = 0,
  });

  /// Reads one course as sent by the course-service API.
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      level: json['level'] as String? ?? '',
      lessons: (json['lessonCount'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
      outcomes:
          (json['outcomes'] as List?)?.whereType<String>().toList() ?? const [],
      resourceCount: (json['resourceCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Same keys as the API, so the offline cache can reuse [Course.fromJson].
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'title': title,
      'description': description,
      'category': category,
      'level': level,
      'lessonCount': lessons,
      'rating': rating,
      'imageUrl': imageUrl,
      'outcomes': outcomes,
      'resourceCount': resourceCount,
    };
  }
}