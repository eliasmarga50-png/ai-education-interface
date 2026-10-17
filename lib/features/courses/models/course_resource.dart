enum ResourceType {
  documentation,
  tutorial,
  video,
  course,
  article,
  book,
  interactive,
  other;

  /// Unknown values from a newer server fall back to [other] instead of failing.
  static ResourceType parse(String? value) {
    for (final type in ResourceType.values) {
      if (type.name == value) {
        return type;
      }
    }
    return ResourceType.other;
  }

  String get label {
    switch (this) {
      case ResourceType.documentation:
        return 'Documentation';
      case ResourceType.tutorial:
        return 'Tutorial';
      case ResourceType.video:
        return 'Video';
      case ResourceType.course:
        return 'Course';
      case ResourceType.article:
        return 'Article';
      case ResourceType.book:
        return 'Book';
      case ResourceType.interactive:
        return 'Interactive';
      case ResourceType.other:
        return 'Link';
    }
  }
}

class CourseResource {
  const CourseResource({
    required this.id,
    required this.courseId,
    required this.title,
    required this.url,
    required this.type,
    required this.description,
    required this.provider,
    this.language = 'en',
    this.difficulty,
    this.position = 0,
  });

  final String id;
  final String courseId;
  final String title;
  final String url;
  final ResourceType type;
  final String description;
  final String provider;
  final String language;
  final String? difficulty;
  final int position;

  Uri? get uri => Uri.tryParse(url);

  factory CourseResource.fromJson(Map<String, dynamic> json) {
    return CourseResource(
      id: json['id'] as String,
      courseId: json['courseId'] as String? ?? '',
      title: json['title'] as String,
      url: json['url'] as String,
      type: ResourceType.parse(json['type'] as String?),
      description: json['description'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      difficulty: json['difficulty'] as String?,
      position: (json['position'] as num?)?.toInt() ?? 0,
    );
  }
}