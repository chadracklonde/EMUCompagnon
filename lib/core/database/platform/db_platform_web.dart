import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' as ffi_web;

/// On the web, there is no real filesystem — sqflite_common_ffi_web
/// stores databases persistently in IndexedDB instead, behind the same
/// Database/DatabaseFactory API used everywhere else in the app.
Future<void> initializeDatabaseFactory() async {
  databaseFactory = ffi_web.databaseFactoryFfiWeb;
}

/// On the web there's no real path — just a logical name identifying the
/// database in IndexedDB.
Future<String> getDatabasePath(String fileName) async {
  return fileName;
}
