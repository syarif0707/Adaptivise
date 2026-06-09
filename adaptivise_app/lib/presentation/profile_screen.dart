import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vark_questionnaire_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get current user email for the profile header
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
          const SizedBox(height: 16),
          Center(child: Text(user?.email ?? 'Student', style: const TextStyle(fontSize: 18))),
          const Divider(height: 40),

          // --- THE RETEST BUTTON ---
          ListTile(
            leading: const Icon(Icons.psychology),
            title: const Text('Retake VARK Assessment'),
            subtitle: const Text('Update your dominant learning style'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // Notice isRetest is true here!
                  builder: (context) => const VarkQuestionnaireScreen(isRetest: true), 
                ),
              );
            },
          ),
          
          const Divider(),
          // You can add a Sign Out button here too!
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              // Navigate back to login screen...
            },
          ),
        ],
      ),
    );
  }
}