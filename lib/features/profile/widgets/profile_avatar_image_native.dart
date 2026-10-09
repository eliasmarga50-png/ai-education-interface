// Native implementation - uses dart:io FileImage
import 'dart:io';
import 'package:flutter/material.dart';

Widget buildNativeAvatar(String imagePath, double radius, String initials) {
  final file = File(imagePath);
  if (file.existsSync()) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: FileImage(file),
    );
  }
  return CircleAvatar(
    radius: radius,
    child: Text(
      initials,
      style: TextStyle(fontSize: radius * 0.8, fontWeight: FontWeight.bold),
    ),
  );
}
