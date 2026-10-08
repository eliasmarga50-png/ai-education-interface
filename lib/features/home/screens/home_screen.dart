import 'package:flutter/material.dart';

import '../../../core/navigation/main_tabs.dart';
import '../../../shared/models/course.dart';
import '../../ai_tutor/models/tutor_context.dart';
import '../../ai_tutor/screens/chat_screen.dart';
import '../../ai_tutor/services/tutor_controller.dart';
import '../../courses/screens/course_details_screen.dart';
import '../../dashboard/models/dashboard_models.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../../dashboard/services/learning_activity_service.dart';
import '../../lessons/screens/lesson_content_screen.dart';
import '../../lessons/services/learning_progress_service.dart';
import '../../profile/services/profile_controller.dart';
import '../../profile/widgets/profile_avatar.dart';
import '../../quizzes/screens/quiz_list_screen.dart';
import '../../quizzes/services/quiz_progress_service.dart';
import '../widgets/ai_tutor_shortcut_card.dart';
import '../widgets/continue_learning_card.dart';
import '../widgets/course_progress_section.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_lessons_section.dart';
import '../widgets/recommended_courses_section.dart';
import '../widgets/section_header.dart';
import '../widgets/stats_grid.dart';
import '../widgets/weekly_activity_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      // Home redraws whenever any of the data it shows changes.
      animation: Listenable.merge([
        ProfileController.instance,
        LearningProgressService.instance,
        LearningActivityService.instance,
        QuizProgressService.instance,
        TutorController.instance,
      ]),
      builder: (context, _) {
        final profile = ProfileController.instance.profile;
        final snapshot = DashboardService.snapshot();

        return Scaffold(
          appBar: AppBar(
            leadingWidth: 64,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: GestureDetector(
                onTap: () => MainTabs.go(MainTabs.profile),
                child: ProfileAvatar(
                  imagePath: profile.avatarUrl,
                  radius: 18,
                  fallbackText: profile.name,
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()} 👋',
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              _StreakChip(
                streak: snapshot.streak,
                activeToday: snapshot.activeToday,
              ),
              IconButton(
                tooltip: 'Notifications',
                onPressed: () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('No new notifications'),
                      ),
                    );
                },
                icon: const Icon(Icons.notifications_outlined),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: HomeContent(snapshot: snapshot),
        );
      },
    );
  }
}

class HomeContent extends StatelessWidget {
  final DashboardSnapshot snapshot;

  const HomeContent({
    super.key,
    required this.snapshot,
  });

  void _openLesson(BuildContext context, LessonRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonContentScreen(
          course: ref.course,
          lesson: ref.lesson,
        ),
      ),
    );
  }

  void _openCourse(BuildContext context, Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailsScreen(course: course),
      ),
    );
  }

  void _openQuizzes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuizListScreen(),
      ),
    );
  }

  /// Starts a new chat with [question]. If there is a lesson to continue,
  /// the chat is about that lesson.
  void _askTutor(BuildContext context, String question) {
    final ref = snapshot.continueTarget.ref;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          initialQuestion: question,
          lesson: ref == null
              ? null
              : TutorContext.fromLesson(
                  course: ref.course,
                  lesson: ref.lesson,
                ),
        ),
      ),
    );
  }

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversation: snapshot.lastConversation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final target = snapshot.continueTarget;
    final targetRef = target.ref;

    var index = 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        FadeSlideIn(
          index: index++,
          child: ContinueLearningCard(
            target: target,
            onStart: () {
              if (targetRef != null) {
                _openLesson(context, targetRef);
              }
            },
            onBrowseCourses: () => MainTabs.go(MainTabs.courses),
          ),
        ),

        const SizedBox(height: 16),

        FadeSlideIn(
          index: index++,
          child: QuickActions(
            onCourses: () => MainTabs.go(MainTabs.courses),
            onAiTutor: () => MainTabs.go(MainTabs.aiTutor),
            onQuizzes: () => _openQuizzes(context),
          ),
        ),

        const SizedBox(height: 28),

        FadeSlideIn(
          index: index++,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Your progress'),
              const SizedBox(height: 12),
              StatsGrid(snapshot: snapshot),
              const SizedBox(height: 12),
              WeeklyActivityCard(snapshot: snapshot),
            ],
          ),
        ),

        const SizedBox(height: 28),

        FadeSlideIn(
          index: index++,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Course progress',
                actionLabel: 'See all',
                onAction: () => MainTabs.go(MainTabs.courses),
              ),
              const SizedBox(height: 12),
              CourseProgressSection(
                courses: snapshot.courses,
                onOpenCourse: (course) => _openCourse(context, course),
                onBrowseCourses: () => MainTabs.go(MainTabs.courses),
              ),
            ],
          ),
        ),

        if (snapshot.recentLessons.isNotEmpty) ...[
          const SizedBox(height: 28),
          FadeSlideIn(
            index: index++,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Recent lessons'),
                const SizedBox(height: 12),
                RecentLessonsSection(
                  lessons: snapshot.recentLessons,
                  onOpen: (ref) => _openLesson(context, ref),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),

        FadeSlideIn(
          index: index++,
          child: AiTutorShortcutCard(
            lessonTitle: targetRef?.lesson.title,
            lastConversation: snapshot.lastConversation,
            onAsk: (question) => _askTutor(context, question),
            onOpenChat: () => _openChat(context),
          ),
        ),

        if (snapshot.recommendations.isNotEmpty) ...[
          const SizedBox(height: 28),
          FadeSlideIn(
            index: index++,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Recommended for you',
                  actionLabel: 'Browse',
                  onAction: () => MainTabs.go(MainTabs.courses),
                ),
                const SizedBox(height: 12),
                RecommendedCoursesSection(
                  recommendations: snapshot.recommendations,
                  onOpenCourse: (course) => _openCourse(context, course),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StreakChip extends StatelessWidget {
  final int streak;
  final bool activeToday;

  const _StreakChip({
    required this.streak,
    required this.activeToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasStreak = streak > 0;
    const flame = Color(0xFFEA580C);

    return Tooltip(
      message: activeToday
          ? 'Active today'
          : 'Study today to keep your streak',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: hasStreak
              ? flame.withValues(alpha: 0.14)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              size: 18,
              color: hasStreak ? flame : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: hasStreak ? flame : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}