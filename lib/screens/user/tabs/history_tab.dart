import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:supa/cubits/order_cubit.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderCubit()
        ..fetchMyOrders()
        ..subscribeToOrders(),
      child: BlocBuilder<OrderCubit, OrderState>(
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
                  Color statusColor;
                  switch (order.status) {
                    case 'pending':
                      statusColor = Colors.orange;
                    case 'in_progress':
                      statusColor = Colors.blue;
                    case 'completed':
                      statusColor = Colors.green;
                    case 'cancelled':
                      statusColor = Colors.red;
                    default:
                      statusColor = Colors.grey;
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withAlpha(51),
                        child: Icon(Icons.car_repair, color: statusColor),
                      ),
                      title: Text(
                        order.carModel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            order.issueDescription,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(
                          order.status.toUpperCase(),
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: statusColor.withAlpha(51),
                        labelStyle: TextStyle(color: statusColor),
                      ),
                      isThreeLine: true,
                    ),
                  );
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
    );
  }
}
