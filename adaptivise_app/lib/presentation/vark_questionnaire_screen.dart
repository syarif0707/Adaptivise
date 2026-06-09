import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/api_service.dart';
import 'dashboard_screen.dart';

class VarkQuestion {
  final String question;
  final Map<String, String> answers;
  VarkQuestion({required this.question, required this.answers});
}

class VarkQuestionnaireScreen extends StatefulWidget {
  final bool isRetest;
  const VarkQuestionnaireScreen({super.key, this.isRetest = false});

  @override
  State<VarkQuestionnaireScreen> createState() => _VarkQuestionnaireScreenState();
}

class _VarkQuestionnaireScreenState extends State<VarkQuestionnaireScreen> {
  final List<VarkQuestion> _questions = [
    VarkQuestion(
      question: "I need to find the way to a shop that a friend has recommended. I would:",
      answers: {'V': "use a map.", 'A': "ask my friend to tell me the directions.", 'R': "write down the street directions.", 'K': "find the shop by walking or riding there."}
    ),
    VarkQuestion(
      question: "A website has a video showing how to make a special graph or chart. I would learn most from:",
      answers: {'V': "seeing the diagrams.", 'A': "listening to the speaker.", 'R': "reading the words.", 'K': "watching the actions."}
    ),
    VarkQuestion(
      question: "I want to find out more about a new tour that I am going on. I would:",
      answers: {'V': "look at details about the highlights on the map.", 'A': "talk with the person who planned the tour.", 'R': "read about the tour on the itinerary.", 'K': "look at pictures and real-life experiences."}
    ),
    VarkQuestion(
      question: "When choosing a career or area of study, these are important for me:",
      answers: {'V': "Working with designs, maps or charts.", 'A': "Communicating with others through discussion.", 'R': "Using words well in written reports.", 'K': "Applying my knowledge in real situations."}
    ),
    VarkQuestion(
      question: "When I am learning I:",
      answers: {'V': "see patterns in things.", 'A': "listen to experts.", 'R': "read books, articles and handouts.", 'K': "use examples and applications."}
    ),
    VarkQuestion(
      question: "I want to learn how to play a new board game or card game. I would:",
      answers: {'V': "use the diagrams that explain the moves.", 'A': "listen to someone explaining it.", 'R': "read the instructions.", 'K': "play it to learn it."}
    ),
    VarkQuestion(
      question: "I have a problem with my heart. I would prefer that the doctor:",
      answers: {'V': "showed me a diagram.", 'A': "described what was wrong.", 'R': "gave me a pamphlet.", 'K': "used a plastic model to show me."}
    ),
    VarkQuestion(
      question: "I want to learn to do something new on a computer. I would:",
      answers: {'V': "follow the diagrams in a book.", 'A': "talk with people who know the program.", 'R': "read the written instructions.", 'K': "start using it and learn by trial and error."}
    ),
    VarkQuestion(
      question: "When I learn from a website I like:",
      answers: {'V': "designs and points that I can see.", 'A': "audio channels where I can hear music or speakers.", 'R': "interesting written descriptions.", 'K': "videos showing how to do things."}
    ),
    VarkQuestion(
      question: "I prefer a presenter or a teacher who uses:",
      answers: {'V': "diagrams, charts or graphs.", 'A': "question and answer or group discussion.", 'R': "handouts, books, or readings.", 'K': "demonstrations or models."}
    ),
    VarkQuestion(
      question: "I remember more from a movie when I:",
      answers: {'V': "see the scenery and costumes.", 'A': "listen to the music and dialogue.", 'R': "read the reviews and subtitles.", 'K': "feel the emotions and actions."}
    ),
    VarkQuestion(
      question: "I need to learn how to take a photo with my new digital camera. I would:",
      answers: {'V': "look at diagrams showing how to use it.", 'A': "ask someone questions about it.", 'R': "read the printed instructions.", 'K': "take photos and see how they look."}
    ),
    VarkQuestion(
      question: "I prefer a website that has things I can:",
      answers: {'V': "see.", 'A': "hear.", 'R': "read.", 'K': "do."}
    ),
    VarkQuestion(
      question: "I have to make a brilliant speech at a special occasion. I would:",
      answers: {'V': "make diagrams or models.", 'A': "practice saying the words over and over.", 'R': "write out my speech and learn it by reading.", 'K': "gather many examples and stories."}
    ),
    VarkQuestion(
      question: "I am going to buy a digital camera or mobile phone. I would be influenced by:",
      answers: {'V': "it looks modern and has a good design.", 'A': "the salesperson telling me about it.", 'R': "reading the details about its features.", 'K': "trying or testing it."}
    ),
    VarkQuestion(
      question: "I want to save more money and to decide between a range of options. I would:",
      answers: {'V': "use graphs showing different options.", 'A': "talk with an expert about the options.", 'R': "read a print brochure describing the options.", 'K': "consider examples of each option."}
    ),
  ];

  final Map<int, String> _selectedAnswers = {};
  bool _isProcessing = false;

  Future<void> _submitQuiz() async {
    // Validate that all questions are answered
    if (_selectedAnswers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all 16 questions before submitting.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 1. Tally the scores
      int v = 0, a = 0, r = 0, k = 0;
      for (var answer in _selectedAnswers.values) {
        if (answer == 'V') v++;
        else if (answer == 'A') a++;
        else if (answer == 'R') r++;
        else if (answer == 'K') k++;
      }

      final List<int> rawScores = [v, a, r, k];

      // 2. API Classification (Talking to your Python AI)
      final Map<String, dynamic> aiResult = await ApiService.classifyVark(rawScores);
      final String formattedStyle = aiResult['formatted_style'] ?? 'Unknown';

      // 3. Save to Supabase Profiles Table
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'vark_scores': {
          'V': v,
          'A': a,
          'R': r,
          'K': k,
        },
        'primary_vark_style': formattedStyle,
      });

      // 4. Navigation
      if (mounted) {
        if (widget.isRetest) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated to $formattedStyle!')),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRetest ? 'Retest VARK Profile' : 'Discover Your Learning Style'),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _questions.length + 1,
              itemBuilder: (context, index) {
                if (index == _questions.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: ElevatedButton(
                      onPressed: _submitQuiz,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Submit & Generate Profile'),
                    ),
                  );
                }

                final q = _questions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${index + 1}. ${q.question}", 
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...q.answers.entries.map((entry) {
                          return RadioListTile<String>(
                            title: Text(entry.value),
                            value: entry.key,
                            groupValue: _selectedAnswers[index],
                            onChanged: (value) {
                              setState(() {
                                _selectedAnswers[index] = value!;
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}