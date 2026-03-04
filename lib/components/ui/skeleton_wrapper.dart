import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SkeletonWrapper extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Widget? skeleton;

  const SkeletonWrapper({
    super.key,
    required this.isLoading,
    required this.child,
    this.skeleton,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: isLoading,
      effect: ShimmerEffect(
        baseColor: Theme.of(context).cardColor.withAlpha(50),
        highlightColor: Theme.of(context).primaryColor.withAlpha(10),
      ),
      child: skeleton ?? child,
    );
  }
}
