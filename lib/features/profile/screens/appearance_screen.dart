import 'package:flutter/material.dart';

import '../../../core/theme/theme_controller.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final controller = ThemeController.instance;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Appearance'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              30,
            ),
            children: [
              Text(
                'Theme',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),

              const SizedBox(height: 8),

              Text(
                'Choose how the app should look.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),

              const SizedBox(height: 20),

              RadioGroup<ThemeMode>(
                groupValue: controller.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    controller.setThemeMode(value);
                  }
                },
                child: Column(
                  children: [
                    _ThemeOption(
                      title: 'System default',
                      subtitle:
                          'Follow your device theme.',
                      icon: Icons.brightness_auto_outlined,
                      value: ThemeMode.system,
                    ),

                    const SizedBox(height: 12),

                    _ThemeOption(
                      title: 'Light',
                      subtitle:
                          'Always use the light theme.',
                      icon: Icons.light_mode_outlined,
                      value: ThemeMode.light,
                    ),

                    const SizedBox(height: 12),

                    _ThemeOption(
                      title: 'Dark',
                      subtitle:
                          'Always use the dark theme.',
                      icon: Icons.dark_mode_outlined,
                      value: ThemeMode.dark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Preview',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium,
              ),

              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.school_outlined,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Education Platform',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your learning journey starts here.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ThemeMode value;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context)
              .colorScheme
              .primaryContainer,
          child: Icon(
            icon,
            color: Theme.of(context)
                .colorScheme
                .onPrimaryContainer,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Radio<ThemeMode>(
          value: value,
        ),
        onTap: () {
          ThemeController.instance.setThemeMode(value);
        },
      ),
    );
  }
}