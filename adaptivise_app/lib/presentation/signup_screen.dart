import 'package:adaptivise_prototype/presentation/auth/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // 1. You must have these controllers defined at the top of your state!
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  bool _isLoading = false; // Optional: To show a loading spinner

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Email Field ---
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            
            // --- Password Field ---
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),

            // --- SIGN UP BUTTON ---
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  // 2. THIS IS WHERE YOUR CODE GOES
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    
                    try {
                      // Tell Supabase to create the user
                      final AuthResponse res = await Supabase.instance.client.auth.signUp(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );
                      
                      // 3. Navigate to the Gatekeeper!
                      if (mounted && res.user != null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const AuthGate()),
                        );
                      }
                    } on AuthException catch (e) {
                      // Show Supabase errors (like "password too short") to the user
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.message)),
                      );
                    } catch (e) {
                      // Catch any other weird errors
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e")),
                      );
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                  child: const Text('Sign Up'),
                ),
          ],
        ),
      ),
    );
  }
}