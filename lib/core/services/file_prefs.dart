import 'dart:io';

/// Minimal key/value file store that works without any native plugin.
///
/// On Android it writes to the app's INTERNAL files directory
/// (`/data/user/0/<package>/files/`). This requires no permission, always
/// persists across app restarts, and is not affected by scoped storage.
/// On other platforms it falls back to the system temp directory.
/// All failures are swallowed so the app keeps working (e.g. on desktop).
class FilePrefs {
  static const String package = 'com.magnetic.scanner.magnetic_field_scanner';

  static String get _dir {
    if (Platform.isAndroid) {
      return '/data/user/0/$package/files';
    }
    return Directory.systemTemp.path;
  }

  static Future<String?> read(String key) async {
    try {
      final file = File('$_dir/$key');
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String key, String value) async {
    try {
      final dir = Directory(_dir);
      await dir.create(recursive: true);
      await File('$_dir/$key').writeAsString(value);
    } catch (_) {}
  }

  static Future<void> remove(String key) async {
    try {
      final file = File('$_dir/$key');
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
