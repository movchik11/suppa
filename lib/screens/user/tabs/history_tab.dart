import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/order_cubit.dart';
import 'package:supa/models/order_model.dart';
import 'package:supa/utils/haptics.dart';
import 'package:supa/components/ui/skeleton_wrapper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lottie/lottie.dart';
import 'package:supa/components/ui/order_progress_bar.dart';
import 'package:supa/components/glass_container.dart';
import 'package:supa/components/ui/bouncy_button.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        final isLoading = state is OrderInitial || state is OrderLoading;
        var orders = state is OrdersLoaded ? state.orders : <Order>[];

        if (state is OrderInitial) {
          context.read<OrderCubit>().fetchMyOrders();
          context.read<OrderCubit>().subscribeToOrders();
        }

        // Apply Smart Search Filter
        if (_searchQuery.isNotEmpty) {
          orders = orders.where((order) {
            final query = _searchQuery.toLowerCase();
            final brand = order.vehicle?.brand.toLowerCase() ?? '';
            final model =
                (order.vehicle?.model.toLowerCase() ?? '') +
                ' ' +
                order.carModel.toLowerCase();
            final desc = order.issueDescription.toLowerCase();
            final status = order.status.toLowerCase();

            return brand.contains(query) ||
                model.contains(query) ||
                desc.contains(query) ||
                status.contains(query);
          }).toList();
        }

        if (state is OrdersLoaded && orders.isEmpty && _searchQuery.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/animations/car_repair.json',
                  height: 150,
                  repeat: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'noHistory'.tr(),
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: GlassContainer(
                borderRadius: BorderRadius.circular(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'searchOrders'.tr(),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).primaryColor,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  AppHaptics.light();
                  await context.read<OrderCubit>().fetchMyOrders();
                },
                child: SkeletonWrapper(
                  isLoading: isLoading,
                  child: orders.isEmpty && _searchQuery.isNotEmpty
                      ? Center(child: Text('noMatchesFound'.tr()))
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: isLoading ? 5 : orders.length,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemBuilder: (context, index) {
                            final order = isLoading
                                ? Order(
                                    id: 'loading',
                                    userId: 'loading',
                                    carModel: 'Loading Service Name',
                                    issueDescription: 'Loading description...',
                                    status: 'pending',
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  )
                                : orders[index];
                            return _OrderHistoryCard(order: order);
                          },
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  final Order order;
  const _OrderHistoryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (order.status) {
      case 'completed':
        statusColor = Colors.green;
        statusText = 'completed'.tr();
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusText = 'inProgress'.tr();
        statusIcon = Icons.engineering;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'cancelled'.tr();
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'pending'.tr();
        statusIcon = Icons.schedule;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String dateString = order.scheduledAt != null
        ? DateFormat('dd.MM.yyyy HH:mm').format(order.scheduledAt!)
        : DateFormat('dd.MM.yyyy HH:mm').format(order.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 80 : 30),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: GlassContainer(
        child: BouncyButton(
          onPressed: () {},
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {},
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
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        dateString,
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          order.vehicle != null
                              ? Icons.directions_car
                              : Icons.build,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.carModel,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (order.vehicle != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '${order.vehicle!.brand} ${order.vehicle!.model}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              order.issueDescription,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OrderProgressBar(status: order.status),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ID: #${order.id.length >= 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 12,
                          fontFamily: 'Courier',
                        ),
                      ),
                      Row(
                        children: [
                          // Action buttons based on status
                          if (order.status == 'completed') ...[
                            // Rating removed per user request
                          ] else if (order.status == 'pending' ||
                              order.status == 'in_progress') ...[
                            OutlinedButton(
                              onPressed: () async {
                                AppHaptics.medium();
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (bgContext) => AlertDialog(
                                    title: Text('cancelOrder'.tr()),
                                    content: Text('confirmCancelOrder'.tr()),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(bgContext, false),
                                        child: Text('no'.tr()),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          AppHaptics.medium();
                                          Navigator.pop(bgContext, true);
                                        },
                                        child: Text(
                                          'yes'.tr(),
                                          style: const TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && context.mounted) {
                                  AppHaptics.success();
                                  context.read<OrderCubit>().cancelOrder(
                                    order.id,
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.red.withAlpha(100),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: Text(
                                'cancel'.tr(),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],

                          // Delete Button (Always Visible)
                          IconButton(
                            onPressed: () async {
                              AppHaptics.heavy();
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (bgContext) => AlertDialog(
                                  title: Text('deleteOrder'.tr()),
                                  content: Text('confirmDeleteOrder'.tr()),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(bgContext, false),
                                      child: Text('no'.tr()),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        AppHaptics.medium();
                                        Navigator.pop(bgContext, true);
                                      },
                                      child: Text(
                                        'yes'.tr(),
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true && context.mounted) {
                                AppHaptics.success();
                                context.read<OrderCubit>().deleteOrder(
                                  order.id,
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'deleteOrder'.tr(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
