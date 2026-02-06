import 'package:flutter/material.dart';

class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final String? message;

  const AppLoadingIndicator({super.key, this.size = 150, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: size * 0.4,
            width: size * 0.4,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF673AB7)),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
