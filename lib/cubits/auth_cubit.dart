import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// States
abstract class AuthCubitState {}

class AuthInitial extends AuthCubitState {}

class AuthLoading extends AuthCubitState {}

class AuthUnauthenticated extends AuthCubitState {}

class AuthAuthenticated extends AuthCubitState {
  final User user;
  final String role;
  final bool needsProfileSetup;
  final bool needsVehicleSetup;
  AuthAuthenticated(
    this.user, {
    this.role = 'user',
    this.needsProfileSetup = false,
    this.needsVehicleSetup = false,
  });
}

class AuthError extends AuthCubitState {
  final String message;
  AuthError(this.message);
}

// Cubit
class AuthCubit extends Cubit<AuthCubitState> {
  final SupabaseClient supabase;
  final GoogleSignIn _googleSignIn;

  AuthCubit()
    : supabase = Supabase.instance.client,
      _googleSignIn = GoogleSignIn(),
      super(AuthInitial()) {
    _init();
  }

  Future<void> _init() async {
    await _checkSession();
  }

  Future<void> _checkSession() async {
    final session = supabase.auth.currentSession;
    if (session != null) {
      // 1. Try to emit from cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedRole = prefs.getString('user_role_${session.user.id}');
      if (cachedRole != null) {
        emit(AuthAuthenticated(session.user, role: cachedRole));
      }

      // 2. Fetch/Refresh from network
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
        // Optimistic UI transition
        final prefs = await SharedPreferences.getInstance();
        final cachedRole =
            prefs.getString('user_role_${response.user!.id}') ?? 'user';
        emit(AuthAuthenticated(response.user!, role: cachedRole));

        // Refresh role in background
        _fetchRoleAndEmit(response.user!);
      } else {
        emit(AuthError('Login failed: Unknown error'));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      if (kIsWeb) {
        // Use Supabase OAuth flow for web to avoid UnimplementedError
        await supabase.auth.signInWithOAuth(OAuthProvider.google);
        return;
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        emit(AuthInitial()); // User cancelled
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      if (response.user != null) {
        // Optimistic UI transition: Use cached role or default to 'user' for immediate transition
        final prefs = await SharedPreferences.getInstance();
        final cachedRole =
            prefs.getString('user_role_${response.user!.id}') ?? 'user';

        emit(AuthAuthenticated(response.user!, role: cachedRole));

        // Refresh role and update state in background without blocking the UI transition
        _fetchRoleAndEmit(response.user!);
      } else {
        emit(AuthError('Google Login failed: Unknown error'));
      }
    } catch (e) {
      emit(AuthError('Google Sign-In Error: ${e.toString()}'));
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
        // New users default to 'user' role
        emit(AuthAuthenticated(response.user!, role: 'user'));

        // Fetch role in background to ensure profile is created and cache is populated
        _fetchRoleAndEmit(response.user!);
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> _fetchRoleAndEmit(User user) async {
    try {
      // 1. Fetch profile for role and completeness
      final profileData = await supabase
          .from('profiles')
          .select('role, display_name, phone_number')
          .eq('id', user.id)
          .maybeSingle();

      final role = profileData != null ? profileData['role'] as String : 'user';
      final bool needsProfile =
          profileData == null ||
          profileData['display_name'] == null ||
          profileData['phone_number'] == null;

      // 2. Check if user has any vehicles
      final vehiclesResponse = await supabase
          .from('vehicles')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);
      final bool needsVehicle = (vehiclesResponse as List).isEmpty;

      // Cache the role
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role_${user.id}', role);

      emit(
        AuthAuthenticated(
          user,
          role: role,
          needsProfileSetup: needsProfile,
          needsVehicleSetup: needsVehicle,
        ),
      );
    } catch (e) {
      if (state is! AuthAuthenticated) {
        emit(AuthAuthenticated(user, role: 'user'));
      }
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    emit(AuthUnauthenticated());
  }
}
