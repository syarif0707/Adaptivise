import 'package:adaptivise_prototype/logic/profile_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      answers: {'Visual': "use a map.", 'Auditory': "ask my friend to tell me the directions.", 'Read/Write': "write down the street directions.", 'Kinesthetic': "find the shop by walking or riding there."}
    ),
    VarkQuestion(
      question: "A website has a video showing how to make a special graph or chart. I would learn most from:",
      answers: {'Visual': "seeing the diagrams.", 'Auditory': "listening to the speaker.", 'Read/Write': "reading the words.", 'Kinesthetic': "watching the actions."}
    ),
    VarkQuestion(
      question: "I want to find out more about a new tour that I am going on. I would:",
      answers: {'Visual': "look at details about the highlights on the map.", 'Auditory': "talk with the person who planned the tour.", 'Read/Write': "read about the tour on the itinerary.", 'Kinesthetic': "look at pictures and real-life experiences."}
    ),
    VarkQuestion(
      question: "When choosing a career or area of study, these are important for me:",
      answers: {'Visual': "Working with designs, maps or charts.", 'Auditory': "Communicating with others through discussion.", 'Read/Write': "Using words well in written reports.", 'Kinesthetic': "Applying my knowledge in real situations."}
    ),
    VarkQuestion(
      question: "When I am learning I:",
      answers: {'Visual': "see patterns in things.", 'Auditory': "listen to experts.", 'Read/Write': "read books, articles and handouts.", 'Kinesthetic': "use examples and applications."}
    ),
    VarkQuestion(
      question: "I want to learn how to play a new board game or card game. I would:",
      answers: {'Visual': "use the diagrams that explain the moves.", 'Auditory': "listen to someone explaining it.", 'Read/Write': "read the instructions.", 'Kinesthetic': "play it to learn it."}
    ),
    VarkQuestion(
      question: "I have a problem with my heart. I would prefer that the doctor:",
      answers: {'Visual': "showed me a diagram.", 'Auditory': "described what was wrong.", 'Read/Write': "gave me a pamphlet.", 'Kinesthetic': "used a plastic model to show me."}
    ),
    VarkQuestion(
      question: "I want to learn to do something new on a computer. I would:",
      answers: {'Visual': "follow the diagrams in a book.", 'Auditory': "talk with people who know the program.", 'Read/Write': "read the written instructions.", 'Kinesthetic': "start using it and learn by trial and error."}
    ),
    VarkQuestion(
      question: "When I learn from a website I like:",
      answers: {'Visual': "designs and points that I can see.", 'Auditory': "audio channels where I can hear music or speakers.", 'Read/Write': "interesting written descriptions.", 'Kinesthetic': "videos showing how to do things."}
    ),
    VarkQuestion(
      question: "I prefer a presenter or a teacher who uses:",
      answers: {'Visual': "diagrams, charts or graphs.", 'Auditory': "question and answer or group discussion.", 'Read/Write': "handouts, books, or readings.", 'Kinesthetic': "demonstrations or models."}
    ),
    VarkQuestion(
      question: "I remember more from a movie when I:",
      answers: {'Visual': "see the scenery and costumes.", 'Auditory': "listen to the music and dialogue.", 'Read/Write': "read the reviews and subtitles.", 'Kinesthetic': "feel the emotions and actions."}
    ),
    VarkQuestion(
      question: "I need to learn how to take a photo with my new digital camera. I would:",
      answers: {'Visual': "look at diagrams showing how to use it.", 'Auditory': "ask someone questions about it.", 'Read/Write': "read the printed instructions.", 'Kinesthetic': "take photos and see how they look."}
    ),
    VarkQuestion(
      question: "I prefer a website that has things I can:",
      answers: {'Visual': "see.", 'Auditory': "hear.", 'Read/Write': "read.", 'Kinesthetic': "do."}
    ),
    VarkQuestion(
      question: "I have to make a brilliant speech at a special occasion. I would:",
      answers: {'Visual': "make diagrams or models.", 'Auditory': "practice saying the words over and over.", 'Read/Write': "write out my speech and learn it by reading.", 'Kinesthetic': "gather many examples and stories."}
    ),
    VarkQuestion(
      question: "I am going to buy a digital camera or mobile phone. I would be influenced by:",
      answers: {'Visual': "it looks modern and has a good design.", 'Auditory': "the salesperson telling me about it.", 'Read/Write': "reading the details about its features.", 'Kinesthetic': "trying or testing it."}
    ),
    VarkQuestion(
      question: "I want to save more money and to decide between a range of options. I would:",
      answers: {'Visual': "use graphs showing different options.", 'Auditory': "talk with an expert about the options.", 'Read/Write': "read a print brochure describing the options.", 'Kinesthetic': "consider examples of each option."}
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
      int visual = 0, auditory = 0, readWrite = 0, kinesthetic = 0;
      for (var answer in _selectedAnswers.values) {
        switch (answer) {
          case 'Visual':
            visual++;
          case 'Auditory':
            auditory++;
          case 'Read/Write':
            readWrite++;
          case 'Kinesthetic':
            kinesthetic++;
        }
      }

      final List<int> rawScores = [visual, auditory, readWrite, kinesthetic];

      // 2. API Classification (Talking to your Python AI)
      final Map<String, dynamic> aiResult = await ApiService.classifyVark(rawScores);
      final String formattedStyle = aiResult['formatted_style'] ?? 'Unknown';

      // 3. Save to Supabase Profiles Table
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'vark_scores': {
          'Visual': visual,
          'Auditory': auditory,
          'Read/Write': readWrite,
          'Kinesthetic': kinesthetic,
        },
        'primary_vark_style': formattedStyle,
      });

      // 4. Navigation
      if (mounted) {
        context.read<ProfileCubit>().watchProfile(); 

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: _selectedAnswers.length / _questions.length,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${_selectedAnswers.length} of ${_questions.length} Answered',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              ),
            ],
          ),
        ),
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