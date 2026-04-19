import 'dart:math';
import 'package:supa/screens/admin/admin_home_screen.dart';
import 'package:supa/screens/admin/mechanic_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/components/glass_container.dart';
import 'package:supa/cubits/auth_cubit.dart';
import 'package:supa/screens/auth/register_screen.dart';
import 'package:supa/screens/home/home_screen.dart';
import 'package:supa/screens/user/profile_setup_screen.dart';
import 'package:supa/screens/user/initial_vehicle_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supa/utils/animation_utils.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final email = TextEditingController();
  final password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthCubitState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else if (state is AuthAuthenticated) {
          _navigateToHome(state);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F0F1E),
          body: Stack(
            children: [
              // Animated Background
              _buildAnimatedBackground(),
              
              // Blur Content
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Logo/Icon
                        _buildLogo(),
                        const SizedBox(height: 40),
                        
                        // Login Glass Card
                        GlassContainer(
                          blur: 20,
                          opacity: 0.08,
                          borderRadius: BorderRadius.circular(30),
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'login'.tr(),
                                    style: GoogleFonts.outfit(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'loginToContinue'.tr(),
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: Colors.white60,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  
                                  _buildTextField(
                                    controller: email,
                                    label: 'emailLabel'.tr(),
                                    icon: Icons.alternate_email_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTextField(
                                    controller: password,
                                    label: 'passwordLabel'.tr(),
                                    icon: Icons.lock_outline_rounded,
                                    isPassword: true,
                                    isVisible: _isPasswordVisible,
                                    onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                  ),
                                  const SizedBox(height: 40),
                                  
                                  state is AuthLoading
                                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF673AB7)))
                                      : _buildLoginButton(),
                                  const SizedBox(height: 24),
                                  
                                  _buildRegisterLink(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        _buildSocialLogin(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToHome(AuthAuthenticated state) {
    Widget target;
    if (state.role == 'admin') {
      target = const AdminHomeScreen();
    } else if (state.role == 'mechanic') {
      target = const MechanicHomeScreen();
    } else if (state.needsProfileSetup) {
      target = const ProfileSetupScreen();
    } else if (state.needsVehicleSetup) {
      target = const InitialVehicleScreen();
    } else {
      target = const HomeScreen();
    }
    
    Navigator.pushAndRemoveUntil(
      context,
      AnimationUtils.createSharedAxisRoute(page: target),
      (route) => false,
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F0F1E),
                    Color(0xFF1A1A2E),
                    Color(0xFF16213E),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -100 + (sin(_animationController.value * 2 * pi) * 50),
              left: -50 + (cos(_animationController.value * 2 * pi) * 100),
              child: _CircleBlob(size: 300, color: const Color(0xFF673AB7).withAlpha(40)),
            ),
            Positioned(
              bottom: -50 + (cos(_animationController.value * 2 * pi) * 80),
              right: -50 + (sin(_animationController.value * 2 * pi) * 120),
              child: _CircleBlob(size: 250, color: const Color(0xFF3F51B5).withAlpha(40)),
            ),
            Positioned(
              top: 200 + (sin(_animationController.value * 1.5 * pi) * 100),
              right: 100 + (cos(_animationController.value * 1.5 * pi) * 50),
              child: _CircleBlob(size: 150, color: const Color(0xFF03DAC6).withAlpha(20)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF673AB7), Color(0xFF512DA8)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF673AB7).withAlpha(100),
              blurRadius: 30,
              spreadRadius: 5,
            )
          ],
        ),
        child: const Icon(
          Icons.car_repair_rounded,
          color: Colors.white,
          size: 60,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !isVisible,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white38, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Colors.white38,
                      size: 20,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withAlpha(10),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.white.withAlpha(10)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFF673AB7), width: 1.5),
            ),
            errorStyle: const TextStyle(color: Colors.redAccent),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required field';
            }
            if (!isPassword && !value.contains('@')) {
              return 'Invalid email';
            }
            if (isPassword && value.length < 6) {
              return 'At least 6 chars';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFF673AB7), Color(0xFF3F51B5)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF673AB7).withAlpha(60),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            context.read<AuthCubit>().login(email.text, password.text);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(
          'login'.tr(),
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'dontHaveAccount'.tr(),
          style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              AnimationUtils.createSharedAxisRoute(page: const RegisterScreen()),
            );
          },
          child: Text(
            'register'.tr(),
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
        Text(
          'OR'.tr(),
          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12, letterSpacing: 2),
        ),
        const SizedBox(height: 24),
        InkWell(
          onTap: () => context.read<AuthCubit>().signInWithGoogle(),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(5),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withAlpha(10)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/icon/google.png', height: 20),
                const SizedBox(width: 12),
                Text(
                  'Sign in with Google',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _CircleBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
