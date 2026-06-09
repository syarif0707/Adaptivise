import 'package:flutter/material.dart';

class KinestheticQuizScreen extends StatefulWidget {
  final List<dynamic> quizData; // Pass this from the library selection
  const KinestheticQuizScreen({super.key, required this.quizData});

  @override
  State<KinestheticQuizScreen> createState() => _KinestheticQuizScreenState();
}

class _KinestheticQuizScreenState extends State<KinestheticQuizScreen> {
  int currentIndex = 0;
  String? selectedAnswer;
  bool hasChecked = false; // Tracks if the user has revealed the answer

  @override
  Widget build(BuildContext context) {
    // Basic null safety check for quizData
    if (widget.quizData.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("KINESTHETIC QUIZ")),
        body: const Center(child: Text("No quiz data available.")),
      );
    }

    final currentQ = widget.quizData[currentIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("KINESTHETIC QUIZ", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Bar
              LinearProgressIndicator(
                value: (currentIndex + 1) / widget.quizData.length,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00695C)),
              ),
              const SizedBox(height: 30),
              
              // Question Text
              Text(
                currentQ['question'] ?? "No Question Found", 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 24),

              // Options List
              ... (currentQ['options'] as List).map((opt) {
                final String optionText = opt.toString().trim();
                final String correctAnswer = currentQ['answer'].toString().trim();
                
                final bool isCorrect = optionText == correctAnswer;
                final bool isSelected = selectedAnswer == optionText;
                
                // Color logic based on "Check Answer" state
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
                      color: isSelected && !hasChecked ? const Color(0xFF00695C) : borderColor,
                      width: 2,
                    ),
                  ),
                  child: RadioListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    title: Text(
                      optionText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    value: optionText,
                    groupValue: selectedAnswer,
                    // Disable selection after checking
                    onChanged: hasChecked ? null : (val) {
                      setState(() => selectedAnswer = val as String);
                    },
                    activeColor: const Color(0xFF00695C),
                  ),
                );
              }),

              const SizedBox(height: 40),
              
              // Action Button (Check -> Next -> Finish)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: const Color(0xFF00695C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: selectedAnswer == null ? null : () {
                  if (!hasChecked) {
                    // Phase 1: Reveal Answer
                    setState(() => hasChecked = true);
                  } else {
                    // Phase 2: Move to Next Question
                    if (currentIndex < widget.quizData.length - 1) {
                      setState(() {
                        currentIndex++;
                        selectedAnswer = null;
                        hasChecked = false;
                      });
                    } else {
                      // Finished
                      Navigator.pop(context);
                    }
                  }
                },
                child: Text(
                  !hasChecked 
                    ? "Check Answer" 
                    : (currentIndex < widget.quizData.length - 1 ? "Next Question" : "Finish Quiz"),
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 16, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}