import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  const AnimatedGradientBackground({super.key, required this.child});

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Base background
            Container(color: Theme.of(context).scaffoldBackgroundColor),

            // Animated Gradients
            Positioned.fill(
              child: CustomPaint(
                painter: _GradientPainter(
                  animation: _controller.value,
                  isDark: isDark,
                  primaryColor: Colors.deepPurple.withAlpha(isDark ? 50 : 30),
                  secondaryColor: Colors.blue.withAlpha(isDark ? 40 : 20),
                ),
              ),
            ),

            // Content
            widget.child,
          ],
        );
      },
    );
  }
}

class _GradientPainter extends CustomPainter {
  final double animation;
  final bool isDark;
  final Color primaryColor;
  final Color secondaryColor;

  _GradientPainter({
    required this.animation,
    required this.isDark,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    // First Blob
    final x1 = size.width * (0.5 + 0.3 * math.cos(animation * 2 * math.pi));
    final y1 = size.height * (0.3 + 0.2 * math.sin(animation * 2 * math.pi));
    canvas.drawCircle(Offset(x1, y1), 200, paint..color = primaryColor);

    // Second Blob
    final x2 =
        size.width * (0.4 + 0.3 * math.sin(animation * 2 * math.pi + math.pi));
    final y2 = size.height * (0.7 + 0.2 * math.cos(animation * 2 * math.pi));
    canvas.drawCircle(Offset(x2, y2), 250, paint..color = secondaryColor);
  }

  @override
  bool shouldRepaint(covariant _GradientPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
