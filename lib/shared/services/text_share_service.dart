import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/hymns/utils/hymn_stanza_parser.dart';

/// Shares a verse or a hymn as plain text, for messaging apps where the
/// words themselves (and not a picture of them) are wanted.
class TextShareService {
  static const _signature = 'ÉMU Compagnon';

  /// A verse, followed by its reference.
  static String verseText({required String reference, required String text}) =>
      '${text.trim()}\n— $reference\n\n$_signature';

  /// A whole hymn: number and title, then each stanza under its label,
  /// the refrain named as such.
  static String hymnText({
    required String number,
    required String title,
    required List<HymnStanza> stanzas,
  }) {
    final buffer = StringBuffer('$number — $title\n');
    for (final s in stanzas) {
      buffer
        ..writeln()
        ..writeln(s.isRefrain ? 'Refrain' : '${s.label}.')
        ..writeln(s.body);
    }
    buffer
      ..writeln()
      ..write(_signature);
    return buffer.toString();
  }

  static Future<void> share(String text, {String? subject}) => SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: subject,
          // iOS requires a non-zero anchor rect for the share popover.
          sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
        ),
      );
}
