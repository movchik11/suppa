import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/admin_cubit.dart';
import 'package:supa/cubits/order_cubit.dart';
import 'package:supa/cubits/auth_cubit.dart';
import 'package:supa/screens/admin/admin_dashboard_screen.dart';
import 'package:supa/screens/admin/orders_management_screen.dart';
import 'package:supa/screens/admin/services_management_screen.dart';
import 'package:supa/screens/auth/login_screen.dart';
import 'package:supa/models/tenant_model.dart';
import 'package:supa/models/service_model.dart';
import 'package:easy_localization/easy_localization.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensuring admin notifications are active
    context.read<OrderCubit>().subscribeToAllOrders();

    final authState = context.read<AuthCubit>().state;

    return BlocProvider(
      create: (context) {
        String? tenantId;
        if (authState is AuthAuthenticated) {
          tenantId = authState.tenantId;
        }
        return AdminCubit(tenantId: tenantId)..fetchProfiles();
      },
      child: Builder(
        builder: (context) {
          final role = (authState as AuthAuthenticated).role;
          return Scaffold(
            body: BlocListener<AdminCubit, AdminState>(
              listener: (context, state) {
                if (state is AdminError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: BlocBuilder<AdminCubit, AdminState>(
                builder: (context, state) {
                  if (state is AdminLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is AdminLoaded) {
                    return DefaultTabController(
                      length: 2,
                      child: NestedScrollView(
                        headerSliverBuilder: (context, innerBoxIsScrolled) => [
                          SliverAppBar(
                            expandedHeight: 180,
                            pinned: true,
                            flexibleSpace: FlexibleSpaceBar(
                              title: Text(
                                'adminPanel'.tr().isEmpty
                                    ? 'Admin Panel'
                                    : 'adminPanel'.tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              background: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.blue.shade900,
                                      Colors.indigo.shade800,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            actions: [
                              IconButton(
                                icon: const Icon(Icons.dashboard_customize),
                                tooltip: 'dashboard'.tr(),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AdminDashboardScreen(),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.logout),
                                onPressed: () {
                                  context.read<AuthCubit>().logout();
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                    (context) => false,
                                  );
                                },
                              ),
                            ],
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      _QuickActionCard(
                                        title: 'services'.tr(),
                                        icon: Icons.build,
                                        color: Colors.orange,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ServicesManagementScreen(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      _QuickActionCard(
                                        title: 'orders'.tr(),
                                        icon: Icons.assignment,
                                        color: Colors.green,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const OrdersManagementScreen(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  TabBar(
                                    labelColor: Colors.blue,
                                    unselectedLabelColor: Colors.grey,
                                    indicatorColor: Colors.blue,
                                    tabs: [
                                      Tab(
                                        text: "users".tr().isEmpty
                                            ? "Users"
                                            : "users".tr(),
                                      ),
                                      Tab(
                                        text: "centers".tr().isEmpty
                                            ? "Centers"
                                            : "centers".tr(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        body: TabBarView(
                          children: [
                            _buildUsersList(context, state, role),
                            _buildTenantsList(context, state, role),
                          ],
                        ),
                      ),
                    );
                  } else if (state is AdminError) {
                    return Center(child: Text('Error: ${state.message}'));
                  }
                  return Center(child: Text('welcomeAdmin'.tr()));
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRoleDialog(
    BuildContext context,
    String userId,
    String currentRole,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('changeUserRole'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'user', label: Text('userRole'.tr())),
                ButtonSegment(
                  value: 'mechanic',
                  label: Text('mechanicRole'.tr()),
                ),
                ButtonSegment(value: 'admin', label: Text('adminRole'.tr())),
              ],
              selected: {currentRole},
              onSelectionChanged: (Set<String> newSelection) {
                final value = newSelection.first;
                Navigator.pop(dialogContext);
                context.read<AdminCubit>().updateUserRole(userId, value);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showTenantDialog(
    BuildContext context,
    String userId,
    String? currentTenantId,
  ) async {
    final tenants = await context.read<AdminCubit>().fetchTenants();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('changeTenant'.tr()),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tenants.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: Text('all'.tr()),
                  trailing: currentTenantId == null
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).primaryColor,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(dialogContext);
                    context.read<AdminCubit>().updateUserTenant(userId, null);
                  },
                );
              }
              final tenant = tenants[index - 1];
              return ListTile(
                title: Text(tenant.name),
                trailing: currentTenantId == tenant.id
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).primaryColor,
                      )
                    : null,
                onTap: () {
                  Navigator.pop(dialogContext);
                  context.read<AdminCubit>().updateUserTenant(
                    userId,
                    tenant.id,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String userId, String email) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('deleteUser'.tr()),
        content: Text('confirmDeleteUser'.tr(args: [email])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AdminCubit>().deleteUser(userId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }

  void _showAddTenantDialog(BuildContext context) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('addServiceCenter'.tr()),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'serviceCenterName'.tr(),
                    hintText: 'serviceCenterHint'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  autofocus: true,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter service center name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: 'address'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter address'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'phone'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter phone number'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final cubit = context.read<AdminCubit>();
                Navigator.pop(dialogContext);
                await cubit.createTenant(
                  name: nameController.text.trim(),
                  address: addressController.text.trim(),
                  phone: phoneController.text.trim(),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Service Center created.')),
                  );
                }
              }
            },
            child: Text('add'.tr()),
          ),
        ],
      ),
    );
  }

  void _showEditTenantDialog(BuildContext context, Tenant tenant) {
    final nameController = TextEditingController(text: tenant.name);
    final addressController = TextEditingController(text: tenant.address);
    final phoneController = TextEditingController(text: tenant.phone);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'editServiceCenter'.tr().isEmpty
              ? 'Edit Center'
              : 'editServiceCenter'.tr(),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'serviceCenterName'.tr(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  decoration: InputDecoration(labelText: 'address'.tr()),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter address'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'phone'.tr()),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter phone'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final cubit = context.read<AdminCubit>();
                Navigator.pop(dialogContext);
                await cubit.updateTenant(
                  id: tenant.id,
                  name: nameController.text.trim(),
                  address: addressController.text.trim(),
                  phone: phoneController.text.trim(),
                );
              }
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDeleteTenantDialog(BuildContext context, Tenant tenant) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'deleteServiceCenter'.tr().isEmpty
              ? 'Delete Center'
              : 'deleteServiceCenter'.tr(),
        ),
        content: Text(
          'Confirm delete ${tenant.name}? All associated data may be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              final cubit = context.read<AdminCubit>();
              Navigator.pop(dialogContext);
              await cubit.deleteTenant(tenant.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }

  void _showManageServicesDialog(BuildContext context, Tenant tenant) async {
    final cubit = context.read<AdminCubit>();
    final services = await cubit.fetchServicesForTenant(tenant.id);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${tenant.name}: Services'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (services.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('No services found for this center'),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final service = services[index];
                        return ListTile(
                          title: Text(service.name),
                          subtitle: Text('\$${service.price}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await cubit.deleteService(service.id);
                              final updated = await cubit
                                  .fetchServicesForTenant(tenant.id);
                              setDialogState(() {
                                services.clear();
                                services.addAll(updated);
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                const Divider(),
                ElevatedButton.icon(
                  onPressed: () =>
                      _showAddServiceDialog(context, tenant.id, () async {
                        final updated = await cubit.fetchServicesForTenant(
                          tenant.id,
                        );
                        setDialogState(() {
                          services.clear();
                          services.addAll(updated);
                        });
                      }),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Service'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddServiceDialog(
    BuildContext context,
    String tenantId,
    VoidCallback onAdded,
  ) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();
    final durationController = TextEditingController(text: '1.0');
    String selectedCategory = 'Тех. обслуживание';
    final formKey = GlobalKey<FormState>();

    final categories = [
      'Тех. обслуживание',
      'Ремонт двигателя',
      'Ходовая часть',
      'Электрика',
      'Кузовной ремонт',
      'Шиномонтаж',
    ];

    final suggestions = [
      'Замена масла и жидкостей',
      'Замена фильтров',
      'Проверка свечей зажигания',
      'Диагностика подвески',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Новая услуга',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Suggestions Chips
                  const Text(
                    'Предложения',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: suggestions
                          .map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(
                                  s,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onPressed: () =>
                                    setState(() => nameController.text = s),
                                backgroundColor: Colors.white10,
                                labelStyle: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  const Text(
                    'Категория',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    dropdownColor: const Color(0xFF2E2E3E),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withAlpha(13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildModernField(
                    controller: nameController,
                    label: 'Название услуги',
                    validator: (v) =>
                        v!.isEmpty ? 'Это поле обязательно' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildModernField(
                    controller: descController,
                    label: 'Описание',
                    maxLines: 2,
                    validator: (v) =>
                        v!.isEmpty ? 'Это поле обязательно' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernField(
                          controller: durationController,
                          label: 'Длительность (ч)',
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              double.tryParse(v ?? '') == null ? '?' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModernField(
                          controller: priceController,
                          label: 'Цена (TMT)',
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              double.tryParse(v ?? '') == null ? '?' : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Отмена',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final cubit = context.read<AdminCubit>();
                    final newService = Service(
                      id: '',
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                      price: double.parse(priceController.text),
                      category: selectedCategory,
                      durationHours: double.parse(durationController.text),
                      tenantId: tenantId,
                    );
                    Navigator.pop(dialogContext);
                    await cubit.addService(newService);
                    onAdded();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'create',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withAlpha(13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsersList(
    BuildContext context,
    AdminLoaded state,
    String? role,
  ) {
    if (state.profiles.isEmpty) {
      return Center(child: Text("noUsersFound".tr()));
    }
    return RefreshIndicator(
      onRefresh: () => context.read<AdminCubit>().fetchProfiles(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "totalUsers".tr(args: [state.profiles.length.toString()]),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: state.profiles.length,
              itemBuilder: (context, index) {
                final profile = state.profiles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(profile.email[0].toUpperCase()),
                    ),
                    title: Text(profile.email),
                    subtitle: Text('roleLabel'.tr(args: [profile.role])),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.swap_horiz,
                            color: Colors.blue,
                          ),
                          tooltip: 'changeRole'.tr(),
                          onPressed: () => _showRoleDialog(
                            context,
                            profile.id,
                            profile.role,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.business, color: Colors.green),
                          tooltip: 'changeTenant'.tr(),
                          onPressed: () => _showTenantDialog(
                            context,
                            profile.id,
                            profile.tenantId,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'deleteUser'.tr(),
                          onPressed: () => _showDeleteDialog(
                            context,
                            profile.id,
                            profile.email,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantsList(
    BuildContext context,
    AdminLoaded state,
    String? role,
  ) {
    // Always return the RefreshIndicator and ListView to ensure 'Add' button is visible for admins
    return RefreshIndicator(
      onRefresh: () => context.read<AdminCubit>().fetchProfiles(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              state.tenants.isEmpty
                  ? "noServiceCentersFound".tr().isEmpty
                        ? "No Service Centers Found"
                        : "noServiceCentersFound".tr()
                  : "${"totalServiceCenters".tr().isEmpty ? "Total Service Centers" : "totalServiceCenters".tr()}: ${state.tenants.length}",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: state.tenants.length + (role == 'admin' ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.tenants.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddTenantDialog(context),
                      icon: const Icon(Icons.add_business),
                      label: Text('addServiceCenter'.tr()),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  );
                }
                final tenant = state.tenants[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.business)),
                    title: Text(tenant.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tenant.address != null) Text(tenant.address!),
                        if (tenant.phone != null) Text(tenant.phone!),
                      ],
                    ),
                    trailing: role == 'admin'
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.add_task,
                                  color: Colors.purple,
                                ),
                                tooltip: 'Manage Services',
                                onPressed: () =>
                                    _showManageServicesDialog(context, tenant),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () =>
                                    _showEditTenantDialog(context, tenant),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    _showDeleteTenantDialog(context, tenant),
                              ),
                            ],
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withAlpha(50)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
