import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  Authenticated(this.user);
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(_initialState()) {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((change) {
      final user = change.session?.user;
      if (user != null) {
        emit(Authenticated(user));
        return;
      }

      if (change.event == AuthChangeEvent.signedOut ||
          (change.event == AuthChangeEvent.userUpdated && user == null)) {
        if (state is AuthLoading) {
          emit(AuthInitial());
        }
      }
    });
  }

  final _supabase = Supabase.instance.client;
  StreamSubscription<dynamic>? _authSubscription;

  static AuthState _initialState() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) return Authenticated(user);
    return AuthInitial();
  }

  User? _resolveUser(AuthResponse response) =>
      response.user ?? _supabase.auth.currentUser;

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = _resolveUser(response);
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(AuthError('Sign in failed. Please check your credentials.'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signUp(String email, String password) async {
    emit(AuthLoading());
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      final user = _resolveUser(response);
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(AuthError(
          'Account created. Check your email to confirm before signing in.',
        ));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.adaptivise://login-callback/',
      );
    } catch (error) {
      emit(AuthError(error.toString()));
    } finally {
      if (state is AuthLoading) {
        emit(AuthInitial());
      }
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}