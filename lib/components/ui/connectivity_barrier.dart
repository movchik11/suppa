import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';

class ConnectivityBarrier extends StatelessWidget {
  final Widget child;

  const ConnectivityBarrier({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final connectivity = snapshot.data;
        final isOffline =
            connectivity != null &&
            connectivity.contains(ConnectivityResult.none);

        return Stack(
          children: [
            child,
            if (isOffline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: SafeArea(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withAlpha(230),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(50),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.wifi_off, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Отсутствует интернет-соединение',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().slideY(begin: -1, end: 0).fadeIn(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
