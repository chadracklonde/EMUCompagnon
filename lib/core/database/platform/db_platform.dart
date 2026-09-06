/// Picks the right platform implementation at COMPILE time (not runtime) —
/// this is what makes it safe to have a dart:io import in one branch: the
/// web build never even sees that file, so it never tries to compile it.
///
/// Default is the web implementation; if dart:io is available at all
/// (Android, iOS, Windows, macOS, Linux), that one is used instead.
export 'db_platform_web.dart' if (dart.library.io) 'db_platform_io.dart';
