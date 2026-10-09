import 'package:flutter/material.dart';
import 'app_spacing.dart';
import 'pressable_scale.dart';

/// Standardized card component ensuring consistent spacing, radius, and elevation across the app.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double borderRadius;
  final bool clip;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.onTap,
    this.color,
    this.borderColor,
    this.borderRadius = AppSpacing.radiusLg,
    this.clip = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBorderColor = borderColor ??
        (isDark
            ? const Color(0xFF232D42)
            : const Color(0xFFE2E8F0));

    final effectiveColor = color ??
        (isDark
            ? const Color(0xFF131B2E)
            : Colors.white);

    Widget content = Material(
      color: effectiveColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(
          color: defaultBorderColor,
          width: 1.0,
        ),
      ),
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return PressableScale(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}

/// A circular or rounded square badge for icons with consistent tinted backgrounds.
class AppIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final double borderRadius;
  final bool isCircle;

  const AppIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44.0,
    this.iconSize = 22.0,
    this.borderRadius = AppSpacing.radiusMd,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: color,
        ),
      ),
    );
  }
}
