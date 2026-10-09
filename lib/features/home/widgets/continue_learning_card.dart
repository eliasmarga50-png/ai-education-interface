import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../dashboard/models/dashboard_models.dart';

/// The hero card: the one thing to do next.
class ContinueLearningCard extends StatelessWidget {
  final ContinueTarget target;
  final VoidCallback onStart;
  final VoidCallback onBrowseCourses;

  const ContinueLearningCard({
    super.key,
    required this.target,
    required this.onStart,
    required this.onBrowseCourses,
  });

  @override
  Widget build(BuildContext context) {
    final ref = target.ref;
    final isAllDone = target.kind == ContinueKind.allDone || ref == null;

    final String label;
    final String title;
    final String subtitle;
    final String buttonText;

    if (ref == null || target.kind == ContinueKind.allDone) {
      label = 'ALL CAUGHT UP 🎉';
      title = 'You finished every lesson';
      subtitle = 'Explore more courses or sharpen your skills with quizzes.';
      buttonText = 'Browse courses';
    } else {
      switch (target.kind) {
        case ContinueKind.resume:
          label = 'CONTINUE LEARNING';
          buttonText = 'Resume lesson';
        case ContinueKind.next:
          label = 'UP NEXT';
          buttonText = 'Start lesson';
        case ContinueKind.start:
          label = 'START LEARNING';
          buttonText = 'Start your first lesson';
        case ContinueKind.allDone:
          label = '';
          buttonText = '';
      }

      title = ref.lesson.title;
      subtitle =
          '${ref.course.title} · ${ref.lesson.durationMinutes} min lesson';
    }

    final percent = (target.courseProgress * 100).round();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              Color(0xFF7C3AED),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -34,
              top: -34,
              child: _Circle(size: 140, opacity: 0.10),
            ),
            Positioned(
              left: -26,
              bottom: -48,
              child: _Circle(size: 130, opacity: 0.07),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  if (!isAllDone) ...[
                    const SizedBox(height: 18),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: target.courseProgress),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 8,
                            color: Colors.white,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.25),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${target.completedInCourse} of ${target.totalInCourse} '
                      'lessons · $percent% of the course',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  PressableScale(
                    onTap: isAllDone ? onBrowseCourses : onStart,
                    child: FilledButton.icon(
                      onPressed: isAllDone ? onBrowseCourses : onStart,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                        minimumSize: const Size(double.infinity, 50),
                        elevation: 2,
                        shadowColor: Colors.black26,
                      ),
                      icon: Icon(
                        isAllDone ? Icons.explore_outlined : Icons.play_arrow_rounded,
                        size: 22,
                      ),
                      label: Text(
                        buttonText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final double opacity;

  const _Circle({
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}