import 'dart:async';

Future<void> downloadString(String filename, String content) async {
  // Not web: caller should not call this on non-web platforms.
  throw UnsupportedError('downloadString is only supported on web');
}
