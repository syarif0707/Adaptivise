import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final _supabase = Supabase.instance.client;

  AuthCubit() : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final response = await _supabase.auth.signInWithPassword(email: email, password: password);
      if (response.user != null) emit(Authenticated(response.user!));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signUp(String email, String password) async {
    emit(AuthLoading());
    try {
      final response = await _supabase.auth.signUp(email: email, password: password);
      if (response.user != null) emit(Authenticated(response.user!));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final googleSignIn = GoogleSignIn.instance;

      await googleSignIn.initialize(
        serverClientId:
            '396176311722-bianpt071tfghhnmfgcbe0t96r88sj6a.apps.googleusercontent.com',
      );

      final googleUser = await googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;

      if (idToken == null) {
        throw 'Missing Google ID Token';
      }

      final authorization =
          await googleUser.authorizationClient.authorizationForScopes([]);
      final accessToken = authorization?.accessToken;

      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        emit(Authenticated(response.user!));
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        emit(AuthInitial());
        return;
      }
      emit(AuthError(e.description ?? e.code.name));
    } catch (error) {
      emit(AuthError(error.toString()));
    }
  }
}