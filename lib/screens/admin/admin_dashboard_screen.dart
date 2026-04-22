import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/order_cubit.dart';
import 'package:supa/cubits/auth_cubit.dart';
import 'package:supa/utils/haptics.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supa/models/order_model.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String? tenantId;
  const AdminDashboardScreen({super.key, this.tenantId});

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
      _selectedTenantId = widget.tenantId ?? authState.tenantId;
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
      create: (context) => OrderCubit(tenantId: _selectedTenantId)..fetchAllOrders(),
      key: ValueKey(_selectedTenantId),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: BlocBuilder<OrderCubit, OrderState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () async => context.read<OrderCubit>().fetchAllOrders(),
              color: Colors.blueAccent,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Immersive Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'management'.tr(),
                                style: GoogleFonts.outfit(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, color: Colors.white),
                                onPressed: () {
                                  AppHaptics.light();
                                  context.read<OrderCubit>().fetchAllOrders();
                                },
                              ),
                            ],
                          ),
                          if (_isAdmin && _tenants.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(10),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withAlpha(20)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: _selectedTenantId,
                                  isExpanded: true,
                                  dropdownColor: const Color(0xFF1E293B),
                                  style: const TextStyle(color: Colors.white),
                                  hint: Text(
                                    'allCenters'.tr(),
                                    style: const TextStyle(color: Colors.white60),
                                  ),
                                  items: [
                                    DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('allCenters'.tr()),
                                    ),
                                    ..._tenants.map(
                                      (t) => DropdownMenuItem(
                                        value: t['id'] as String,
                                        child: Text(t['id'] == widget.tenantId ? '🚀 ${t['name']}' : t['name'] as String),
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
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Summary Statistics (Calculated from state)
                  if (state is OrdersLoaded)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: _buildSummaryOverview(state.orders),
                      ),
                    ),

                  // Order List Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                      child: Text(
                        'allOrders'.tr(),
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),

                  // Orders Body
                  _buildSliverBody(state),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryOverview(List<Order> orders) {
    // Logic for Advance Calculation: 
    // If totalPrice exists, use it. Otherwise, use 100.0 as a baseline for orders that are not cancelled.
    final activeOrders = orders.where((o) => o.status != 'cancelled').toList();
    final totalAdvances = activeOrders.fold(0.0, (sum, o) => sum + (o.totalPrice ?? 100.0));
    final pendingCount = activeOrders.where((o) => o.status == 'pending').length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.indigo.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'totalAdvances'.tr(),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${totalAdvances.toStringAsFixed(0)} TMT',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  pendingCount > 0 
                    ? 'ordersNeedAttention'.tr(args: [pendingCount.toString()]).isEmpty
                        ? '$pendingCount orders need attention'
                        : 'ordersNeedAttention'.tr(args: [pendingCount.toString()])
                    : 'allCaughtUp'.tr().isEmpty ? 'All caught up!' : 'allCaughtUp'.tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverBody(OrderState state) {
    if (state is OrderLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    } else if (state is OrdersLoaded) {
      final orders = state.orders;
      if (orders.isEmpty) {
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  'noOrdersYet'.tr(),
                  style: const TextStyle(color: Colors.white60, fontSize: 18),
                ),
              ],
            ),
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _OrderManagementCard(order: orders[index]),
            childCount: orders.length,
          ),
        ),
      );
    } else if (state is OrderError) {
      return SliverFillRemaining(
        child: Center(child: Text(state.message, style: const TextStyle(color: Colors.red))),
      );
    }
    return const SliverToBoxAdapter(child: SizedBox());
  }
}

class _OrderManagementCard extends StatefulWidget {
  final Order order;
  const _OrderManagementCard({required this.order});

  @override
  State<_OrderManagementCard> createState() => _OrderManagementCardState();
}

class _OrderManagementCardState extends State<_OrderManagementCard> {
  bool _isProcessing = false;

  Future<void> _updateStatus(String status) async {
    setState(() => _isProcessing = true);
    AppHaptics.medium();
    try {
      await context.read<OrderCubit>().updateOrderStatus(widget.order.id, status);
    } catch (_) {}
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    Color statusColor;
    IconData statusIcon;

    switch (order.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusIcon = Icons.settings;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, color: statusColor, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                order.status.tr().toUpperCase(),
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '#${order.id.substring(0, 8)}',
                          style: const TextStyle(color: Colors.white38, fontSize: 12, fontFamily: 'Monospace'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      order.issueDescription,
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: Colors.white60),
                        const SizedBox(width: 4),
                        Text(order.user?.email ?? 'customer'.tr(), style: const TextStyle(color: Colors.white60, fontSize: 13)),
                        const Spacer(),
                        const Icon(Icons.calendar_today, size: 12, color: Colors.white38),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, HH:mm').format(order.createdAt),
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Colors.white10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('advancePaid'.tr(), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(order.totalPrice ?? 100.0).toStringAsFixed(0)} TMT',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_isProcessing)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70)),
                          )
                        else if (order.status == 'pending')
                          _ActionButton(
                            label: 'startWork'.tr(),
                            icon: Icons.play_arrow_rounded,
                            color: Colors.blueAccent,
                            onTap: () => _updateStatus('in_progress'),
                          )
                        else if (order.status == 'in_progress')
                          _ActionButton(
                            label: 'completeWork'.tr(),
                            icon: Icons.check_rounded,
                            color: Colors.greenAccent,
                            onTap: () => _updateStatus('completed'),
                          )
                        else if (order.status != 'completed' && order.status != 'cancelled')
                          Row(
                            children: [
                              _ActionButton(
                                icon: Icons.close_rounded,
                                color: Colors.redAccent,
                                onTap: () => _updateStatus('cancelled'),
                              ),
                              const SizedBox(width: 10),
                              _ActionButton(
                                icon: Icons.check_rounded,
                                color: Colors.greenAccent,
                                onTap: () => _updateStatus('completed'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? label;

  const _ActionButton({required this.icon, required this.color, required this.onTap, this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: label != null
          ? TextButton.icon(
              onPressed: onTap,
              icon: Icon(icon, color: color, size: 20),
              label: Text(label!, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            )
          : IconButton(
              icon: Icon(icon, color: color, size: 20),
              onPressed: onTap,
              constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            ),
    );
  }
}
