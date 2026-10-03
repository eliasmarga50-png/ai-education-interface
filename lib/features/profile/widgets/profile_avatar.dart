


import 'dart:io';

import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String imagePath;
  final double radius;
  final String fallbackText;

  const ProfileAvatar({
    super.key,
    required this.imagePath,
    this.radius = 40,
    this.fallbackText = 'E',
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        imagePath.isNotEmpty && File(imagePath).existsSync();

    if (hasImage) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(
          File(imagePath),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      child: Text(
        fallbackText.isNotEmpty
            ? fallbackText[0].toUpperCase()
            : 'E',
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}