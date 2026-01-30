import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double? opacity;
  final double? height;
  final double? width;
  final AlignmentGeometry? alignment;
  final BorderRadius? borderRadius;
  final Gradient? borderGradient;
  final Gradient? gradient;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity,
    this.height,
    this.width,
    this.alignment,
    this.borderRadius,
    this.borderGradient,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          height: height,
          width: width,
          alignment: alignment,
          decoration: BoxDecoration(
            color: gradient == null
                ? Colors.white.withAlpha((opacity ?? 0.2) * 255 ~/ 1)
                : null,
            gradient: gradient,
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            border: Border.all(
              color: Colors.transparent,
              width: 0,
            ), // Basic border, custom border gradient requires CustomPainter or simple border with gradient is tricky.
            // For simplicity, we'll use a simple border color if borderGradient is null, or standard white.
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(51), width: 1.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
