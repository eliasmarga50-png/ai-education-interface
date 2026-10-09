import 'package:flutter/material.dart';
import 'app_spacing.dart';

enum DeviceScreenType {
  mobile,
  tablet,
  desktop,
}

class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  static const double mobileMax = 640;
  static const double tabletMax = 1024;

  static DeviceScreenType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileMax) {
      return DeviceScreenType.mobile;
    } else if (width <= tabletMax) {
      return DeviceScreenType.tablet;
    } else {
      return DeviceScreenType.desktop;
    }
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMax;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileMax && width <= tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width > tabletMax;
}

/// A container that centers and constrains content width on large screens
/// while applying responsive horizontal padding.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;
  final bool fillRemaining;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = AppSpacing.maxContentWidth,
    this.padding,
    this.fillRemaining = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final effectivePadding = padding ??
        (isMobile ? AppSpacing.pagePaddingMobile : AppSpacing.pagePaddingTablet);

    Widget content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(
        padding: effectivePadding,
        child: child,
      ),
    );

    return Align(
      alignment: Alignment.topCenter,
      child: content,
    );
  }
}

/// Helper that builds different widget trees depending on screen size.
class ResponsiveBuilder extends StatelessWidget {
  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final type = ResponsiveBreakpoints.getDeviceType(context);

    if (type == DeviceScreenType.desktop && desktop != null) {
      return desktop!(context);
    }
    if ((type == DeviceScreenType.tablet || type == DeviceScreenType.desktop) &&
        tablet != null) {
      return tablet!(context);
    }

    return mobile(context);
  }
}
