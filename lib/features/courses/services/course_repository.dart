import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/models/course.dart';
import '../models/course_resource.dart';
import 'courses_api.dart';

/// The app's single source of course data.
///
/// - [refresh] loads every page of the catalogue and saves it on the device.
/// - If the network fails, the last saved catalogue stays on screen and
///   [error] explains what went wrong, so the app still works offline.
/// - The dashboard, quizzes and course screens all read [courses] and listen
///   to this object, so they update when the API answers.
class CourseRepository extends ChangeNotifier {
  CourseRepository(this._api);

  /// Replaced in tests.
  static CourseRepository instance = CourseRepository(HttpCoursesApi());

  static const String _cacheKey = 'courses_cache_v1';
  static const int _pageSize = 50;
  static const int _maxPages = 20;
  static const ApiException _invalidResponse = ApiException(
    code: 'INVALID_RESPONSE',
    message: 'The server sent an unexpected response. Please try again.',
  );

  final CoursesApi _api;

  List<Course> _courses = const [];
  bool _hasLoaded = false;
  bool _isLoading = false;
  ApiException? _error;
  Future<void>? _inFlight;

  List<Course> get courses => _courses;

  /// True once a catalogue is available (from the server or from the cache).
  bool get hasLoaded => _hasLoaded;
  bool get isLoading => _isLoading;

  /// The last refresh failure, or null.
  ApiException? get error => _error;

  Course? findById(String id) {
    for (final course in _courses) {
      if (course.id == id) {
        return course;
      }
    }
    return null;
  }

  /// Call once at start-up: shows the saved catalogue immediately, then refreshes.
  Future<void> initialize() async {
    await _restoreCache();
    unawaited(refresh());
  }

  Future<void> ensureLoaded() {
    final running = _inFlight;
    if (running != null) {
      return running;
    }
    if (_hasLoaded) {
      return Future.value();
    }
    return refresh();
  }

  /// Only one request runs at a time, even if several screens ask together.
  Future<void> refresh() =>
      _inFlight ??= _load().whenComplete(() => _inFlight = null);

  Future<void> _load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final all = <Course>[];
      for (var page = 1; page <= _maxPages; page++) {
        final result = await _api.listCourses(page: page, limit: _pageSize);
        all.addAll(result.items);
        if (!result.hasMore) {
          break;
        }
      }
      _courses = List.unmodifiable(all);
      _hasLoaded = true;
      await _saveCache(all);
    } on ApiException catch (e) {
      _error = e;
    } catch (_) {
      _error = _invalidResponse;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Course> fetchCourse(String id) => _guard(() => _api.getCourse(id));

  Future<List<CourseResource>> fetchResources(String courseId) {
    return _guard(() async {
      final all = <CourseResource>[];
      for (var page = 1; page <= _maxPages; page++) {
        final result = await _api.listResources(
          courseId,
          page: page,
          limit: _pageSize,
        );
        all.addAll(result.items);
        if (!result.hasMore) {
          break;
        }
      }
      return all;
    });
  }

  /// Everything that leaves this class is an [ApiException] with a safe message.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw _invalidResponse;
    }
  }

  Future<void> _restoreCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) {
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return;
      }
      final cached = decoded
          .whereType<Map>()
          .map((item) => Course.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      if (cached.isNotEmpty) {
        _courses = List.unmodifiable(cached);
        _hasLoaded = true;
        notifyListeners();
      }
    } catch (_) {
      // A damaged cache is ignored; the network will refill it.
    }
  }

  Future<void> _saveCache(List<Course> courses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode(courses.map((course) => course.toJson()).toList()),
      );
    } catch (_) {
      // Caching is best effort.
    }
  }
}