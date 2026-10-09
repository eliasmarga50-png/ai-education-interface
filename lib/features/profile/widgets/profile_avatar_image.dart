// Stub for web. dart:io is unavailable on web so this file provides a no-op
// implementation of buildNativeAvatar that never actually gets called
// (the caller checks kIsWeb first).
import 'package:flutter/material.dart';

Widget buildNativeAvatar(String imagePath, double radius, String initials) {
  // This stub is never called on web; the caller guards with kIsWeb.
  return CircleAvatar(
    radius: radius,
    child: Text(
      initials,
      style: TextStyle(
        fontSize: radius * 0.8,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
