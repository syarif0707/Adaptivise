import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ApiService {
  // Use a getter so it always checks the latest value from dotenv
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'https://adaptivise-engine-396176311722.us-central1.run.app';
  static String get processNoteUrl => '$baseUrl/ai/process-note';
  /// Call function for the Python Hybrid Weighted K-Means algorithm
  static Uri getUrl(String path) {
  // Ensure the path starts with a / but baseUrl doesn't end with one
  final cleanBase = baseUrl.replaceAll(RegExp(r'/$'), '');
  final cleanPath = path.startsWith('/') ? path : '/$path';
  return Uri.parse('$cleanBase$cleanPath');
}

// Then call it like this:
static Future<Map<String, dynamic>> classifyVark(List<int> scores) async {
  final response = await http.post(
    getUrl('/ai/classify-vark'), // Safe concatenation
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'scores': scores}),
  );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to classify VARK: ${response.statusCode} - ${response.body}');
    }
  }

  /// Call function for the Python TextRank algorithm
  static Future<Map<String, dynamic>> summarizeText(String extractedText) async {
    final response = await http.post(
      getUrl('/ai/summarize'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': extractedText}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to generate summary');
    }
  }

  /// Gemini is used only to format summaries (title, layout, bullets).
  static Future<String> formatWithGemini(String rawSummary) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) throw Exception('Gemini API Key not found');

    final modelName = dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash';
    final model = GenerativeModel(model: modelName, apiKey: apiKey);

    final prompt = '''
You are an expert educational editor. Reformat this raw summary for readability using Markdown only.
Rules:
1. Add a clear title at the top.
2. Bold important keywords.
3. Use justified-style structured paragraphs, bullet points, or a table only when it genuinely helps.
4. Do not invent facts beyond the source summary.

Raw summary:
$rawSummary
''';

    final response = await model.generateContent([Content.text(prompt)]);
    return response.text ?? rawSummary;
  }

  /// Semantic question generation runs on the Python server (not Gemini).
  static Future<List<dynamic>> generateQuiz(String extractedText) async {
    final response = await http.post(
      getUrl('/ai/generate-quiz'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': extractedText}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['quiz_content'] as List<dynamic>? ?? [];
    }
    throw Exception('Failed to generate quiz: ${response.statusCode} - ${response.body}');
  }

  /// Sends the raw scores [V, A, R, K] to the AI to get the dominant style
  static Future<String> classifyVarkDominantStyle(List<int> scores) async {
    final response = await http.post(
      getUrl('/ai/classify-vark'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'scores': scores}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['learning_style'][0]; // Returns 'V', 'A', 'R', or 'K'
    } else {
      throw Exception('Failed to classify VARK profile');
    }
  }
}