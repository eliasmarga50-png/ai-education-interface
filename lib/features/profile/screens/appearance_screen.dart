import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/theme_controller.dart';
import '../../../shared/widgets/pressable_scale.dart';

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
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  Text(
                    'Theme',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Choose how the app should look across all screens.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),

                  const SizedBox(height: 20),

                  RadioGroup<ThemeMode>(
                    groupValue: controller.themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        HapticFeedback.selectionClick();
                        controller.setThemeMode(value);
                      }
                    },
                    child: Column(
                      children: [
                        _ThemeOption(
                          title: 'System default',
                          subtitle: 'Follow your device setting automatically.',
                          icon: Icons.brightness_auto_outlined,
                          value: ThemeMode.system,
                        ),

                        const SizedBox(height: 12),

                        _ThemeOption(
                          title: 'Light',
                          subtitle: 'Clean, crisp light appearance.',
                          icon: Icons.light_mode_outlined,
                          value: ThemeMode.light,
                        ),

                        const SizedBox(height: 12),

                        _ThemeOption(
                          title: 'Dark',
                          subtitle: 'Refined deep navy dark mode.',
                          icon: Icons.dark_mode_outlined,
                          value: ThemeMode.dark,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Preview',
                    style: Theme.of(context).textTheme.titleMedium,
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
                                  .primary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.school_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Education Platform',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your learning journey starts here.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
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
            ),
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
    final theme = Theme.of(context);
    final isSelected = ThemeController.instance.themeMode == value;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title theme: $subtitle',
      child: PressableScale(
        onTap: () {
          HapticFeedback.selectionClick();
          ThemeController.instance.setThemeMode(value);
        },
        child: Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            leading: CircleAvatar(
              backgroundColor: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : theme.colorScheme.surfaceContainerHighest,
              child: Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? theme.colorScheme.primary : null,
              ),
            ),
            subtitle: Text(subtitle),
            trailing: Radio<ThemeMode>(
              value: value,
            ),
            onTap: () {
              HapticFeedback.selectionClick();
              ThemeController.instance.setThemeMode(value);
            },
          ),
        ),
      ),
    );
  }
}