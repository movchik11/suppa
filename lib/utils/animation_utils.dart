import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

class AnimationUtils {
  static Route createSharedAxisRoute({
    required Widget page,
    SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: type,
          child: child,
        );
      },
    );
  }

  static Widget fadeThrough({
    required Widget child,
    required double animationValue,
  }) {
    return FadeThroughTransition(
      animation: AlwaysStoppedAnimation(animationValue),
      secondaryAnimation: const AlwaysStoppedAnimation(0.0),
      child: child,
    );
  }
}
