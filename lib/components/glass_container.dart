import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double? height;
  final double? width;
  final AlignmentGeometry? alignment;
  final BorderRadius? borderRadius;
  final Gradient? borderGradient;
  final Gradient? gradient;
  final Color? color;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.1,
    this.height,
    this.width,
    this.alignment,
    this.borderRadius,
    this.borderGradient,
    this.gradient,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          height: height,
          width: width,
          alignment: alignment,
          decoration: BoxDecoration(
            color: gradient == null
                ? (color ?? Colors.white).withAlpha((opacity * 255).toInt())
                : null,
            gradient: gradient,
            borderRadius: borderRadius ?? BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(30), width: 1.0),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withAlpha(20), width: 0.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
