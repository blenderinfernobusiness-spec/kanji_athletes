// Conditional export for platform-specific screenshot saving
export 'src/screenshot_saver_io.dart'
    if (dart.library.html) 'src/screenshot_saver_web.dart';
