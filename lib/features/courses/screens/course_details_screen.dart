import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/course.dart';
import '../../lessons/screens/learning_screen.dart';

class CourseDetailsScreen extends StatelessWidget {
  final Course course;

  const CourseDetailsScreen({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CourseTitleSection(course: course),

                  const SizedBox(height: 24),

                  _CourseStats(course: course),

                  const SizedBox(height: 28),

                  const _SectionTitle(
                    title: 'About this course',
                  ),

                  const SizedBox(height: 10),

                  Text(
                    course.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                  ),

                  const SizedBox(height: 28),

                  const _SectionTitle(
                    title: 'What you will learn',
                  ),

                  const SizedBox(height: 12),

                  const _LearningPoint(
                    icon: Icons.check_circle_outline,
                    text: 'Understand the fundamentals step by step',
                  ),

                  const _LearningPoint(
                    icon: Icons.check_circle_outline,
                    text: 'Build practical projects while learning',
                  ),

                  const _LearningPoint(
                    icon: Icons.check_circle_outline,
                    text: 'Practice your knowledge with exercises',
                  ),

                  const _LearningPoint(
                    icon: Icons.check_circle_outline,
                    text: 'Develop skills you can use in real projects',
                  ),

                  const SizedBox(height: 28),

                  const _SectionTitle(
                    title: 'Course content',
                  ),

                  const SizedBox(height: 12),

                  _CourseContent(course: course),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:(context) => LearningScreen(
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