



import '../../../shared/models/course.dart';
import '../../../shared/models/lesson.dart';
import '../../ai_tutor/models/chat_conversation.dart';

/// A lesson together with the course it belongs to.
class LessonRef {
  final Course course;
  final Lesson lesson;

  const LessonRef({
    required this.course,
    required this.lesson,
  });
}

enum ContinueKind {
  /// A lesson the user opened but has not completed.
  resume,

  /// The next unfinished lesson in the course they were last in.
  next,

  /// Nothing started yet: begin with the first lesson.
  start,

  /// Every lesson is completed.
  allDone,
}

class ContinueTarget {
  final ContinueKind kind;
  final LessonRef? ref;
  final int completedInCourse;
  final int totalInCourse;

  const ContinueTarget({
    required this.kind,
    this.ref,
    this.completedInCourse = 0,
    this.totalInCourse = 0,
  });

  double get courseProgress {
    if (totalInCourse == 0) {
      return 0;
    }

    return completedInCourse / totalInCourse;
  }
}

class CourseProgressInfo {
  final Course course;
  final int totalLessons;
  final int completedLessons;
  final LessonRef? nextLesson;

  const CourseProgressInfo({
    required this.course,
    required this.totalLessons,
    required this.completedLessons,
    required this.nextLesson,
  });

  double get progress {
    if (totalLessons == 0) {
      return 0;
    }

    return completedLessons / totalLessons;
  }

  bool get isStarted => completedLessons > 0;

  bool get isComplete => totalLessons > 0 && completedLessons == totalLessons;
}

class DayActivity {
  final DateTime date;
  final int seconds;
  final bool isActive;
  final bool isToday;

  const DayActivity({
    required this.date,
    required this.seconds,
    required this.isActive,
    required this.isToday,
  });

  double get minutes => seconds / 60;
}

class RecentLessonInfo {
  final LessonRef ref;
  final DateTime openedAt;
  final bool isCompleted;

  const RecentLessonInfo({
    required this.ref,
    required this.openedAt,
    required this.isCompleted,
  });
}

class CourseRecommendation {
  final CourseProgressInfo info;
  final String reason;

  const CourseRecommendation({
    required this.info,
    required this.reason,
  });
}

/// Everything the Home screen shows, computed in one place.
class DashboardSnapshot {
  final int streak;
  final int longestStreak;
  final bool activeToday;

  final int totalSeconds;
  final int dailyGoalMinutes;
  final List<DayActivity> week;

  final int completedLessons;
  final int totalLessons;

  final int quizzesPassed;
  final int totalQuizzes;
  final double? quizAverage;

  final List<CourseProgressInfo> courses;
  final ContinueTarget continueTarget;
  final List<RecentLessonInfo> recentLessons;
  final List<CourseRecommendation> recommendations;
  final ChatConversation? lastConversation;

  const DashboardSnapshot({
    required this.streak,
    required this.longestStreak,
    required this.activeToday,
    required this.totalSeconds,
    required this.dailyGoalMinutes,
    required this.week,
    required this.completedLessons,
    required this.totalLessons,
    required this.quizzesPassed,
    required this.totalQuizzes,
    required this.quizAverage,
    required this.courses,
    required this.continueTarget,
    required this.recentLessons,
    required this.recommendations,
    required this.lastConversation,
  });

  int get todaySeconds => week.last.seconds;

  int get weekSeconds {
    return week.fold(0, (sum, day) => sum + day.seconds);
  }

  int get coursesStarted {
    return courses.where((info) => info.isStarted).length;
  }

  int get coursesCompleted {
    return courses.where((info) => info.isComplete).length;
  }
}





