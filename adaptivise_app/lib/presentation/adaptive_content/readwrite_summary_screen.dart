import 'package:adaptivise_prototype/core/app_theme.dart';
import 'package:adaptivise_prototype/core/note_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class SummaryModeScreen extends StatelessWidget {
  final String summary;

  const SummaryModeScreen({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final formatted = formatSummaryForDisplay(summary);

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: MarkdownBody(
            data: formatted,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              h1: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
              h2: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
              p: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
              listBullet: const TextStyle(fontSize: 16, color: Colors.teal),
              strong: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF00695C),
              ),
              blockSpacing: 12,
              listIndent: 24,
            ),
          ),
        ),
      ),
    );
  }
}
