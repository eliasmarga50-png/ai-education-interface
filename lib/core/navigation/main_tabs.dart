


import 'package:flutter/foundation.dart';

/// Lets any screen switch the bottom-navigation tab, for example a Home card
/// that opens the Courses tab. [MainShell] listens to [index].
class MainTabs {
  MainTabs._();

  static const int home = 0;
  static const int courses = 1;
  static const int aiTutor = 2;
  static const int profile = 3;

  static final ValueNotifier<int> index = ValueNotifier<int>(home);

  static void go(int tab) {
    index.value = tab;
  }
}




