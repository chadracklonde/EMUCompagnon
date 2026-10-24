import 'dart:convert';

class EveningExamenEntry {
  final int id;
  final String entryDate; // ISO date (yyyy-MM-dd)
  final List<String> answers;

  const EveningExamenEntry({
    required this.id,
    required this.entryDate,
    required this.answers,
  });

  factory EveningExamenEntry.fromMap(Map<String, dynamic> map) {
    final raw = map['answers'] as String;
    final decoded = (jsonDecode(raw) as List).cast<String>();
    return EveningExamenEntry(
      id: map['id'] as int,
      entryDate: map['entry_date'] as String,
      answers: decoded,
    );
  }
}
