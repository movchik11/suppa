import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:supa/cubits/order_cubit.dart';
import 'package:supa/cubits/theme_cubit.dart';
import 'package:supa/models/order_model.dart';
import 'package:supa/screens/user/chat_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class OrdersManagementScreen extends StatelessWidget {
  const OrdersManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderCubit()..fetchAllOrders(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('manageOrders'.tr()),
          actions: [
            PopupMenuButton<Locale>(
              icon: const Icon(Icons.language),
              onSelected: (locale) {
                context.setLocale(locale);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: Locale('en'),
                  child: Text('English'),
                ),
                const PopupMenuItem(
                  value: Locale('ru'),
                  child: Text('Русский'),
                ),
                const PopupMenuItem(
                  value: Locale('tk'),
                  child: Text('Türkmençe'),
                ),
              ],
            ),
            BlocBuilder<ThemeCubit, bool>(
              builder: (context, isLight) {
                return IconButton(
                  icon: Icon(isLight ? Icons.dark_mode : Icons.light_mode),
                  onPressed: () => context.read<ThemeCubit>().toggleTheme(),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<OrderCubit>().fetchAllOrders(),
            ),
          ],
        ),
        body: BlocBuilder<OrderCubit, OrderState>(
          builder: (context, state) {
            if (state is OrderLoading) {
              return Center(
                child: Lottie.asset(
                  'assets/animations/loading.json',
                  height: 200,
                  errorBuilder: (context, error, stackTrace) =>
                      const CircularProgressIndicator(),
                ),
              );
            } else if (state is OrdersLoaded) {
              if (state.orders.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No orders yet'),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => context.read<OrderCubit>().fetchAllOrders(),
                child: ListView.builder(
                  itemCount: state.orders.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final order = state.orders[index];
                    return _OrderCard(order: order);
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
                    Text(state.message),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  Color _getStatusColor() {
    switch (order.status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (order.status) {
      case 'pending':
        return Icons.pending;
      case 'in_progress':
        return Icons.build;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        leading: Icon(_getStatusIcon(), color: _getStatusColor()),
        title: Text(
          order.carModel,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _formatDate(order.createdAt),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
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
            ),
            Chip(
              label: Text(
                order.status.toUpperCase(),
                style: const TextStyle(fontSize: 10),
              ),
              backgroundColor: _getStatusColor().withAlpha(51),
              labelStyle: TextStyle(color: _getStatusColor()),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Issue Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(order.issueDescription),
                const SizedBox(height: 16),
                const Text(
                  'Change Status:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _StatusButton(
                      label: 'Pending',
                      status: 'pending',
                      orderId: order.id,
                      currentStatus: order.status,
                    ),
                    _StatusButton(
                      label: 'In Progress',
                      status: 'in_progress',
                      orderId: order.id,
                      currentStatus: order.status,
                    ),
                    _StatusButton(
                      label: 'Completed',
                      status: 'completed',
                      orderId: order.id,
                      currentStatus: order.status,
                    ),
                    _StatusButton(
                      label: 'Cancelled',
                      status: 'cancelled',
                      orderId: order.id,
                      currentStatus: order.status,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final String status;
  final String orderId;
  final String currentStatus;

  const _StatusButton({
    required this.label,
    required this.status,
    required this.orderId,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentStatus == status;
    return ElevatedButton(
      onPressed: isActive
          ? null
          : () {
              context.read<OrderCubit>().updateOrderStatus(orderId, status);
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.deepPurple : Colors.grey[300],
        foregroundColor: isActive ? Colors.white : Colors.black87,
      ),
      child: Text(label),
    );
  }
}
