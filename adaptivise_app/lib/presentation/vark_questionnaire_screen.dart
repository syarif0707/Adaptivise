import 'package:adaptivise_prototype/presentation/main_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/profile_cubit.dart';
import '../../logic/vark_cubit.dart';
import 'vark_result_screen.dart';

class VarkQuestion {
  final String question;
  final Map<String, String> answers;
  VarkQuestion({required this.question, required this.answers});
}

class VarkQuestionnaireScreen extends StatefulWidget {
  final bool isRetest;
  const VarkQuestionnaireScreen({super.key, this.isRetest = false});

  @override
  State<VarkQuestionnaireScreen> createState() =>
      _VarkQuestionnaireScreenState();
}

class _VarkQuestionnaireScreenState extends State<VarkQuestionnaireScreen> {
  final List<VarkQuestion> _questions = [
    VarkQuestion(
      question: "I need to find the way to a shop that a friend has recommended. I would:",
      answers: {
        'Visual': "use a map.",
        'Auditory': "ask my friend to tell me the directions.",
        'Read/Write': "write down the street directions.",
        'Kinesthetic': "find the shop by walking or riding there.",
      },
    ),
    VarkQuestion(
      question: "A website has a video showing how to make a special graph or chart. I would learn most from:",
      answers: {
        'Visual': "seeing the diagrams.",
        'Auditory': "listening to the speaker.",
        'Read/Write': "reading the words.",
        'Kinesthetic': "watching the actions.",
      },
    ),
    VarkQuestion(
      question: "I want to find out more about a new tour that I am going on. I would:",
      answers: {
        'Visual': "look at details about the highlights on the map.",
        'Auditory': "talk with the person who planned the tour.",
        'Read/Write': "read about the tour on the itinerary.",
        'Kinesthetic': "look at pictures and real-life experiences.",
      },
    ),
    VarkQuestion(
      question: "When choosing a career or area of study, these are important for me:",
      answers: {
        'Visual': "Working with designs, maps or charts.",
        'Auditory': "Communicating with others through discussion.",
        'Read/Write': "Using words well in written reports.",
        'Kinesthetic': "Applying my knowledge in real situations.",
      },
    ),
    VarkQuestion(
      question: "When I am learning I:",
      answers: {
        'Visual': "see patterns in things.",
        'Auditory': "listen to experts.",
        'Read/Write': "read books, articles and handouts.",
        'Kinesthetic': "use examples and applications.",
      },
    ),
    VarkQuestion(
      question: "I want to learn how to play a new board game or card game. I would:",
      answers: {
        'Visual': "use the diagrams that explain the moves.",
        'Auditory': "listen to someone explaining it.",
        'Read/Write': "read the instructions.",
        'Kinesthetic': "play it to learn it.",
      },
    ),
    VarkQuestion(
      question: "I have a problem with my heart. I would prefer that the doctor:",
      answers: {
        'Visual': "showed me a diagram.",
        'Auditory': "described what was wrong.",
        'Read/Write': "gave me a pamphlet.",
        'Kinesthetic': "used a plastic model to show me.",
      },
    ),
    VarkQuestion(
      question: "I want to learn to do something new on a computer. I would:",
      answers: {
        'Visual': "follow the diagrams in a book.",
        'Auditory': "talk with people who know the program.",
        'Read/Write': "read the written instructions.",
        'Kinesthetic': "start using it and learn by trial and error.",
      },
    ),
    VarkQuestion(
      question: "When I learn from a website I like:",
      answers: {
        'Visual': "designs and points that I can see.",
        'Auditory': "audio channels where I can hear music or speakers.",
        'Read/Write': "interesting written descriptions.",
        'Kinesthetic': "videos showing how to do things.",
      },
    ),
    VarkQuestion(
      question: "I prefer a presenter or a teacher who uses:",
      answers: {
        'Visual': "diagrams, charts or graphs.",
        'Auditory': "question and answer or group discussion.",
        'Read/Write': "handouts, books, or readings.",
        'Kinesthetic': "demonstrations or models.",
      },
    ),
    VarkQuestion(
      question: "I remember more from a movie when I:",
      answers: {
        'Visual': "see the scenery and costumes.",
        'Auditory': "listen to the music and dialogue.",
        'Read/Write': "read the reviews and subtitles.",
        'Kinesthetic': "feel the emotions and actions.",
      },
    ),
    VarkQuestion(
      question: "I need to learn how to take a photo with my new digital camera. I would:",
      answers: {
        'Visual': "look at diagrams showing how to use it.",
        'Auditory': "ask someone questions about it.",
        'Read/Write': "read the printed instructions.",
        'Kinesthetic': "take photos and see how they look.",
      },
    ),
    VarkQuestion(
      question: "I prefer a website that has things I can:",
      answers: {
        'Visual': "see.",
        'Auditory': "hear.",
        'Read/Write': "read.",
        'Kinesthetic': "do.",
      },
    ),
    VarkQuestion(
      question: "I have to make a brilliant speech at a special occasion. I would:",
      answers: {
        'Visual': "make diagrams or models.",
        'Auditory': "practice saying the words over and over.",
        'Read/Write': "write out my speech and learn it by reading.",
        'Kinesthetic': "gather many examples and stories.",
      },
    ),
    VarkQuestion(
      question: "I am going to buy a digital camera or mobile phone. I would be influenced by:",
      answers: {
        'Visual': "it looks modern and has a good design.",
        'Auditory': "the salesperson telling me about it.",
        'Read/Write': "reading the details about its features.",
        'Kinesthetic': "trying or testing it.",
      },
    ),
    VarkQuestion(
      question: "I want to save more money and to decide between a range of options. I would:",
      answers: {
        'Visual': "use graphs showing different options.",
        'Auditory': "talk with an expert about the options.",
        'Read/Write': "read a print brochure describing the options.",
        'Kinesthetic': "consider examples of each option.",
      },
    ),
  ];

