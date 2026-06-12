import 'dart:convert';

import 'package:http/http.dart' as http;

/// Session debug logger (folded in IDE via #region).
void agentDebugLog({
  required String location,
  required String message,
  required Map<String, dynamic> data,
  required String hypothesisId,
  String runId = 'pre-fix',
}) {
  // #region agent log
  http
      .post(
        Uri.parse(
          'http://127.0.0.1:7548/ingest/f0d67597-6b37-4d01-b5d3-faf1ba1ddd1a',
        ),
        headers: {
          'Content-Type': 'application/json',
          'X-Debug-Session-Id': 'a2f396',
        },
        body: jsonEncode({
          'sessionId': 'a2f396',
          'runId': runId,
          'hypothesisId': hypothesisId,
          'location': location,
          'message': message,
          'data': data,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      )
      .catchError((_) => http.Response('', 500));
  // #endregion
}
