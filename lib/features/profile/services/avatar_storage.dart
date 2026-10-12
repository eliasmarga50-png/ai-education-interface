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

Future<void> deleteAvatarFile(String path) => impl.deleteAvatarFile(path);

Future<bool> avatarFileExists(String path) => impl.avatarFileExists(path);