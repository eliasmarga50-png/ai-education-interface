import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/navigation/main_tabs.dart';
import '../../../shared/models/course.dart';
import '../../../shared/widgets/app_spacing.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../ai_tutor/models/tutor_context.dart';
import '../../ai_tutor/screens/chat_screen.dart';
import '../../ai_tutor/services/tutor_controller.dart';
import '../../courses/screens/course_details_screen.dart';
import '../../dashboard/models/dashboard_models.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../../dashboard/services/learning_activity_service.dart';
import '../../lessons/screens/lesson_content_screen.dart';
import '../../lessons/services/learning_progress_service.dart';
import '../../profile/screens/appearance_screen.dart';
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
          drawer: _AppDrawer(profile: profile, snapshot: snapshot),
          appBar: AppBar(
            leadingWidth: 56,
            leading: Builder(
              builder: (ctx) => Semantics(
                label: 'Open navigation menu',
                button: true,
                child: IconButton(
                  tooltip: 'Menu',
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Scaffold.of(ctx).openDrawer();
                  },
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_greeting()} 👋',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Notifications',
                onPressed: () {
                  HapticFeedback.lightImpact();
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
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.lightImpact();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: HomeContent(snapshot: snapshot),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Side Drawer
// ---------------------------------------------------------------------------

class _AppDrawer extends StatelessWidget {
  final dynamic profile;
  final DashboardSnapshot snapshot;

  const _AppDrawer({required this.profile, required this.snapshot});

  void _go(BuildContext context, int tab) {
    Navigator.of(context).pop();
    MainTabs.go(tab);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile header
            InkWell(
              onTap: () => _go(context, MainTabs.profile),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Row(
                  children: [
                    ProfileAvatar(
                      imagePath: profile.avatarUrl,
                      radius: 28,
                      fallbackText: profile.name,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((profile.email as String?)?.isNotEmpty == true)
                            Text(
                              profile.email as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),

            Divider(height: 1, color: colorScheme.outlineVariant),
            const SizedBox(height: 8),

            // Navigation items
            _DrawerItem(
              icon: Icons.home_rounded,
              label: 'Home',
              onTap: () => _go(context, MainTabs.home),
            ),
            _DrawerItem(
              icon: Icons.menu_book_rounded,
              label: 'Courses',
              onTap: () => _go(context, MainTabs.courses),
            ),
            _DrawerItem(
              icon: Icons.smart_toy_rounded,
              label: 'AI Tutor',
              onTap: () => _go(context, MainTabs.aiTutor),
            ),
            _DrawerItem(
              icon: Icons.quiz_rounded,
              label: 'Quizzes',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QuizListScreen()),
                );
              },
            ),

            const Spacer(),

            Divider(height: 1, color: colorScheme.outlineVariant),
            const SizedBox(height: 8),

            // Bottom actions
            _DrawerItem(
              icon: Icons.palette_outlined,
              label: 'Appearance',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AppearanceScreen()),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              onTap: () => _go(context, MainTabs.profile),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: colorScheme.onSurfaceVariant),
      title: Text(label),
      onTap: onTap,
      horizontalTitleGap: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

// ---------------------------------------------------------------------------
// Home content
// ---------------------------------------------------------------------------

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
    final isWide = !ResponsiveBreakpoints.isMobile(context);

    var index = 0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: isWide ? AppSpacing.pagePaddingTablet : AppSpacing.pagePaddingMobile,
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

            const SizedBox(height: 18),

            FadeSlideIn(
              index: index++,
              child: QuickActions(
                onCourses: () => MainTabs.go(MainTabs.courses),
                onAiTutor: () => MainTabs.go(MainTabs.aiTutor),
                onQuizzes: () => _openQuizzes(context),
              ),
            ),

            const SizedBox(height: AppSpacing.section),

            FadeSlideIn(
              index: index++,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Your progress'),
                  const SizedBox(height: 14),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: StatsGrid(snapshot: snapshot)),
                        const SizedBox(width: 16),
                        Expanded(child: WeeklyActivityCard(snapshot: snapshot)),
                      ],
                    )
                  else ...[
                    StatsGrid(snapshot: snapshot),
                    const SizedBox(height: 14),
                    WeeklyActivityCard(snapshot: snapshot),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.section),

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
                  const SizedBox(height: 14),
                  CourseProgressSection(
                    courses: snapshot.courses,
                    onOpenCourse: (course) => _openCourse(context, course),
                    onBrowseCourses: () => MainTabs.go(MainTabs.courses),
                  ),
                ],
              ),
            ),

            if (snapshot.recentLessons.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.section),
              FadeSlideIn(
                index: index++,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Recent lessons'),
                    const SizedBox(height: 14),
                    RecentLessonsSection(
                      lessons: snapshot.recentLessons,
                      onOpen: (ref) => _openLesson(context, ref),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

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
              const SizedBox(height: AppSpacing.section),
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
                    const SizedBox(height: 14),
                    RecommendedCoursesSection(
                      recommendations: snapshot.recommendations,
                      onOpenCourse: (course) => _openCourse(context, course),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
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

    return Semantics(
      label: 'Learning streak: $streak days. ${activeToday ? "Active today" : "Study today to keep streak"}',
      button: true,
      child: PressableScale(
        onTap: () {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  activeToday
                      ? 'Streak active! Great job learning today 🔥'
                      : 'Keep your streak alive by completing a lesson today!',
                ),
              ),
            );
        },
        child: Tooltip(
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
        ),
      ),
    );
  }
}
