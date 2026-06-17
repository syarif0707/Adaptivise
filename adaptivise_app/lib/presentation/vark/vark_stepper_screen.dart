import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/vark_cubit.dart';
import '../main_navigation_screen.dart';

class VarkStepperScreen extends StatefulWidget {
  const VarkStepperScreen({super.key});
  @override
  State<VarkStepperScreen> createState() => _VarkStepperScreenState();
}

class _VarkStepperScreenState extends State<VarkStepperScreen> {
  int _currentStep = 0;
  final Map<String, int> _scores = {
    'Visual': 0,
    'Auditory': 0,
    'Read/Write': 0,
    'Kinesthetic': 0,
  };

  // Example data (expand to 16 in production)
  final List<Map<String, dynamic>> _questions = [
    {
      'q': 'You are planning a holiday...',
      'opts': [
        {'t': 'Visual', 'x': 'Draw map'},
        {'t': 'A', 'x': 'Discuss'},
      ],
    },
  ];

  void _submit() {
    context.read<VarkCubit>().processVarkScores(_scores);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostic Profiling')),
      body: BlocConsumer<VarkCubit, VarkState>(
        listener: (context, state) {
          if (state is VarkSuccess) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const MainNavigationScreen(),
                  ),
                );
              } catch (e) {
                // If it still errors, it won't crash the app, it will just log it!
                debugPrint("Navigation Error: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Profile saved, but encountered a display error.',
                    ),
                  ),
                );
              }
            });
          } else if (state is VarkError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is VarkLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("AI Clustering in progress..."),
                ],
              ),
            );
          }
          return Stepper(
            type: StepperType.horizontal,
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < _questions.length - 1) {
                setState(() => _currentStep++);
              } else {
                _submit();
              }
            },
            steps: _questions
                .map(
                  (q) => Step(
                    title: const Text(""),
                    content: Text(
                      q['q'] as String,
                    ), // Implement radio buttons here like in your prototype
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
