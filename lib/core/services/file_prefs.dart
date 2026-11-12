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
      // Prefer the real app files dir when available (path_provider), so we
      // don't rely on a hardcoded /data/user/0 path that can differ on some
      // devices or work profiles.
      final override = _overrideDir;
      if (override != null) return override;
      return '/data/user/0/$package/files';
    }
    return Directory.systemTemp.path;
  }

  /// Set by the app at startup via [init] (path_provider) when available.
  static String? _overrideDir;

  static Future<void> init(String? dir) async {
    if (dir != null && dir.isNotEmpty) _overrideDir = dir;
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

  /// Atomic write: writes to `<key>.tmp` then renames over `<key>`.
  /// A crash mid-write leaves the previous file intact instead of corrupting it.
  static Future<void> writeAtomic(String key, String value) async {
    try {
      final dir = Directory(_dir);
      await dir.create(recursive: true);
      final tmp = File('$_dir/$key.tmp');
      await tmp.writeAsString(value, flush: true);
      final target = File('$_dir/$key');
      if (await target.exists()) await target.delete();
      await tmp.rename('$_dir/$key');
    } catch (_) {
      // Fallback to a plain write rather than losing the value entirely.
      await write(key, value);
    }
  }

  static Future<void> remove(String key) async {
    try {
      final file = File('$_dir/$key');
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
