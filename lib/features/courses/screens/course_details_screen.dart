import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/course.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/app_shimmer.dart';
import '../../lessons/screens/learning_screen.dart';
import '../../quizzes/models/quiz_performance.dart';
import '../../quizzes/screens/quiz_screen.dart';
import '../../quizzes/services/quiz_progress_service.dart';
import '../../quizzes/widgets/understanding_badge.dart';
import '../models/course_resource.dart';
import '../services/course_repository.dart';
import '../widgets/resource_tile.dart';

typedef LinkLauncher = Future<bool> Function(Uri uri);

Future<bool> _openInBrowser(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

class CourseDetailsScreen extends StatefulWidget {
  final Course course;

  /// Injectable for tests; defaults to the app-wide repository.
  final CourseRepository? repository;
  final LinkLauncher launcher;

  const CourseDetailsScreen({
    super.key,
    required this.course,
    this.repository,
    this.launcher = _openInBrowser,
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen>
    with WidgetsBindingObserver {
  late final CourseRepository _repo =
      widget.repository ?? CourseRepository.instance;

  // The course from the list is shown at once; the API answer replaces it.
  late Course _course = widget.course;
  List<CourseResource> _resources = const [];
  bool _loading = true;
  ApiException? _error;

  /// The resource the student just opened in the browser. When they come back
  /// to the app, they are offered its quiz.
  CourseResource? _pendingQuizFor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    QuizProgressService.instance.refresh();
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final resource = _pendingQuizFor;
    if (state != AppLifecycleState.resumed || resource == null || !mounted) {
      return;
    }
    _pendingQuizFor = null;
    _offerQuiz(resource);
  }

  Future<void> _offerQuiz(CourseResource resource) async {
    final take = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Finished “${resource.title}”?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Take a short quiz to see how well you understood it.',
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Take quiz'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Not now'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (take == true && mounted) {
      await _openQuiz(resource: resource);
    }
  }

  Future<void> _openQuiz({CourseResource? resource}) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          courseId: _course.id,
          resourceId: resource?.id,
          title: resource?.title ?? _course.title,
        ),
      ),
    );
    QuizProgressService.instance.refresh();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<Object>([
        _repo.fetchCourse(widget.course.id),
        _repo.fetchResources(widget.course.id),
      ]);
      if (!mounted) return;
      setState(() {
        _course = results[0] as Course;
        _resources = results[1] as List<CourseResource>;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  Future<void> _open(CourseResource resource) async {
    final uri = resource.uri;
    var opened = false;

    if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
      try {
        opened = await widget.launcher(uri);
      } catch (_) {
        opened = false;
      }
    }

    if (opened) {
      _pendingQuizFor = resource;
      return;
    }
    if (!mounted) return;

    await Clipboard.setData(ClipboardData(text: resource.url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Couldn't open the link. It was copied instead."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final course = _course;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                course.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: _CourseHeader(
                category: course.category,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CourseTitleSection(course: course),
                      const SizedBox(height: 24),
                      _CourseStats(course: course),
                      const SizedBox(height: 28),
                      const _SectionTitle(title: 'About this course'),
                      const SizedBox(height: 10),
                      Text(
                        course.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                            ),
                      ),
                      const SizedBox(height: 28),
                      if (course.outcomes.isNotEmpty) ...[
                        const _SectionTitle(title: 'What you will learn'),
                        const SizedBox(height: 12),
                        for (final outcome in course.outcomes)
                          _LearningPoint(
                            icon: Icons.check_circle_outline,
                            text: outcome,
                          ),
                        const SizedBox(height: 28),
                      ],
                      const _SectionTitle(title: 'Learning resources'),
                      const SizedBox(height: 12),
                      AnimatedBuilder(
                        animation: QuizProgressService.instance,
                        builder: (context, _) => _ResourcesSection(
                          loading: _loading,
                          error: _error,
                          resources: _resources,
                          onRetry: _retry,
                          onOpen: _open,
                          onTakeQuiz: (resource) =>
                              _openQuiz(resource: resource),
                          performanceFor: (resource) => QuizProgressService
                              .instance
                              .scopeFor(_course.id, resource.id),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const _SectionTitle(title: 'Test your understanding'),
                      const SizedBox(height: 12),
                      AnimatedBuilder(
                        animation: QuizProgressService.instance,
                        builder: (context, _) => _CourseQuizCard(
                          performance: QuizProgressService.instance
                              .scopeFor(_course.id, null),
                          onStart: _openQuiz,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const _SectionTitle(title: 'Course content'),
                      const SizedBox(height: 12),
                      _CourseContent(course: course),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LearningScreen(
                        course: course,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Start Learning',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResourcesSection extends StatelessWidget {
  final bool loading;
  final ApiException? error;
  final List<CourseResource> resources;
  final VoidCallback onRetry;
  final ValueChanged<CourseResource> onOpen;
  final ValueChanged<CourseResource> onTakeQuiz;
  final ScopePerformance? Function(CourseResource) performanceFor;

  const _ResourcesSection({
    required this.loading,
    required this.error,
    required this.resources,
    required this.onRetry,
    required this.onOpen,
    required this.onTakeQuiz,
    required this.performanceFor,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Semantics(
        label: 'Loading learning resources',
        child: AppShimmer(
          child: Column(
            children: List.generate(
              3,
              (_) => Container(
                height: 84,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (error != null) {
      return AppErrorState(
        title: "Couldn't load resources",
        message: error!.message,
        onRetry: onRetry,
      );
    }

    if (resources.isEmpty) {
      return const AppEmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No resources yet',
        message: 'Learning resources for this course will appear here.',
      );
    }

    return Column(
      children: [
        for (final resource in resources)
          ResourceTile(
            resource: resource,
            onOpen: () => onOpen(resource),
            onTakeQuiz: () => onTakeQuiz(resource),
            performance: performanceFor(resource),
          ),
      ],
    );
  }
}

/// Entry to the quiz about the whole course, with the student's result if any.
class _CourseQuizCard extends StatelessWidget {
  final ScopePerformance? performance;
  final VoidCallback onStart;

  const _CourseQuizCard({required this.performance, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = performance;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Course quiz', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              result == null
                  ? 'Questions built from this course and its resources.'
                  : 'Attempts: ${result.attempts} · Best: ${result.bestScore.round()}%',
              style: theme.textTheme.bodyMedium,
            ),
            if (result != null) ...[
              const SizedBox(height: 10),
              UnderstandingBadge(
                understanding: result.understanding,
                percent: result.lastScore,
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.quiz_outlined),
              label: Text(result == null ? 'Start quiz' : 'Retake quiz'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseHeader extends StatelessWidget {
  final String category;

  const _CourseHeader({
    required this.category,
  });

  IconData get _icon {
    switch (category) {
      case 'Programming':
        return Icons.code;

      case 'Design':
        return Icons.design_services_outlined;

      case 'AI':
        return Icons.smart_toy_outlined;

      default:
        return Icons.school_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryColor,
      child: Center(
        child: Icon(
          _icon,
          size: 90,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CourseTitleSection extends StatelessWidget {
  final Course course;

  const _CourseTitleSection({
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          course.category.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          course.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),

        const SizedBox(height: 8),

        Text(
          '${course.level} • ${course.lessons} lessons',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _CourseStats extends StatelessWidget {
  final Course course;

  const _CourseStats({
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            icon: Icons.star,
            value: course.rating.toString(),
            label: 'Rating',
          ),
        ),

        Expanded(
          child: _StatItem(
            icon: Icons.menu_book_outlined,
            value: course.lessons.toString(),
            label: 'Lessons',
          ),
        ),

        Expanded(
          child: _StatItem(
            icon: Icons.signal_cellular_alt,
            value: course.level,
            label: 'Level',
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 24,
        ),

        const SizedBox(height: 6),

        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}

class _LearningPoint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _LearningPoint({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 22,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseContent extends StatelessWidget {
  final Course course;

  const _CourseContent({
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    final int moduleCount = (course.lessons / 6).ceil();

    return Card(
      child: Column(
        children: List.generate(
          moduleCount,
          (index) {
            final int startLesson = (index * 6) + 1;

            final int endLesson = ((index + 1) * 6).clamp(
              1,
              course.lessons,
            );

            return ListTile(
              leading: CircleAvatar(
                child: Text('${index + 1}'),
              ),

              title: Text(
                'Module ${index + 1}',
              ),

              subtitle: Text(
                'Lessons $startLesson–$endLesson',
              ),

              trailing: const Icon(
                Icons.chevron_right,
              ),
            );
          },
        ),
      ),
    );
  }
}