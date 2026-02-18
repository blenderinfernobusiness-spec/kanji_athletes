import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

Future<String?> savePng(Uint8List bytes, String filename) async {
  try {
    // Prefer external Pictures directory when available (Android)
    try {
      final externalDirs = await getExternalStorageDirectories(type: StorageDirectory.pictures);
      if (externalDirs != null && externalDirs.isNotEmpty) {
        final picturesDir = externalDirs.first;
        final appDir = Directory(path.join(picturesDir.path, 'KanjiAthletes'));
        await appDir.create(recursive: true);
        final filePath = path.join(appDir.path, filename);
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        return file.path;
      }
    } catch (_) {
      // ignore and fall back to app documents directory
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath = path.join(dir.path, filename);
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return file.path;
  } catch (e) {
    // Failure saving screenshot on native platform
    return null;
  }
}
