import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final themeMode =
            ThemeController.instance.themeMode;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Appearance'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              30,
            ),
            children: [
              const _AppearanceHeader(),

              const SizedBox(height: 28),

              Text(
                'Theme',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),

              const SizedBox(height: 12),

              Card(
                child: Column(
                  children: [
                    _ThemeOption(
                      icon: Icons.brightness_auto_outlined,
                      title: 'System default',
                      subtitle:
                          'Follow your device theme.',
                      value: ThemeMode.system,
                      groupValue: themeMode,
                      onChanged: (value) {
                        ThemeController.instance
                            .setThemeMode(value);
                      },
                    ),
                    const Divider(height: 1),
                    _ThemeOption(
                      icon: Icons.light_mode_outlined,
                      title: 'Light',
                      subtitle:
                          'Use the light theme.',
                      value: ThemeMode.light,
                      groupValue: themeMode,
                      onChanged: (value) {
                        ThemeController.instance
                            .setThemeMode(value);
                      },
                    ),
                    const Divider(height: 1),
                    _ThemeOption(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark',
                      subtitle:
                          'Use the dark theme.',
                      value: ThemeMode.dark,
                      groupValue: themeMode,
                      onChanged: (value) {
                        ThemeController.instance
                            .setThemeMode(value);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Preview',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),

              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor
                              .withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.palette_outlined,
                          color:
                              AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Your selected theme is applied throughout the application.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                height: 1.5,
                              ),
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

class _AppearanceHeader
    extends StatelessWidget {
  const _AppearanceHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.palette_outlined,
            color: AppTheme.primaryColor,
            size: 30,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Choose how AI Education Platform should look on your device.',
              style: TextStyle(
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ThemeMode value;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      leading: Icon(
        icon,
        color: isSelected
            ? AppTheme.primaryColor
            : null,
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
        groupValue: groupValue,
        onChanged: (selectedValue) {
          if (selectedValue != null) {
            onChanged(selectedValue);
          }
        },
      ),
      onTap: () {
        onChanged(value);
      },
    );
  }
}