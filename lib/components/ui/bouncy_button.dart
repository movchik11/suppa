import 'package:flutter/material.dart';

class BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double scaleFactor;
  final Duration duration;

  const BouncyButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.scaleFactor = 0.95,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (mounted) _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (mounted) _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    if (mounted) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
