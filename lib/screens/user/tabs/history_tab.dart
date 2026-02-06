import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/order_cubit.dart';
import 'package:supa/models/order_model.dart';
import 'package:supa/components/app_loading_indicator.dart';

import 'package:easy_localization/easy_localization.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderCubit, OrderState>(
      listener: (context, state) {
        if (state is OrderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'error'.tr()}: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      buildWhen: (previous, current) => current is! OrderError,
      builder: (context, state) {
        if (state is OrderLoading) {
          return const AppLoadingIndicator();
        } else if (state is OrdersLoaded) {
          if (state.orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 80,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text('noHistory'.tr()),
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
        }
        // Fallback for initial state or if we somehow get here
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor;
    String statusText;

    switch (order.status) {
      case 'completed':
        statusColor = Colors.green;
        statusText = 'completed'.tr();
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusText = 'inProgress'.tr();
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'cancelled'.tr();
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'pending'.tr();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: isDark ? Colors.transparent : Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withAlpha(100)),
                  ),
                  child: Text(
                    statusText.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      order.scheduledAt != null
                          ? '${'booked'.tr()}: ${DateFormat('MMM dd • HH:mm').format(order.scheduledAt!)}'
                          : '${'created'.tr()}: ${DateFormat('MMM dd').format(order.createdAt)}',
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.carModel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.issueDescription,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${'id_label'.tr()}: #${order.id.substring(0, 6).toUpperCase()}',
                  style: TextStyle(
                    color: Theme.of(context).disabledColor,
                    fontSize: 11,
                    fontFamily: 'Courier',
                  ),
                ),
                if (order.status == 'completed')
                  TextButton.icon(
                    onPressed: () {
                      // Repeat logic would go here
                    },
                    icon: const Icon(Icons.refresh, size: 14),
                    label: Text(
                      'repeat'.tr(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                if (order.status == 'pending' || order.status == 'in_progress')
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (bgContext) => AlertDialog(
                          title: Text('cancelOrder'.tr()),
                          content: Text('confirmCancelOrder'.tr()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(bgContext, false),
                              child: Text('no'.tr()),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(bgContext, true);
                              },
                              child: Text(
                                'yes'.tr(),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        context.read<OrderCubit>().cancelOrder(order.id);
                      }
                    },
                    icon: const Icon(
                      Icons.cancel_outlined,
                      size: 14,
                      color: Colors.red,
                    ),
                    label: Text(
                      'cancel'.tr(),
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
