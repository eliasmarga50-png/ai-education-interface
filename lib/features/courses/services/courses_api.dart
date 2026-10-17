import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/paged_result.dart';
import '../../../shared/models/course.dart';
import '../models/course_resource.dart';

/// One method per endpoint. No state, no UI: [CourseRepository] owns the state.
abstract class CoursesApi {
  Future<PagedResult<Course>> listCourses({
    int page = 1,
    int limit = 50,
    String? category,
    String? level,
    String? query,
  });

  Future<Course> getCourse(String id);

  Future<PagedResult<CourseResource>> listResources(
    String courseId, {
    int page = 1,
    int limit = 50,
    ResourceType? type,
  });
}

class HttpCoursesApi implements CoursesApi {
  HttpCoursesApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  @override
  Future<PagedResult<Course>> listCourses({
    int page = 1,
    int limit = 50,
    String? category,
    String? level,
    String? query,
  }) async {
    final data = await _client.get(
      '/api/courses',
      baseUrl: ApiConfig.coursesBaseUrl,
      query: {
        'page': '$page',
        'limit': '$limit',
        if (category != null && category.isNotEmpty) 'category': category,
        if (level != null && level.isNotEmpty) 'level': level,
        if (query != null && query.isNotEmpty) 'q': query,
      },
    );
    return _page(data, Course.fromJson);
  }

  @override
  Future<Course> getCourse(String id) async {
    final data = await _client.get(
      '/api/courses/${Uri.encodeComponent(id)}',
      baseUrl: ApiConfig.coursesBaseUrl,
    );
    return Course.fromJson(Map<String, dynamic>.from(data['data'] as Map));
  }

  @override
  Future<PagedResult<CourseResource>> listResources(
    String courseId, {
    int page = 1,
    int limit = 50,
    ResourceType? type,
  }) async {
    final data = await _client.get(
      '/api/courses/${Uri.encodeComponent(courseId)}/resources',
      baseUrl: ApiConfig.coursesBaseUrl,
      query: {
        'page': '$page',
        'limit': '$limit',
        if (type != null) 'type': type.name,
      },
    );
    return _page(data, CourseResource.fromJson);
  }

  PagedResult<T> _page<T>(
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) parse,
  ) {
    final items = (data['data'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => parse(Map<String, dynamic>.from(item)))
        .toList();
    final meta = Map<String, dynamic>.from((data['meta'] as Map?) ?? const {});

    return PagedResult<T>(
      items: items,
      page: (meta['page'] as num?)?.toInt() ?? 1,
      limit: (meta['limit'] as num?)?.toInt() ?? items.length,
      total: (meta['total'] as num?)?.toInt() ?? items.length,
      totalPages: (meta['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}