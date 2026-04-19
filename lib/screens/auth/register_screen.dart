import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/auth_cubit.dart';
import 'package:supa/screens/home/home_screen.dart';
import 'package:supa/screens/user/profile_setup_screen.dart';
import 'package:supa/screens/user/initial_vehicle_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supa/components/glass_container.dart';
import 'package:supa/utils/animation_utils.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  
  late AnimationController _bgAnimationController;
  late List<BackgroundBlob> _blobs;

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _blobs = List.generate(4, (index) => BackgroundBlob(seed: index));
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
          if (state.needsProfileSetup) {
            Navigator.pushAndRemoveUntil(
              context,
              AnimationUtils.createSharedAxisRoute(page: const ProfileSetupScreen()),
              (route) => false,
            );
          } else if (state.needsVehicleSetup) {
            Navigator.pushAndRemoveUntil(
              context,
              AnimationUtils.createSharedAxisRoute(page: const InitialVehicleScreen()),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              AnimationUtils.createSharedAxisRoute(page: const HomeScreen()),
              (route) => false,
            );
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            children: [
              // Animated Background
              AnimatedBuilder(
                animation: _bgAnimationController,
                builder: (context, child) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
                      ),
                    ),
                    child: CustomPaint(
                      painter: BackgroundPainter(
                        blobs: _blobs,
                        animationValue: _bgAnimationController.value,
                        isDarkMode: true,
                      ),
                      size: Size.infinite,
                    ),
                  );
                },
              ),
              
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: GlassContainer(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Hero Icon
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.withAlpha(30),
                                  border: Border.all(color: Colors.blue.withAlpha(50)),
                                ),
                                child: const Icon(Icons.person_add_rounded, size: 48, color: Colors.blueAccent),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'createAccount'.tr(),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'tagline'.tr(),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              const SizedBox(height: 48),
                              
                              // Form Fields
                              _buildTextField(
                                controller: emailController,
                                label: 'emailLabel'.tr(),
                                icon: Icons.alternate_email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'requiredField'.tr();
                                  if (!val.contains('@')) return 'invalidEmail'.tr();
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                controller: passwordController,
                                label: 'passwordLabel'.tr(),
                                icon: Icons.lock_outline_rounded,
                                isPassword: true,
                                isVisible: _isPasswordVisible,
                                toggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'requiredField'.tr();
                                  if (val.length < 6) return 'passwordTooShort'.tr();
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                controller: confirmPasswordController,
                                label: 'confirmPassword'.tr().isEmpty ? 'Confirm Password' : 'confirmPassword'.tr(),
                                icon: Icons.check_circle_outline_rounded,
                                isPassword: true,
                                isVisible: _isPasswordVisible,
                                toggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                validator: (val) {
                                  if (val != passwordController.text) return 'passwordsDoNotMatch'.tr().isEmpty ? 'Passwords do not match' : 'passwordsDoNotMatch'.tr();
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 40),
                              
                              // Submit Button
                              if (state is AuthLoading)
                                const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                              else
                                ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      context.read<AuthCubit>().register(
                                        emailController.text.trim(),
                                        passwordController.text.trim(),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 8,
                                    shadowColor: Colors.blueAccent.withAlpha(100),
                                  ),
                                  child: Text(
                                    'register'.tr().toUpperCase(),
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              
                              const SizedBox(height: 24),
                              
                              // Toggle to Login
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'alreadyHaveAccount'.tr(),
                                    style: const TextStyle(color: Colors.white60),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'login'.tr(),
                                      style: const TextStyle(
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? toggleVisibility,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.blueAccent.withAlpha(150), size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.white38,
                  size: 20,
                ),
                onPressed: toggleVisibility,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withAlpha(10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withAlpha(20)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}

class BackgroundBlob {
  double x, y, size, speedX, speedY;
  final Color color;

  BackgroundBlob({required int seed})
    : x = Random(seed).nextDouble(),
      y = Random(seed + 1).nextDouble(),
      size = 200 + Random(seed + 2).nextDouble() * 300,
      speedX = 0.001 + Random(seed + 3).nextDouble() * 0.002,
      speedY = 0.001 + Random(seed + 4).nextDouble() * 0.002,
      color = [
        Colors.blueAccent.withAlpha(40),
        Colors.purpleAccent.withAlpha(30),
        Colors.indigoAccent.withAlpha(25),
        Colors.blue.withAlpha(20),
      ][seed % 4];

  void update() {
    x += speedX;
    y += speedY;
    if (x > 1.2 || x < -0.2) speedX *= -1;
    if (y > 1.2 || y < -0.2) speedY *= -1;
  }
}

class BackgroundPainter extends CustomPainter {
  final List<BackgroundBlob> blobs;
  final double animationValue;
  final bool isDarkMode;

  BackgroundPainter({required this.blobs, required this.animationValue, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    for (var blob in blobs) {
      blob.update();
      final paint = Paint()
        ..color = blob.color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
      
      canvas.drawCircle(
        Offset(blob.x * size.width, blob.y * size.height),
        blob.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
