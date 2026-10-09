import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Conditional import: on web, use the stub; on native, use the real file.
import 'profile_avatar_image.dart'
    if (dart.library.io) 'profile_avatar_image_native.dart';

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
    final initials = fallbackText.isNotEmpty
        ? fallbackText[0].toUpperCase()
        : '?';

    // No image set — show initials avatar.
    if (imagePath.isEmpty) {
      return _InitialsAvatar(radius: radius, initials: initials);
    }

    // On web, image_picker returns a blob URL or an XFile with a network path.
    // We display it via Image.network which handles blob: and https: URLs.
    if (kIsWeb) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.transparent,
        child: ClipOval(
          child: Image.network(
            imagePath,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _InitialsAvatar(radius: radius, initials: initials),
          ),
        ),
      );
    }

    // Native platforms: delegate to dart:io FileImage helper.
    return buildNativeAvatar(imagePath, radius, initials);
  }
}

class _InitialsAvatar extends StatelessWidget {
  final double radius;
  final String initials;

  const _InitialsAvatar({required this.radius, required this.initials});

  @override
  Widget build(BuildContext context) {
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
}