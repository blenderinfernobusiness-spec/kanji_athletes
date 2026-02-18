import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

Future<String?> savePng(Uint8List bytes, String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final filePath = path.join(dir.path, filename);
  final file = File(filePath);
  await file.writeAsBytes(bytes);
  return file.path;
}
