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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'managementPanel'.tr().isEmpty ? 'Live Orders' : 'managementPanel'.tr(),
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          bottom: _isAdmin && _tenants.isNotEmpty
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Container(
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
                            'allCenters'.tr().isEmpty ? 'All Centers' : 'allCenters'.tr(),
                            style: const TextStyle(color: Colors.white60),
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text('allCenters'.tr().isEmpty ? 'All Centers' : 'allCenters'.tr()),
                            ),
                            ..._tenants.map((t) => DropdownMenuItem(
                              value: t['id'] as String,
                              child: Text(t['id'] == widget.tenantId ? '🚀 ${t['name']}' : t['name'] as String),
                            )),
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
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                AppHaptics.light();
                context.read<OrderCubit>().fetchAllOrders();
              },
            ),
          ],
        ),
        body: BlocBuilder<OrderCubit, OrderState>(
          builder: (context, state) {
            if (state is OrderLoading) {
              return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
            } else if (state is OrdersLoaded) {
              final orders = state.orders;
              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.white24),
                      const SizedBox(height: 16),
                      Text(
                        'noOrdersYet'.tr().isEmpty ? 'No orders found' : 'noOrdersYet'.tr(),
                        style: const TextStyle(color: Colors.white60, fontSize: 18),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => context.read<OrderCubit>().fetchAllOrders(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _OrderManagementCard(order: order);
                  },
                ),
              );
            } else if (state is OrderError) {
              return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _OrderManagementCard extends StatelessWidget {
  final Order order;
  const _OrderManagementCard({required this.order});

  @override
  Widget build(BuildContext context) {
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
          child: InkWell(
            onTap: () {
              // Management options here
            },
            child: Padding(
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
                      Text(order.user?.email ?? 'Customer', style: const TextStyle(color: Colors.white60, fontSize: 13)),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Price', style: TextStyle(color: Colors.white38, fontSize: 11)),
                          Text(
                            '${(order.totalPrice ?? 0).toStringAsFixed(2)} TMT',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _ActionButton(
                            icon: Icons.edit_note,
                            color: Colors.blueAccent,
                            onTap: () {
                              // Detailed view
                            },
                          ),
                          const SizedBox(width: 10),
                          _ActionButton(
                            icon: Icons.check_rounded,
                            color: Colors.greenAccent,
                            onTap: () {
                              context.read<OrderCubit>().updateOrderStatus(order.id, 'completed');
                            },
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onTap,
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
      ),
    );
  }
}
