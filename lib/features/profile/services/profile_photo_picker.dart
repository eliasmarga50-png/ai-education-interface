import 'package:image_picker/image_picker.dart';

import 'profile_controller.dart';

/// Lets the user choose a photo from the gallery and uploads it to the
/// account. Shared by the Profile header and the Edit Profile screen.
class ProfilePhotoPicker {
  ProfilePhotoPicker._();

  static final ImagePicker _picker = ImagePicker();
  static bool _busy = false;

  /// Returns a message to show when something went wrong, or null when the
  /// photo was saved (or the user cancelled).
  static Future<String?> pickAndUpload() async {
    if (_busy) {
      return null;
    }
    _busy = true;

    try {
      XFile? image;

      try {
        // Small, so it stays well under the server's 300 KB limit.
        image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 512,
          maxHeight: 512,
        );
      } catch (_) {
        return 'We could not open your photos. Check the permission and try again.';
      }

      if (image == null) {
        return null;
      }

      final bytes = await image.readAsBytes();
      final controller = ProfileController.instance;
      final saved = await controller.updateAvatarBytes(bytes);

      return saved
          ? null
          : (controller.lastError ??
              'We could not save your photo. Please try again.');
    } finally {
      _busy = false;
    }
  }
}