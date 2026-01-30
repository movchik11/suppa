import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/auth_cubit.dart';
import 'package:supa/screens/admin/admin_home_screen.dart';
import 'package:supa/screens/auth/login_screen.dart';
import 'package:supa/screens/home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Verification or loading logic can go here if needed,
    // but BlocListener handles the navigation.
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) async {
        // Add a small delay for branding if desired, or remove it for speed.
        await Future.delayed(const Duration(seconds: 2));
        if (!context.mounted) return;

        if (state is AuthAuthenticated) {
          if (state.role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        } else if (state is AuthUnauthenticated || state is AuthError) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      },
      child: const Scaffold(
        body: Center(child: Text('Salam', style: TextStyle(fontSize: 100))),
      ),
    );
  }
}
