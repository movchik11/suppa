import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';

class OrderProgressBar extends StatelessWidget {
  final String status;

  const OrderProgressBar({super.key, required this.status});

  int _getCurrentStep() {
    switch (status) {
      case 'pending':
        return 0;
      case 'confirmed':
        return 1;
      case 'in_progress':
        return 2;
      case 'completed':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int currentStep = _getCurrentStep();
    final bool isCancelled = status == 'cancelled';

    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        width: double.infinity,
        child: Center(
          child: Text(
            'orderCancelled'.tr(),
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );
    }

    final List<String> steps = [
      'stepAuth'.tr(),
      'stepConf'.tr(),
      'stepWork'.tr(),
      'stepDone'.tr(),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Stack(
        children: [
          // Background Line
          Positioned(
            top: 15,
            left: 20,
            right: 20,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withAlpha(50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Progress Line
          Positioned(
            top: 15,
            left: 20,
            child: AnimatedContainer(
              duration: 800.ms,
              curve: Curves.easeInOut,
              height: 4,
              width:
                  (MediaQuery.of(context).size.width - 72) * (currentStep / 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withAlpha(200),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ).animate().shimmer(duration: 2.seconds, delay: 1.seconds),
          ),

          // Dots and Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (index) {
              final bool isPassed = index <= currentStep;
              final bool isCurrent = index == currentStep;

              return Column(
                children: [
                  AnimatedContainer(
                        duration: 400.ms,
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: isPassed
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).cardColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isPassed
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).dividerColor,
                            width: 2,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withAlpha(100),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: isPassed
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : Text(
                                  (index + 1).toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                        ),
                      )
                      .animate(target: isCurrent ? 1 : 0)
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.2, 1.2),
                        duration: 300.ms,
                      ),
                  const SizedBox(height: 8),
                  Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isPassed
                          ? Theme.of(context).textTheme.bodyMedium?.color
                          : Theme.of(context).hintColor,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
