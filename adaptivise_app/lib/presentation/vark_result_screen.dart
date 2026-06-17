import 'package:flutter/material.dart';
import 'package:adaptivise_prototype/presentation/main_navigation_screen.dart';

class VarkResultScreen extends StatelessWidget {
  final String learningStyleResult;

  const VarkResultScreen({super.key, required this.learningStyleResult});

  // Helper method to dynamically load the right content based on the result
  Map<String, dynamic> _getStyleConfiguration(String style) {
    final s = style.toLowerCase();
    
    if (s.contains('visual') || s == 'v') {
      return {
        'title': 'Visual',
        'image': 'assets/images/visual_symbol.png',
        'color': const Color(0xFFF97316), // Alerting Orange
        'description': 'You learn best by seeing. Unfortunately, this feature is not yet implemented.'
      };
    } else if (s.contains('auditory') || s == 'a') {
      return {
        'title': 'Auditory',
        'image': 'assets/images/auditory_symbol.png',
        'color': const Color(0xFFEC4899), // Expressive Pink
        'description': 'You learn best by listening. The app will prioritize audio summaries.'
      };
    } else if (s.contains('read') || s == 'r' || s == 'readwrite') {
      return {
        'title': 'Read/Write',
        'image': 'assets/images/readwrite_symbol.png',
        'color': const Color(0xFF22C55E), // Concentration Green
        'description': 'You learn best by reading and writing. The app will prioritize detailed text summaries and lists.'
      };
    } else {
      // Defaults to Kinesthetic
      return {
        'title': 'Kinesthetic',
        'image': 'assets/images/kinesthetic_symbol.png',
        'color': const Color(0xFF14B8A6), // Dynamic Teal
        'description': 'You learn best by doing. The app will prioritize interactive quizzes.'
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getStyleConfiguration(learningStyleResult);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Congratulatory Header
                Text(
                  "Test Complete!",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 40),

                // 2. The Symbol (Wrapped in a subtle card for emphasis)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: config['color'].withOpacity(0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    config['image'],
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 40),

                // 3. The Big Reveal
                Text(
                  "Your learning style is",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  config['title'],
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: config['color'],
                    fontWeight: FontWeight.w900,
                    fontSize: 40,
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Brief Explanation (Low cognitive load, highly scannable)
                Text(
                  config['description'],
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 56),

                // 5. Call to Action to enter the app
                FilledButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainNavigationScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Go to Dashboard',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}