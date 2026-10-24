import 'dart:typed_data';

import 'avatar_storage_stub.dart'
    if (dart.library.io) 'avatar_storage_io.dart' as impl;

/// Keeps a picked photo somewhere permanent.
///
/// image_picker returns a path in the app's cache, which Android may delete at
/// any time, so on phones the file is copied into the app's documents folder.
/// On web the picked blob: URL only lives for the current session and is
/// returned unchanged.
Future<String> saveAvatarFile({
  required String sourcePath,
  required String userId,
}) {
  return impl.saveAvatarFile(sourcePath: sourcePath, userId: userId);
}

/// Keeps the photo downloaded from (or uploaded to) the server. Returns the
/// path to show: a file on phones, a data: URI on web.
Future<String> saveAvatarBytes({
  required Uint8List bytes,
  required String userId,
  required String mimeType,
}) {
  return impl.saveAvatarBytes(bytes: bytes, userId: userId, mimeType: mimeType);
}

Future<Uint8List> readAvatarBytes(String path) => impl.readAvatarBytes(path);

/// "image/jpeg", "image/png" or "image/webp" from the first bytes, or null
/// when the data is not one of those. The server checks the same thing.
String? detectImageMimeType(Uint8List b) {
  if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
    return 'image/jpeg';
  }

  const png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  if (b.length >= 8 && List.generate(8, (i) => b[i] == png[i]).every((x) => x)) {
    return 'image/png';
  }

  // "RIFF" .... "WEBP"
  if (b.length >= 12 &&
      b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 &&
      b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) {
    return 'image/webp';
  }

  return null;
}

Future<void> deleteAvatarFile(String path) => impl.deleteAvatarFile(path);

Future<bool> avatarFileExists(String path) => impl.avatarFileExists(path);