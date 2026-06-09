import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard_screen.dart';
import '../vark_questionnaire_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkVarkProfile();
  }

  Future<void> _checkVarkProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        // Not logged in? Go back to login screen.
        return; 
      }

      // Fetch the user's profile row
      final response = await Supabase.instance.client
          .from('profiles')
          .select('primary_vark_style')
          .eq('id', user.id)
          .single();

      if (mounted) {
        // If they don't have a VARK style yet, force them to take the quiz
        if (response['primary_vark_style'] == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const VarkQuestionnaireScreen()),
          );
        } else {
          // They already took the quiz! Send them to the dashboard.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint("Error checking profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // Shows briefly while checking database
      ),
    );
  }
}