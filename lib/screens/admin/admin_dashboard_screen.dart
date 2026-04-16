import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/order_cubit.dart';
import 'package:supa/cubits/auth_cubit.dart';
import 'package:supa/cubits/theme_cubit.dart';
import 'package:supa/components/ui/skeleton_wrapper.dart';
import 'package:supa/utils/haptics.dart';
import 'package:easy_localization/easy_localization.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String? _selectedTenantId;
  bool _isAdmin = false;
  List<Map<String, dynamic>> _tenants = [];

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _isAdmin = authState.role == 'admin';
      _selectedTenantId = authState.tenantId;
    }
    if (_isAdmin) {
      _fetchTenants();
    }
  }

  Future<void> _fetchTenants() async {
    try {
      final supabase = context.read<AuthCubit>().supabase;
      final data = await supabase
          .from('tenants')
          .select('id, name')
          .order('name');
      if (mounted) {
        setState(() {
          _tenants = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          OrderCubit(tenantId: _selectedTenantId)..fetchAllOrders(),
      key: ValueKey(
        _selectedTenantId,
      ), // Re-create cubit when tenant selection changes
      child: Scaffold(
        appBar: AppBar(
          title: Text('dashboard'.tr()),
          bottom: _isAdmin && _tenants.isNotEmpty
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor.withAlpha(150),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withAlpha(50),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedTenantId,
                          isExpanded: true,
                          hint: Text(
                            'allServiceCenters'.tr().isEmpty
                                ? 'All Service Centers'
                                : 'allServiceCenters'.tr(),
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                'allServiceCenters'.tr().isEmpty
                                    ? 'All Service Centers'
                                    : 'allServiceCenters'.tr(),
                              ),
                            ),
                            ..._tenants.map(
                              (t) => DropdownMenuItem(
                                value: t['id'] as String,
                                child: Text(t['name'] as String),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            AppHaptics.selection();
                            setState(() => _selectedTenantId = val);
                          },
                        ),
                      ),
                    ),
                  ),
                )
              : null,
          actions: [
            BlocBuilder<ThemeCubit, bool>(
              builder: (context, isLight) {
                return IconButton(
                  icon: Icon(isLight ? Icons.dark_mode : Icons.light_mode),
                  onPressed: () {
                    AppHaptics.selection();
                    context.read<ThemeCubit>().toggleTheme();
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                AppHaptics.light();
                context.read<OrderCubit>().fetchAllOrders();
              },
            ),
          ],
        ),
        body: BlocBuilder<OrderCubit, OrderState>(
          builder: (context, state) {
            if (state is OrderLoading || state is OrdersLoaded) {
              final orders = state is OrdersLoaded ? state.orders : [];
              final isLoading = state is OrderLoading;

              // Calculate statistics (with defaults for loading state)
              final total = orders.length;
              final pending = orders.where((o) => o.status == 'pending').length;
              final inProgress = orders
                  .where((o) => o.status == 'in_progress')
                  .length;
              final completed = orders
                  .where((o) => o.status == 'completed')
                  .length;
              final cancelled = orders
                  .where((o) => o.status == 'cancelled')
                  .length;

              // Revenue calculation
              final totalRevenue = orders
                  .where((o) => o.status == 'completed' && o.totalPrice != null)
                  .fold<double>(
                    0,
                    (sum, order) => sum + (order.totalPrice ?? 0),
                  );

              // daily revenue for chart
              final Map<String, double> dailyRevenue = {};
              for (var order in orders.where((o) => o.status == 'completed')) {
                final dateKey = DateFormat('MM/dd').format(order.createdAt);
                dailyRevenue[dateKey] =
                    (dailyRevenue[dateKey] ?? 0) + (order.totalPrice ?? 0);
              }
              final List<MapEntry<String, double>> chartData =
                  dailyRevenue.entries.toList()
                    ..sort((a, b) => a.key.compareTo(b.key));

              return RefreshIndicator(
                onRefresh: () async {
                  AppHaptics.light();
                  await context.read<OrderCubit>().fetchAllOrders();
                },
                child: SkeletonWrapper(
                  isLoading: isLoading,
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
                                title: 'totalOrders'.tr(),
                                value: isLoading ? '00' : total.toString(),
                                icon: Icons.receipt_long,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'pending'.tr(),
                                value: isLoading ? '00' : pending.toString(),
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
                                title: 'inProgress'.tr(),
                                value: isLoading ? '00' : inProgress.toString(),
                                icon: Icons.build,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'completed'.tr(),
                                value: isLoading ? '00' : completed.toString(),
                                icon: Icons.check_circle,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _StatCard(
                          title: 'totalRevenue'.tr(),
                          value: isLoading
                              ? '000.00 TMT'
                              : '${totalRevenue.toStringAsFixed(2)} TMT',
                          icon: Icons.monetization_on,
                          color: Colors.teal,
                        ),
                        const SizedBox(height: 12),
                        const SizedBox(height: 32),

                        // Pie Chart
                        if (isLoading || total > 0) ...[
                          Text(
                            'orderStatusDistribution'.tr(),
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
                                    child: isLoading
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : PieChart(
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
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                if (inProgress > 0)
                                                  PieChartSectionData(
                                                    value: inProgress
                                                        .toDouble(),
                                                    title: '$inProgress',
                                                    color: Colors.blue,
                                                    radius: 80,
                                                    titleStyle: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                      if (isLoading || pending > 0)
                                        _LegendItem(
                                          color: Colors.orange,
                                          label: 'pending'.tr(),
                                          count: pending,
                                        ),
                                      if (isLoading || inProgress > 0)
                                        _LegendItem(
                                          color: Colors.blue,
                                          label: 'inProgress'.tr(),
                                          count: inProgress,
                                        ),
                                      if (isLoading || completed > 0)
                                        _LegendItem(
                                          color: Colors.green,
                                          label: 'completed'.tr(),
                                          count: completed,
                                        ),
                                      if (isLoading || cancelled > 0)
                                        _LegendItem(
                                          color: Colors.red,
                                          label: 'cancelled'.tr(),
                                          count: cancelled,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Revenue Line Chart
                          if (isLoading || chartData.isNotEmpty) ...[
                            Text(
                              'revenueTrend'.tr(),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: SizedBox(
                                  height: 250,
                                  child: isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : LineChart(
                                          LineChartData(
                                            gridData: const FlGridData(
                                              show: false,
                                            ),
                                            titlesData: FlTitlesData(
                                              bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  getTitlesWidget: (value, meta) {
                                                    if (value.toInt() < 0 ||
                                                        value.toInt() >=
                                                            chartData.length) {
                                                      return const SizedBox.shrink();
                                                    }
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 8.0,
                                                          ),
                                                      child: Text(
                                                        chartData[value.toInt()]
                                                            .key,
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            borderData: FlBorderData(
                                              show: false,
                                            ),
                                            lineBarsData: [
                                              LineChartBarData(
                                                spots: List.generate(
                                                  chartData.length,
                                                  (i) => FlSpot(
                                                    i.toDouble(),
                                                    chartData[i].value,
                                                  ),
                                                ),
                                                isCurved: true,
                                                color: Colors.teal,
                                                dotData: const FlDotData(
                                                  show: true,
                                                ),
                                                belowBarData: BarAreaData(
                                                  show: true,
                                                  color: Colors.teal.withAlpha(
                                                    51,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ] else
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                'noOrdersToStatistics'.tr(),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                      ],
                    ),
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
