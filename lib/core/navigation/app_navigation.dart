import 'package:flutter/material.dart';

import 'main_tabs.dart';

/// Leaves any pushed screens (course details, learning, lessons...) and lands
/// on one of the main tabs. [MainShell] is the first route, so popping to it
/// and switching the tab is enough.
class AppNavigation {
  AppNavigation._();

  static void goToTab(BuildContext context, int tab) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    MainTabs.go(tab);
  }

  static void goHome(BuildContext context) =>
      goToTab(context, MainTabs.home);

  static void backToCourses(BuildContext context) =>
      goToTab(context, MainTabs.courses);
}