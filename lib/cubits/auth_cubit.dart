import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supa/services/biometric_service.dart';

// States
abstract class AuthCubitState {}

class AuthInitial extends AuthCubitState {}

class AuthLoading extends AuthCubitState {}

class AuthUnauthenticated extends AuthCubitState {}

class AuthAuthenticated extends AuthCubitState {
  final User user;
  final String role;
  final String? tenantId;
  final bool needsProfileSetup;
  final bool needsVehicleSetup;
  AuthAuthenticated(
    this.user, {
    this.role = 'user',
    this.tenantId,
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
  final BiometricService _biometricService = BiometricService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _biometricEnabledKey = 'biometric_enabled';

  AuthCubit()
    : supabase = Supabase.instance.client,
      _googleSignIn = GoogleSignIn(
        serverClientId: dotenv.env['WEB_CLIENT'],
        clientId: kIsWeb ? null : dotenv.env['IOS_CLIENT'],
      ),
      super(AuthInitial()) {
    _init();
  }

  Future<void> _init() async {
    await _checkSession();
  }

  Future<void> _checkSession() async {
    final session = supabase.auth.currentSession;
    if (session != null) {
      // Wait for true role fetch before routing
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
        // Wait for role response before emitting
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
        // Wait for role and setup check to ensure user goes to correct screen
        await _fetchRoleAndEmit(response.user!);
      } else {
        emit(AuthError('Google Login failed: No user found'));
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
        // New users default to 'user' role and MUST go through setup
        emit(
          AuthAuthenticated(
            response.user!,
            role: 'user',
            needsProfileSetup: true,
            needsVehicleSetup: true,
          ),
        );

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
      // Small delay for new sign-ups to allow Supabase triggers to create the profile row
      await Future.delayed(const Duration(seconds: 1));

      // 1. Fetch profile for role and completeness
      final profileData = await supabase
          .from('profiles')
          .select('role, display_name, phone_number, tenant_id')
          .eq('id', user.id)
          .maybeSingle();

      final role = profileData != null ? profileData['role'] as String : 'user';
      final tenantId = profileData != null
          ? profileData['tenant_id'] as String?
          : null;
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

      // Cache the role and tenantId
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role_${user.id}', role);
      if (tenantId != null) {
        await prefs.setString('user_tenant_${user.id}', tenantId);
      } else {
        await prefs.remove('user_tenant_${user.id}');
      }

      emit(
        AuthAuthenticated(
          user,
          role: role,
          tenantId: tenantId,
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
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (_) {
      // Ignore Google Sign-In signout errors if the user wasn't signed in via Google
    }
    emit(AuthUnauthenticated());
  }

  Future<void> deleteAccount() async {
    emit(AuthLoading());
    try {
      // Call the RPC function to delete from auth.users (cascades to public tables)
      await supabase.rpc('delete_user_account');

      // Clear local cache/session
      await logout();
    } catch (e) {
      emit(AuthError('Failed to delete account: ${e.toString()}'));
    }
  }

  // --- Biometric Authentication ---

  Future<void> enableBiometrics(String email, String password) async {
    try {
      await _secureStorage.write(key: 'email', value: email);
      await _secureStorage.write(key: 'password', value: password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, true);
    } catch (e) {
      // Diagnostic log removed for production
    }
  }

  Future<bool> isBiometricAvailable() =>
      _biometricService.isBiometricAvailable();

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> loginWithBiometrics() async {
    final bool available = await _biometricService.isBiometricAvailable();
    final bool enabled = await isBiometricEnabled();

    if (!available || !enabled) {
      emit(AuthError('Biometric authentication is not enabled or available.'));
      return;
    }

    final bool authenticated = await _biometricService.authenticate();
    if (authenticated) {
      final emailValue = await _secureStorage.read(key: 'email');
      final passwordValue = await _secureStorage.read(key: 'password');

      if (emailValue != null && passwordValue != null) {
        await login(emailValue, passwordValue);
      } else {
        emit(
          AuthError('No saved credentials found. Please login normally once.'),
        );
      }
    }
  }
}
