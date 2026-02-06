import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/order_cubit.dart';
import 'package:supa/cubits/theme_cubit.dart';
import 'package:easy_localization/easy_localization.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderCubit()..fetchAllOrders(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('dashboard'.tr()),
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
              return const Center(child: CircularProgressIndicator());
            } else if (state is OrdersLoaded) {
              // Calculate statistics
              final total = state.orders.length;
              final pending = state.orders
                  .where((o) => o.status == 'pending')
                  .length;
              final inProgress = state.orders
                  .where((o) => o.status == 'in_progress')
                  .length;
              final completed = state.orders
                  .where((o) => o.status == 'completed')
                  .length;
              final cancelled = state.orders
                  .where((o) => o.status == 'cancelled')
                  .length;

              return RefreshIndicator(
                onRefresh: () => context.read<OrderCubit>().fetchAllOrders(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statistics Cards
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Total Orders',
                              value: total.toString(),
                              icon: Icons.receipt_long,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Pending',
                              value: pending.toString(),
                              icon: Icons.pending,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'In Progress',
                              value: inProgress.toString(),
                              icon: Icons.build,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Completed',
                              value: completed.toString(),
                              icon: Icons.check_circle,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Pie Chart
                      if (total > 0) ...[
                        Text(
                          'Order Status Distribution',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 250,
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 60,
                                      sections: [
                                        if (pending > 0)
                                          PieChartSectionData(
                                            value: pending.toDouble(),
                                            title: '$pending',
                                            color: Colors.orange,
                                            radius: 80,
                                            titleStyle: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        if (inProgress > 0)
                                          PieChartSectionData(
                                            value: inProgress.toDouble(),
                                            title: '$inProgress',
                                            color: Colors.blue,
                                            radius: 80,
                                            titleStyle: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        if (completed > 0)
                                          PieChartSectionData(
                                            value: completed.toDouble(),
                                            title: '$completed',
                                            color: Colors.green,
                                            radius: 80,
                                            titleStyle: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        if (cancelled > 0)
                                          PieChartSectionData(
                                            value: cancelled.toDouble(),
                                            title: '$cancelled',
                                            color: Colors.red,
                                            radius: 80,
                                            titleStyle: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Legend
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    if (pending > 0)
                                      _LegendItem(
                                        color: Colors.orange,
                                        label: 'Pending',
                                        count: pending,
                                      ),
                                    if (inProgress > 0)
                                      _LegendItem(
                                        color: Colors.blue,
                                        label: 'In Progress',
                                        count: inProgress,
                                      ),
                                    if (completed > 0)
                                      _LegendItem(
                                        color: Colors.green,
                                        label: 'Completed',
                                        count: completed,
                                      ),
                                    if (cancelled > 0)
                                      _LegendItem(
                                        color: Colors.red,
                                        label: 'Cancelled',
                                        count: cancelled,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'No orders yet to display statistics',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                    ],
                  ),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text('$label ($count)', style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
