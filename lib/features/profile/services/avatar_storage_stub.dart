// Web: files cannot be copied; the picked blob: URL is used for this session.
Future<String> saveAvatarFile({
  required String sourcePath,
  required String userId,
}) async {
  return sourcePath;
}

Future<void> deleteAvatarFile(String path) async {}

Future<bool> avatarFileExists(String path) async => true;