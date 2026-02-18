import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

Future<void> main(List<String> args) async {
  final srcPath = 'assets/kanji_athletes.png';
  final outPath = 'windows/runner/resources/app_icon.ico';

  if (!File(srcPath).existsSync()) {
    print('Source image not found: $srcPath');
    exit(1);
  }

  final srcBytes = File(srcPath).readAsBytesSync();
  final src = img.decodeImage(srcBytes);
  if (src == null) {
    print('Failed to decode source image.');
    exit(2);
  }

  final sizes = [256, 128, 64, 48, 32, 16];
  final List<Uint8List> pngs = [];

  for (final s in sizes) {
    final resized = img.copyResize(src, width: s, height: s, interpolation: img.Interpolation.average);
    final png = img.PngEncoder().encodeImage(resized);
    pngs.add(Uint8List.fromList(png));
    print('Prepared $s x $s PNG, ${png.length} bytes');
  }

  // Build ICO
  final entries = <List<int>>[]; // store entry bytes
  final dataParts = <Uint8List>[];
  int offset = 6 + (16 * pngs.length); // header + entries

  final outBytes = BytesBuilder();

  // ICONDIR
  outBytes.add([0, 0]); // reserved
  outBytes.add([1, 0]); // type = 1 for ICO
  outBytes.add([pngs.length & 0xFF, (pngs.length >> 8) & 0xFF]); // count

  for (int i = 0; i < pngs.length; i++) {
    final png = pngs[i];
    final size = sizes[i];
    final widthByte = (size == 256) ? 0 : size;
    final heightByte = (size == 256) ? 0 : size;
    final bytesInRes = png.length;

    final entry = BytesBuilder();
    entry.add([widthByte]); // width
    entry.add([heightByte]); // height
    entry.add([0]); // color count
    entry.add([0]); // reserved
    entry.add([1, 0]); // color planes (little endian)
    entry.add([32, 0]); // bit count
    entry.add([bytesInRes & 0xFF, (bytesInRes >> 8) & 0xFF, (bytesInRes >> 16) & 0xFF, (bytesInRes >> 24) & 0xFF]); // bytes in res
    entry.add([offset & 0xFF, (offset >> 8) & 0xFF, (offset >> 16) & 0xFF, (offset >> 24) & 0xFF]); // image offset

    entries.add(entry.takeBytes());
    dataParts.add(png);
    offset += bytesInRes;
  }

  // Write entries
  for (final e in entries) outBytes.add(e);
  // Write image data
  for (final d in dataParts) outBytes.add(d);

  final outFile = File(outPath);
  // Backup existing
  if (outFile.existsSync()) {
    final bak = outPath + '.bak';
    print('Backing up existing icon to $bak');
    try { File(bak).writeAsBytesSync(outFile.readAsBytesSync()); } catch (_) {}
  }
  outFile.createSync(recursive: true);
  outFile.writeAsBytesSync(outBytes.takeBytes());
  print('Wrote ICO to $outPath');
}
