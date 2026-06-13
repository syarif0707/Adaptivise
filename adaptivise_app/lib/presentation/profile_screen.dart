import 'package:adaptivise_prototype/logic/profile_cubit.dart';
import 'package:adaptivise_prototype/logic/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vark_questionnaire_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().watchProfile();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final style = state is ProfileLoaded ? state.primaryStyle : 'Not set';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user?.email ?? 'Student',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Learning style: $style',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const Divider(height: 40),
              ListTile(
                leading: const Icon(Icons.psychology),
                title: const Text('Retake VARK Assessment'),
                subtitle: const Text('Update your dominant learning style'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const VarkQuestionnaireScreen(isRetest: true),
                    ),
                  );
                },
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text("App Settings", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              ListTile(
                leading: const Icon(Icons.format_size, color: Colors.teal),
                title: const Text('Adjust Text Size'),
                subtitle: Slider(
                  value: context.watch<SettingsCubit>().state,
                  min: 0.8, // Smallest
                  max: 1.5, // Largest
                  divisions: 7,
                  activeColor: Colors.teal,
                  onChanged: (val) => context.read<SettingsCubit>().updateFontSize(val),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
