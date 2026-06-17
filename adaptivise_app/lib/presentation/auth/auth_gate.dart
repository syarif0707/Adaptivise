import 'package:adaptivise_prototype/presentation/main_navigation_screen.dart';
import 'package:adaptivise_prototype/presentation/vark_questionnaire_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _checkVarkProfile();
  }

  Future<void> _checkVarkProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
        return;
      }

      final response = await Supabase.instance.client
          .from('profiles')
          .select('primary_vark_style')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (response == null || response['primary_vark_style'] == null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const VarkQuestionnaireScreen(),
          ),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const MainNavigationScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error routing user: $e');
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _hasError
            ? const Text(
                'Error connecting to database. Please restart the app.',
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
