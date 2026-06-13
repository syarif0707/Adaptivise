import 'package:adaptivise_prototype/core/api_service.dart';
import 'package:adaptivise_prototype/core/note_utils.dart';
import 'package:flutter/material.dart';

class KinestheticQuizScreen extends StatefulWidget {
  final List<Map<String, dynamic>> quizData;
  final String rawText;

  const KinestheticQuizScreen({
    super.key,
    required this.quizData,
    this.rawText = '',
  });

  @override
  State<KinestheticQuizScreen> createState() => _KinestheticQuizScreenState();
}

class _KinestheticQuizScreenState extends State<KinestheticQuizScreen> {
  late List<Map<String, dynamic>> _quiz;
  int currentIndex = 0;
  String? selectedAnswer;
  bool hasChecked = false;
  bool _isRegenerating = false;

  @override
  void initState() {
    super.initState();
    _quiz = List<Map<String, dynamic>>.from(widget.quizData);
  }

  Future<void> _regenerateQuiz() async {
    if (widget.rawText.trim().isEmpty) return;
    setState(() => _isRegenerating = true);
    try {
      final generated = await ApiService.generateQuiz(widget.rawText);
      final parsed = parseQuizContent(generated);
      if (parsed.isNotEmpty && mounted) {
        setState(() {
          _quiz = parsed;
          currentIndex = 0;
          selectedAnswer = null;
          hasChecked = false;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not regenerate quiz: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRegenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isRegenerating) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_quiz.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No quiz available yet.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Generate practice questions from your note content.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (widget.rawText.trim().isNotEmpty)
                ElevatedButton.icon(
                  onPressed: _regenerateQuiz,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Generate Quiz'),
                ),
            ],
          ),
        ),
      );
    }

    final currentQ = _quiz[currentIndex];
    final options = (currentQ['options'] as List).map((o) => o.toString()).toList();
    final correctAnswer = currentQ['answer'].toString().trim();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (currentIndex + 1) / _quiz.length,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00695C)),
            ),
            const SizedBox(height: 30),
            Text(
              currentQ['question'] ?? 'No Question Found',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ...options.map((optionText) {
              final isCorrect = optionText.trim() == correctAnswer;
              final isSelected = selectedAnswer == optionText;

              Color tileColor = Colors.grey[100]!;
              Color borderColor = Colors.transparent;

              if (hasChecked) {
                if (isCorrect) {
                  tileColor = Colors.green[100]!;
                  borderColor = Colors.green;
                } else if (isSelected) {
                  tileColor = Colors.red[100]!;
                  borderColor = Colors.red;
                }
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected && !hasChecked
                        ? const Color(0xFF00695C)
                        : borderColor,
                    width: 2,
                  ),
                ),
                child: RadioListTile<String>(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  title: Text(
                    optionText,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  value: optionText,
                  groupValue: selectedAnswer,
                  onChanged: hasChecked
                      ? null
                      : (val) => setState(() => selectedAnswer = val),
                  activeColor: const Color(0xFF00695C),
                ),
              );
            }),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: const Color(0xFF00695C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: selectedAnswer == null
                  ? null
                  : () {
                      if (!hasChecked) {
                        setState(() => hasChecked = true);
                      } else if (currentIndex < _quiz.length - 1) {
                        setState(() {
                          currentIndex++;
                          selectedAnswer = null;
                          hasChecked = false;
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Quiz complete!')),
                        );
                      }
                    },
              child: Text(
                !hasChecked
                    ? 'Check Answer'
                    : (currentIndex < _quiz.length - 1
                        ? 'Next Question'
                        : 'Finish Quiz'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
