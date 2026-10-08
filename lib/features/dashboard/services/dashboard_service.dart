import '../../../shared/models/course.dart';
import '../../ai_tutor/services/tutor_controller.dart';
import '../../courses/data/course_data.dart';
import '../../lessons/data/lesson_data.dart';
import '../../lessons/services/learning_progress_service.dart';
import '../../profile/services/profile_controller.dart';
import '../../quizzes/data/mock_quiz_data.dart';
import '../../quizzes/services/quiz_progress_service.dart';
import '../models/dashboard_models.dart';
import 'learning_activity_service.dart';

/// Turns the app's separate services (lesson progress, activity, quizzes,
/// tutor) into the single [DashboardSnapshot] the Home screen draws.
class DashboardService {
  DashboardService._();

  /// Minutes of study per day that fill the daily-goal ring.
  static const int dailyGoalMinutes = 15;

  /// "1h 5m", "12m".
  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;

    if (minutes < 60) {
      return '${minutes}m';
    }

    return '${minutes ~/ 60}h ${minutes % 60}m';
  }

  static List<LessonRef> allLessons() {
    final refs = <LessonRef>[];

    for (final course in CourseData.courses) {
      final lessons = LessonData.modulesForCourse(course.title)
          .expand((module) => module.lessons);

      for (final lesson in lessons) {
        refs.add(LessonRef(course: course, lesson: lesson));
      }
    }

    return refs;
  }

  static LessonRef? findLesson(String lessonId) {
    for (final ref in allLessons()) {
      if (ref.lesson.id == lessonId) {
        return ref;
      }
    }

    return null;
  }

  static List<CourseProgressInfo> courseProgress() {
    final progress = LearningProgressService.instance;

    return CourseData.courses.map((course) {
      final lessons = LessonData.modulesForCourse(course.title)
          .expand((module) => module.lessons)
          .toList();

      final completed =
          lessons.where((lesson) => progress.isCompleted(lesson.id)).length;

      LessonRef? next;

      for (final lesson in lessons) {
        if (!progress.isCompleted(lesson.id)) {
          next = LessonRef(course: course, lesson: lesson);
          break;
        }
      }

      return CourseProgressInfo(
        course: course,
        totalLessons: lessons.length,
        completedLessons: completed,
        nextLesson: next,
      );
    }).toList();
  }

  static DashboardSnapshot snapshot() {
    final activity = LearningActivityService.instance;
    final progress = LearningProgressService.instance;
    final quizzes = QuizProgressService.instance;

    final courses = courseProgress();
    final lessonRefs = allLessons();

    final completedLessons = lessonRefs
        .where((ref) => progress.isCompleted(ref.lesson.id))
        .length;

    final today = LearningActivityService.dateOnly(DateTime.now());

    final week = List.generate(7, (i) {
      final date = DateTime(today.year, today.month, today.day - (6 - i));

      return DayActivity(
        date: date,
        seconds: activity.secondsOn(date),
        isActive: activity.isActiveOn(date),
        isToday: i == 6,
      );
    });

    final recentLessons = <RecentLessonInfo>[];

    for (final entry in activity.recentLessons) {
      final ref = findLesson(entry.lessonId);

      if (ref != null) {
        recentLessons.add(
          RecentLessonInfo(
            ref: ref,
            openedAt: entry.openedAt,
            isCompleted: progress.isCompleted(ref.lesson.id),
          ),
        );
      }

      if (recentLessons.length == 3) {
        break;
      }
    }

    final conversations = TutorController.instance.conversations;

    return DashboardSnapshot(
      streak: activity.currentStreak,
      longestStreak: activity.longestStreak,
      activeToday: activity.activeToday,
      totalSeconds: activity.totalSeconds,
      dailyGoalMinutes: dailyGoalMinutes,
      week: week,
      completedLessons: completedLessons,
      totalLessons: lessonRefs.length,
      quizzesPassed: quizzes.quizzesPassed,
      totalQuizzes: MockQuizData.quizzes.length,
      quizAverage:
          quizzes.totalAttempts == 0 ? null : quizzes.averageBestPercentage,
      courses: courses,
      continueTarget: _continueTarget(courses),
      recentLessons: recentLessons,
      recommendations: _recommendations(courses),
      lastConversation: conversations.isEmpty ? null : conversations.first,
    );
  }

  // ---------------------------------------------------------------------
  // Continue learning
  // ---------------------------------------------------------------------

  static ContinueTarget _continueTarget(List<CourseProgressInfo> courses) {
    final activity = LearningActivityService.instance;
    final progress = LearningProgressService.instance;

    CourseProgressInfo infoFor(Course course) {
      return courses.firstWhere((info) => info.course.title == course.title);
    }

    ContinueTarget target(ContinueKind kind, LessonRef ref) {
      final info = infoFor(ref.course);

      return ContinueTarget(
        kind: kind,
        ref: ref,
        completedInCourse: info.completedLessons,
        totalInCourse: info.totalLessons,
      );
    }

    // 1. A lesson that was opened but not finished.
    for (final entry in activity.recentLessons) {
      final ref = findLesson(entry.lessonId);

      if (ref != null && !progress.isCompleted(ref.lesson.id)) {
        return target(ContinueKind.resume, ref);
      }
    }

    // 2. The next unfinished lesson in the course studied last.
    if (activity.recentLessons.isNotEmpty) {
      final last = findLesson(activity.recentLessons.first.lessonId);

      if (last != null) {
        final next = infoFor(last.course).nextLesson;

        if (next != null) {
          return target(ContinueKind.next, next);
        }
      }
    }

    // 3. The first unfinished lesson anywhere.
    final hasStarted = progress.completedLessonIds.isNotEmpty ||
        activity.recentLessons.isNotEmpty;

    for (final info in courses) {
      final next = info.nextLesson;

      if (next != null) {
        return target(
          hasStarted ? ContinueKind.next : ContinueKind.start,
          next,
        );
      }
    }

    // 4. Everything is done.
    return const ContinueTarget(kind: ContinueKind.allDone);
  }

  // ---------------------------------------------------------------------
  // Recommendations
  // ---------------------------------------------------------------------

  static List<CourseRecommendation> _recommendations(
    List<CourseProgressInfo> courses,
  ) {
    final preferredLevel =
        ProfileController.instance.preferences.preferredDifficulty;

    final startedCategories = courses
        .where((info) => info.isStarted)
        .map((info) => info.course.category)
        .toSet();

    final scored = <MapEntry<CourseProgressInfo, double>>[];
    final reasons = <String, String>{};

    for (final info in courses) {
      if (info.isStarted) {
        continue;
      }

      final course = info.course;
      var score = course.rating / 5;
      var reason = 'Top rated';

      if (course.level == preferredLevel) {
        score += 2;
        reason = 'Matches your level';
      }

      if (startedCategories.contains(course.category)) {
        score += 2;
        reason = 'More ${course.category}';
      }

      reasons[course.title] = reason;
      scored.add(MapEntry(info, score));
    }

    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored
        .take(4)
        .map(
          (entry) => CourseRecommendation(
            info: entry.key,
            reason: reasons[entry.key.course.title] ?? 'Top rated',
          ),
        )
        .toList();
  }
}