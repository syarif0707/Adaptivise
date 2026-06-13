import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfExportService {
  static String _safeFileName(String name) =>
      name.replaceAll(RegExp(r'[^\w\-. ]'), '_');

  // IMPROVEMENT: Added sanitization for smart quotes, em-dashes, and special characters
  // that cause the default PDF font to crash.
  static String _plainText(String markdown) {
    String clean = markdown.replaceAll(RegExp(r'[#*_`\[\]]'), '').trim();
    return clean
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('—', '-');
  }

  static Future<String?> saveStudyPackPdf({
    required String fileName,
    required String summary,
    required dynamic quizContent,
  }) async {
    try {
      final safeName = _safeFileName(fileName);
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) {
            final blocks = <pw.Widget>[
              pw.Text(
                fileName,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Summary',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(_plainText(summary), style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 24),
              pw.Text(
                'Quiz',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
            ];

            // IMPROVEMENT: Added safe type checking for the Quiz Content
            if (quizContent is List) {
              for (var i = 0; i < quizContent.length; i++) {
                final q = quizContent[i];
                if (q is Map<String, dynamic>) {
                  blocks.add(
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 12),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Q${i + 1}: ${_plainText(q['question'] ?? q['prompt'] ?? 'Question')}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          if (q['answer'] != null)
                            pw.Text('Answer: ${_plainText(q['answer'])}'),
                        ],
                      ),
                    ),
                  );
                }
              }
            }

            return blocks;
          },
        ),
      );

      final bytes = await pdf.save();
      final directory = await _resolveSaveDirectory();
      
      // Fallback in case directory resolution fails
      if (directory == null) return null; 

      final outputPath = '${directory.path}/$safeName-study-pack.pdf';
      final file = File(outputPath);
      await file.writeAsBytes(bytes, flush: true);
      
      return file.path;
      
    } catch (e) {
      print("Error generating PDF: $e");
      return null; // Return null so your UI can show an error message
    }
  }

  static Future<Directory?> _resolveSaveDirectory() async {
    if (Platform.isAndroid) {
      // IMPROVEMENT: Force it to the public Android Download folder!
      final publicDownloadDir = Directory('/storage/emulated/0/Download');
      if (await publicDownloadDir.exists()) {
        return publicDownloadDir;
      }
      // If it doesn't exist (rare), fallback to standard external storage
      return await getExternalStorageDirectory();
    }
    
    if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    }
    
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return await getDownloadsDirectory();
    }
    
    return await getApplicationDocumentsDirectory();
  }
}