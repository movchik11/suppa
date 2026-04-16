import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/order_cubit.dart';
import 'package:supa/cubits/auth_cubit.dart';
import 'package:supa/cubits/theme_cubit.dart';
import 'package:supa/models/order_model.dart';
import 'package:easy_localization/easy_localization.dart';

class OrdersManagementScreen extends StatefulWidget {
  const OrdersManagementScreen({super.key});

  @override
  State<OrdersManagementScreen> createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'all';
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderCubit(tenantId: _selectedTenantId)
        ..fetchAllOrders()
        ..subscribeToAllOrders(),
      key: ValueKey(
        _selectedTenantId,
      ), // Re-create cubit when tenant selection changes
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
                            setState(() => _selectedTenantId = val);
                          },
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'searchHint'.tr(),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'all'.tr(),
                          value: 'all',
                          selectedValue: _selectedStatusFilter,
                          onSelected: (v) =>
                              setState(() => _selectedStatusFilter = v),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'pending'.tr(),
                          value: 'pending',
                          selectedValue: _selectedStatusFilter,
                          onSelected: (v) =>
                              setState(() => _selectedStatusFilter = v),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'inProgress'.tr(),
                          value: 'in_progress',
                          selectedValue: _selectedStatusFilter,
                          onSelected: (v) =>
                              setState(() => _selectedStatusFilter = v),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'completed'.tr(),
                          value: 'completed',
                          selectedValue: _selectedStatusFilter,
                          onSelected: (v) =>
                              setState(() => _selectedStatusFilter = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<OrderCubit, OrderState>(
                builder: (context, state) {
                  if (state is OrderLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is OrdersLoaded) {
                    var filteredOrders = state.orders;

                    // Apply Status Filter
                    if (_selectedStatusFilter != 'all') {
                      filteredOrders = filteredOrders
                          .where((o) => o.status == _selectedStatusFilter)
                          .toList();
                    }

                    // Apply Search
                    final query = _searchController.text.toLowerCase();
                    if (query.isNotEmpty) {
                      filteredOrders = filteredOrders.where((o) {
                        final userName =
                            o.user?.displayName?.toLowerCase() ?? '';
                        final plate =
                            o.vehicle?.licensePlate?.toLowerCase() ?? '';
                        final service = o.carModel.toLowerCase();
                        final orderId = o.id.toLowerCase();
                        return userName.contains(query) ||
                            plate.contains(query) ||
                            service.contains(query) ||
                            orderId.contains(query);
                      }).toList();
                    }

                    if (filteredOrders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 80,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text('noMatchingOrders'.tr()),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () =>
                          context.read<OrderCubit>().fetchAllOrders(),
                      child: ListView.builder(
                        itemCount: filteredOrders.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
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
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final Function(String) onSelected;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedValue == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
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
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _formatDate(order.createdAt),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(
                order.status.toUpperCase(),
                style: const TextStyle(fontSize: 10),
              ),
              backgroundColor: _getStatusColor().withAlpha(51),
              labelStyle: TextStyle(color: _getStatusColor()),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (bgContext) => AlertDialog(
                    title: Text('deleteOrder'.tr()),
                    content: Text('confirmDeleteOrder'.tr()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(bgContext, false),
                        child: Text('no'.tr()),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(bgContext, true),
                        child: Text(
                          'yes'.tr(),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  context.read<OrderCubit>().deleteOrder(
                    order.id,
                    isAdmin: true,
                  );
                }
              },
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
              tooltip: 'deleteOrder'.tr(),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order.user != null) ...[
                  Text(
                    'userDetails'.tr(),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.person,
                    order.user!.displayName ?? 'N/A',
                  ),
                  _buildDetailRow(Icons.email, order.user!.email),
                  if (order.user!.phoneNumber != null)
                    _buildDetailRow(Icons.phone, order.user!.phoneNumber!),
                  const SizedBox(height: 16),
                ],
                if (order.vehicle != null) ...[
                  Text(
                    'vehicleDetails'.tr(),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.directions_car,
                    '${order.vehicle!.brand} ${order.vehicle!.model} (${order.vehicle!.year})',
                  ),
                  if (order.vehicle!.licensePlate != null)
                    _buildDetailRow(Icons.pin, order.vehicle!.licensePlate!),
                  const SizedBox(height: 16),
                ],
                Text(
                  'serviceIssue'.tr(),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  order.carModel, // Service title
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  order.issueDescription,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'changeStatus'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _StatusButton(
                      label: 'pending'.tr(),
                      status: 'pending',
                      orderId: order.id,
                      currentStatus: order.status,
                    ),
                    _StatusButton(
                      label: 'inProgress'.tr(),
                      status: 'in_progress',
                      orderId: order.id,
                      currentStatus: order.status,
                    ),
                    _StatusButton(
                      label: 'completed'.tr(),
                      status: 'completed',
                      orderId: order.id,
                      currentStatus: order.status,
                    ),
                    _StatusButton(
                      label: 'cancelled'.tr(),
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

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
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
