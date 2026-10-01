import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/lesson.dart';

class LessonContentScreen extends StatelessWidget {
  final Lesson lesson;

  const LessonContentScreen({
    super.key,
    required this.lesson,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _VideoPlaceholder(),

          const SizedBox(height: 24),

          Text(
            lesson.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 18,
                color: AppTheme.textSecondaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                '${lesson.durationMinutes} minutes',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            'About this lesson',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 10),

          Text(
            lesson.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                ),
          ),

          const SizedBox(height: 28),

          Text(
            'Lesson Content',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 12),

          Text(
            lesson.content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.8,
                ),
          ),

          const SizedBox(height: 30),

          _ResourcesSection(),

          const SizedBox(height: 30),

          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.check),
              label: const Text(
                'Mark Lesson Complete',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton(
            onPressed: () {},
            child: const Text('Next Lesson'),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircleAvatar(
          radius: 32,
          backgroundColor: Colors.white,
          child: Icon(
            Icons.play_arrow,
            color: Colors.black87,
            size: 36,
          ),
        ),
      ),
    );
  }
}

class _ResourcesSection extends StatelessWidget {
  const _ResourcesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resources',
          style: Theme.of(context).textTheme.titleLarge,
        ),

        const SizedBox(height: 12),

        Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.picture_as_pdf_outlined),
            ),
            title: const Text('Lesson Notes'),
            subtitle: const Text('PDF resource'),
            trailing: const Icon(Icons.download_outlined),
            onTap: () {},
          ),
        ),

        Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.code),
            ),
            title: const Text('Practice Code'),
            subtitle: const Text('Source code and examples'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ),
      ],
    );
  }
}