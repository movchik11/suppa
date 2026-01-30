import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:supa/cubits/order_cubit.dart';
import 'package:supa/models/order_model.dart';
import 'package:supa/components/app_loading_indicator.dart';
import 'package:intl/intl.dart';
import 'package:supa/screens/user/chat_screen.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderCubit, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading) {
          return const AppLoadingIndicator();
        } else if (state is OrdersLoaded) {
          if (state.orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animations/scanning_docs.json',
                    height: 200,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.inbox, size: 80, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  const Text('No orders yet'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<OrderCubit>().fetchMyOrders(),
            child: ListView.builder(
              itemCount: state.orders.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final order = state.orders[index];
                return _OrderHistoryCard(order: order);
              },
            ),
          );
        } else if (state is OrderError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 80, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load history: ${state.message}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  final Order order;
  const _OrderHistoryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusSteps = ['pending', 'confirmed', 'in_progress', 'completed'];
    final currentStep = statusSteps.indexOf(order.status);
    final isCancelled = order.status == 'cancelled';

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.carModel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      DateFormat(
                        'MMM dd, yyyy • HH:mm',
                      ).format(order.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                if (order.status == 'completed')
                  TextButton.icon(
                    onPressed: () {
                      // Repeat order logic (navigates to create order with same details)
                    },
                    icon: const Icon(Icons.replay_outlined, size: 16),
                    label: const Text('Repeat'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
              ],
            ),
            const Divider(height: 32),
            if (isCancelled)
              const Center(
                child: Text(
                  'ORDER CANCELLED',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              )
            else
              _buildProgressIndicator(currentStep),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.issueDescription,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                Text(
                  'ID: ${order.id.substring(0, 8).toUpperCase()}',
                  style: TextStyle(
                    color: Colors.blue.withAlpha(153),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (!isCancelled) ...[
              const Divider(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          orderId: order.id,
                          serviceName: order.carModel,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Chat with Master'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: BorderSide(color: Colors.blue.withAlpha(77)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int currentStep) {
    final steps = ['Auth', 'Conf', 'Work', 'Done'];
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index <= currentStep;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.blue : Colors.white12,
                      shape: BoxShape.circle,
                      border: isActive
                          ? null
                          : Border.all(color: Colors.white24),
                    ),
                    child: Icon(
                      isActive ? Icons.check : Icons.circle,
                      size: 14,
                      color: isActive ? Colors.white : Colors.white24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive ? Colors.blue : Colors.grey,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 14),
                    color: index < currentStep ? Colors.blue : Colors.white12,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
