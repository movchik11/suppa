import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// States
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  final String role;
  AuthAuthenticated(this.user, {this.role = 'user'});
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// Cubit
class AuthCubit extends Cubit<AuthState> {
  final SupabaseClient supabase;

  AuthCubit() : supabase = Supabase.instance.client, super(AuthInitial()) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(Duration.zero); // Ensure next event loop for listeners
    final session = supabase.auth.currentSession;
    if (session != null && session.user != null) {
      await _fetchRoleAndEmit(session.user);
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await _fetchRoleAndEmit(response.user!);
      } else {
        emit(AuthError('Login failed: Unknown error'));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> register(String email, String password) async {
    emit(AuthLoading());
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {
        // New users are 'user' by default via trigger, so we can just emit 'user' or fetch it.
        // Fetching is safer to be consistent.
        await _fetchRoleAndEmit(response.user!);
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> _fetchRoleAndEmit(User user) async {
    try {
      final data = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      final role = data != null ? data['role'] as String : 'user';
      emit(AuthAuthenticated(user, role: role));
    } catch (e) {
      // Fallback to 'user' if fetching profile fails
      emit(AuthAuthenticated(user, role: 'user'));
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    emit(AuthInitial());
  }
}