  final Map<int, String> _selectedAnswers = {};

  void _submitQuiz() {
    // 1. Validate that all questions are answered
    if (_selectedAnswers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all 16 questions before submitting.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 2. Tally the scores
    int visual = 0, auditory = 0, readWrite = 0, kinesthetic = 0;
    for (var answer in _selectedAnswers.values) {
      switch (answer) {
        case 'Visual':
          visual++;
          break;
        case 'Auditory':
          auditory++;
          break;
        case 'Read/Write':
          readWrite++;
          break;
        case 'Kinesthetic':
          kinesthetic++;
          break;
      }
    }

    // 3. Create the score map requested by VarkCubit
    final Map<String, int> scores = {
      'Visual': visual,
      'Auditory': auditory,
      'Read/Write': readWrite,
      'Kinesthetic': kinesthetic,
    };

    context.read<VarkCubit>().processVarkScores(scores);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isRetest
              ? 'Retest VARK Profile'
              : 'Discover Your Learning Style',
        ),
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      
      // Wrap the body in a BlocConsumer to listen to the VarkCubit
      body: BlocConsumer<VarkCubit, VarkState>(
        listener: (context, state) {
          if (state is VarkSuccess) {
            context.read<ProfileCubit>().watchProfile();

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => VarkResultScreen(
                  learningStyleResult: state.style,
                ),
              ),
              (route) => false,
            );
          } else if (state is VarkError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          // Show loading UI while Python API processes
          if (state is VarkLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.teal),
                  SizedBox(height: 16),
                  Text("Analyzing your learning style...", style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          // Show Questionnaire
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _questions.length + 1,
            itemBuilder: (context, index) {
              // The Submit Button at the bottom
              if (index == _questions.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: FilledButton(
                    onPressed: _submitQuiz,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Submit & Discover My Style', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                );
              }

              // The Questions
              final q = _questions[index];
              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${index + 1}. ${q.question}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937)
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...q.answers.entries.map((entry) {
                        return RadioListTile<String>(
                          title: Text(entry.value, style: const TextStyle(fontSize: 15)),
                          value: entry.key,
                          groupValue: _selectedAnswers[index],
                          activeColor: Colors.teal,
                          contentPadding: EdgeInsets.zero,
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
          );
        },
      ),
    );
  }
}