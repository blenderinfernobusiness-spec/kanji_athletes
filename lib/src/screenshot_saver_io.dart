import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';

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
        // Try to notify the Android media scanner so the image appears in the Gallery
        try {
          const platform = MethodChannel('kanji_athletes/saver');
          await platform.invokeMethod('scanFile', {'path': file.path});
        } catch (_) {
          // ignore errors from platform channel - scanner is best-effort
        }
        return file.path;
      }
    } catch (_) {
      // ignore and fall back to app documents directory
    }

    // Try writing directly to the public Pictures folder (sdcard) which is visible
    // to gallery apps on many devices/emulators. This is a best-effort fallback.
    try {
      final sdPath = '/sdcard/Pictures/KanjiAthletes';
      final sdDir = Directory(sdPath);
      if (!await sdDir.exists()) {
        await sdDir.create(recursive: true);
      }
      final sdFilePath = path.join(sdDir.path, filename);
      final sdFile = File(sdFilePath);
      await sdFile.writeAsBytes(bytes);
      try {
        const platform = MethodChannel('kanji_athletes/saver');
        await platform.invokeMethod('scanFile', {'path': sdFile.path});
      } catch (_) {}
      return sdFile.path;
    } catch (_) {
      // ignore and fall back
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
