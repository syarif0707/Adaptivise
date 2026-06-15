import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ApiService {
  // Use a getter so it always checks the latest value from dotenv
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'https://adaptivise-engine-396176311722.us-central1.run.app';
  static Uri get processNoteUrl => getUrl('/ai/process-note');
  static Uri get processUrlUrl => getUrl('/ai/process-url');

  static Uri getUrl(String path) {
    final cleanBase = baseUrl.replaceAll(RegExp(r'/$'), '');
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$cleanBase$cleanPath');
  }

  static String _decodeBody(http.Response response) =>
      utf8.decode(response.bodyBytes, allowMalformed: true);

  static Never _throwApiError(String action, http.Response response) {
    throw Exception(
      'Failed to $action: ${response.statusCode} - ${_decodeBody(response)}',
    );
  }

  /// Upload a file for text extraction, summarization, and quiz generation.
  static Future<Map<String, dynamic>> processNote({
    required File file,
    required String userId,
    required String storagePath,
    required String folderId,
  }) async {
    final request = http.MultipartRequest('POST', processNoteUrl)
      ..fields['user_id'] = userId
      ..fields['folder_id'] = folderId
      ..fields['storage_path'] = storagePath
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return jsonDecode(_decodeBody(response)) as Map<String, dynamic>;
    }
    _throwApiError('process note', response);
  }

  /// Fetch and process a web page URL.
  static Future<Map<String, dynamic>> processUrl({
    required String url,
    required String userId,
    required String storagePath,
    required String folderId,
  }) async {
    final request = http.MultipartRequest('POST', processUrlUrl)
      ..fields['user_id'] = userId
      ..fields['folder_id'] = folderId
      ..fields['url'] = url.trim()
      ..fields['storage_path'] = storagePath;

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return jsonDecode(_decodeBody(response)) as Map<String, dynamic>;
    }
    _throwApiError('process URL', response);
  }

  /// Hybrid Weighted K-Means VARK classification.
  static Future<Map<String, dynamic>> classifyVark(List<int> scores) async {
    final response = await http.post(
      getUrl('/ai/classify-vark'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'scores': scores}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(_decodeBody(response)) as Map<String, dynamic>;
      final styles = data['learning_style'];
      final formatted = data['formatted_style'] ??
          (styles is List ? styles.join(' & ') : styles?.toString() ?? 'Read/Write');
      return {...data, 'formatted_style': formatted};
    }
    _throwApiError('classify VARK', response);
  }

  /// TextRank + BM25 hybrid summarization.
  static Future<Map<String, dynamic>> summarizeText(String extractedText) async {
    final response = await http.post(
      getUrl('/ai/summarize'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': extractedText}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(_decodeBody(response)) as Map<String, dynamic>;
    }
    _throwApiError('generate summary', response);
  }

  /// Formats a raw summary via the backend Gemini endpoint, with client fallbacks.
  static Future<String> formatWithGemini(String rawSummary) async {
    final trimmed = rawSummary.trim();
    if (trimmed.isEmpty) return trimmed;

    try {
      final response = await http.post(
        getUrl('/ai/format-summary'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': trimmed}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(_decodeBody(response)) as Map<String, dynamic>;
        final formatted = data['formatted_summary']?.toString().trim();
        if (formatted != null && formatted.isNotEmpty) {
          return formatted;
        }
      }
    } catch (_) {}

    return _formatWithGeminiClient(trimmed);
  }

  static Future<String> _formatWithGeminiClient(String rawSummary) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return _localFormatSummary(rawSummary);
    }

    final models = {
      dotenv.env['GEMINI_MODEL'],
      'gemini-2.5-flash',
      'gemini-2.0-flash-lite',
      'gemini-2.0-flash',
    }.whereType<String>().where((m) => m.isNotEmpty);

    final prompt = '''
You are an expert educational editor designing content for a mobile app.
Reformat this raw summary for excellent mobile readability using clean Markdown.

STRICT RULES:
1. Start with a single # Heading for the main title.
2. Convert the text into short, highly scannable bullet points.
3. Add a blank line between every bullet point.
4. **Bold** 1 or 2 critical keywords per bullet point.
5. Do not add information that is not in the raw summary.
6. Output valid Markdown only.

Raw summary:
$rawSummary
''';

    for (final modelName in models) {
      try {
        final model = GenerativeModel(model: modelName, apiKey: apiKey);
        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text?.trim();
        if (text != null && text.isNotEmpty) {
          return text;
        }
      } catch (_) {}
    }

    return _localFormatSummary(rawSummary);
  }

  static String _localFormatSummary(String rawSummary) {
    final sentences = rawSummary
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (sentences.isEmpty) return rawSummary;

    final title = sentences.first.length > 80
        ? '${sentences.first.substring(0, 77)}...'
        : sentences.first;

    final buffer = StringBuffer('# $title\n\n');
    for (final sentence in sentences) {
      buffer.writeln('- $sentence\n');
    }
    return buffer.toString().trim();
  }

  /// BM25 semantic quiz generation.
  static Future<List<dynamic>> generateQuiz(String extractedText) async {
    final response = await http.post(
      getUrl('/ai/generate-quiz'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': extractedText}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(_decodeBody(response)) as Map<String, dynamic>;
      return data['quiz_content'] as List<dynamic>? ?? [];
    }
    _throwApiError('generate quiz', response);
  }
}
