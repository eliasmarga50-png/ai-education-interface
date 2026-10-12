import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Copies the picked photo to `documents/avatars/userId_time.ext`.
/// A new file name per photo makes Flutter's image cache show the new picture.
Future<String> saveAvatarFile({
  required String sourcePath,
  required String userId,
}) async {
  final documents = await getApplicationDocumentsDirectory();
  final folder = Directory('${documents.path}${Platform.pathSeparator}avatars');
  if (!await folder.exists()) {
    await folder.create(recursive: true);
  }

  final dot = sourcePath.lastIndexOf('.');
  final extension = dot > sourcePath.lastIndexOf(Platform.pathSeparator) &&
          dot != -1 &&
          sourcePath.length - dot <= 6
      ? sourcePath.substring(dot).toLowerCase()
      : '.jpg';

  final safeId = userId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
  final target = '${folder.path}${Platform.pathSeparator}'
      '${safeId}_${DateTime.now().millisecondsSinceEpoch}$extension';

  await File(sourcePath).copy(target);
  return target;
}

Future<void> deleteAvatarFile(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {
    // A leftover file is harmless.
  }
}

Future<bool> avatarFileExists(String path) => File(path).exists();