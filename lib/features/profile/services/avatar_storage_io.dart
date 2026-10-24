import 'dart:convert';
import 'dart:typed_data';

// Web: there are no files. The photo is shown from a data: URI that lives in
// memory for the session and is downloaded again on the next start.
Future<String> saveAvatarFile({
  required String sourcePath,
  required String userId,
}) async {
  return sourcePath;
}

Future<String> saveAvatarBytes({
  required Uint8List bytes,
  required String userId,
  required String mimeType,
}) async {
  return 'data:$mimeType;base64,${base64Encode(bytes)}';
}

Future<Uint8List> readAvatarBytes(String path) async {
  final comma = path.indexOf(',');
  if (!path.startsWith('data:') || comma == -1) {
    throw UnsupportedError('Only data: URIs can be read on web.');
  }
  return base64Decode(path.substring(comma + 1));
}

Future<void> deleteAvatarFile(String path) async {}

Future<bool> avatarFileExists(String path) async => true;