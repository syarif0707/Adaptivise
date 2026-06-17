import 'dart:convert';

/// Normalizes quiz payloads from Supabase/API into a usable list.
List<Map<String, dynamic>> parseQuizContent(dynamic raw) {
  if (raw == null) return [];

  dynamic decoded = raw;
  if (raw is String) {
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return [];
    }
  }

  if (decoded is! List) return [];

  return decoded
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .where(
        (item) =>
            (item['question'] ?? item['prompt'] ?? '').toString().isNotEmpty,
      )
      .map(_normalizeQuizItem)
      .where((item) => (item['options'] as List).isNotEmpty)
      .toList();
}

Map<String, dynamic> _normalizeQuizItem(Map<String, dynamic> item) {
  final question = (item['question'] ?? item['prompt'] ?? 'Review this concept.')
      .toString();
  final answer = (item['answer'] ?? item['correct_answer'] ?? '').toString();

  var options = <String>[];
  final rawOptions = item['options'];
  if (rawOptions is List) {
    options = rawOptions.map((o) => o.toString().trim()).where((o) => o.isNotEmpty).toList();
  }

  if (answer.isNotEmpty && !options.contains(answer)) {
    options.insert(0, answer);
  }

  if (options.length < 2 && answer.isNotEmpty) {
    options = [
      answer,
      'This statement is unrelated to the material.',
      'The opposite of the material is true.',
      'None of the above apply.',
    ];
  }

  options = options.toSet().toList();
  if (options.length > 4) {
    options = options.take(4).toList();
  }

  return {
    'question': question,
    'answer': answer.isNotEmpty ? answer : options.first,
    'options': options,
  };
}

/// Converts plain or lightly-marked summaries into readable markdown.
String formatSummaryForDisplay(String summary) {
  final trimmed = summary.trim();
  if (trimmed.isEmpty) return 'No summary available.';

  if (trimmed.contains('#') ||
      trimmed.contains('**') ||
      trimmed.contains('\n- ') ||
      trimmed.contains('\n* ')) {
    return trimmed;
  }

  final sentences = trimmed
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  if (sentences.isEmpty) return trimmed;

  final buffer = StringBuffer('## Summary\n\n');
  for (var i = 0; i < sentences.length; i++) {
    if (i == 0) {
      buffer.writeln(sentences[i]);
      buffer.writeln();
    } else if (i == 1 || sentences[i].length > 80) {
      buffer.writeln('- ${sentences[i]}');
    } else {
      buffer.writeln(sentences[i]);
    }
  }
  return buffer.toString().trim();
}
