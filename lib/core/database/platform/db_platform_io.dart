import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

/// On Android/iOS, sqflite's own native plugin is already the default
/// factory — nothing to change. On desktop (Windows/macOS/Linux), sqflite
/// has no bundled native implementation, so we swap in the FFI-based one
/// (a real SQLite library loaded via dart:ffi).
Future<void> initializeDatabaseFactory() async {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    ffi.sqfliteFfiInit();
    databaseFactory = ffi.databaseFactoryFfi;
  }
}

/// A real file path inside the app's documents directory.
Future<String> getDatabasePath(String fileName) async {
  final docsDir = await getApplicationDocumentsDirectory();
  return join(docsDir.path, fileName);
}
