import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
            builder: (context, state) {
              if (state is AuthLoading) return const Center(child: CircularProgressIndicator());
              
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Adaptivise", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 40),
                  TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.read<AuthCubit>().login(_email.text.trim(), _pass.text.trim()),
                    child: const Text('Login'),
                  ),
                  TextButton(
                    onPressed: () => context.read<AuthCubit>().signUp(_email.text.trim(), _pass.text.trim()),
                    child: const Text("Don't have an account? Sign Up"),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}