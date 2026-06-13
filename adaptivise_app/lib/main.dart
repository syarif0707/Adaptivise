import 'package:adaptivise_prototype/logic/settings_cubit.dart';
import 'package:adaptivise_prototype/presentation/analytics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'logic/auth_cubit.dart' hide AuthState;
import 'logic/folders_cubit.dart';
import 'logic/notes_cubit.dart';
import 'logic/profile_cubit.dart';
import 'logic/study_cubit.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/main_navigation_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Supabase Data Layer
  await Supabase.initialize(
    url: 'https://nnqafyfydbpspywuxhtk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ucWFmeWZ5ZGJwc3B5d3V4aHRrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYxMTIwMjcsImV4cCI6MjA5MTY4ODAyN30.SV_aAWiGMioj5GMbJ26AHpbn5TRFRUxekh7pBYcMFjE',
  );

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Error loading .env file: $e");
  }
  
  runApp(const AdaptiviseApp());
}

class AdaptiviseApp extends StatelessWidget {
  const AdaptiviseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => StudyCubit()),
        BlocProvider(create: (_) => FoldersCubit()),
        BlocProvider(create: (_) => NotesCubit()),
        BlocProvider(create: (_) => ProfileCubit()),
        BlocProvider(create: (_) => SettingsCubit()),
      ],
      child: BlocBuilder<SettingsCubit, double>( // <-- Wrap MaterialApp
        builder: (context, textScale) {
          return MaterialApp(
        title: 'Adaptivise',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScale),
                ),
                child: child!,
              );
            },
        home: const AuthWrapper(),
        // ADD THIS SECTION:
        routes: {
          '/analytics': (context) => const AnalyticsScreen(),
        },
      );
        },
      ),
    );
  }
}

/// Automatically routes users based on their login status
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final session = snapshot.data?.session;
        if (session != null) {
          // User is logged in, go to the Main Shell
          return const MainNavigationScreen();
        } else {
          // User needs to log in
          return const LoginScreen();
        }
      },
    );
  }
}