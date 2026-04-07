import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/admin_cubit.dart';
import 'package:supa/cubits/order_cubit.dart';
import 'package:supa/cubits/auth_cubit.dart';
import 'package:supa/screens/admin/admin_dashboard_screen.dart';
import 'package:supa/screens/admin/orders_management_screen.dart';
import 'package:supa/screens/admin/services_management_screen.dart';
import 'package:supa/screens/auth/login_screen.dart';
import 'package:supa/cubits/theme_cubit.dart';
import 'package:easy_localization/easy_localization.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensuring admin notifications are active
    context.read<OrderCubit>().subscribeToAllOrders();

    return BlocProvider(
      create: (context) {
        final authState = context.read<AuthCubit>().state;
        String? tenantId;
        if (authState is AuthAuthenticated) {
          tenantId = authState.tenantId;
        }
        return AdminCubit(tenantId: tenantId);
      },
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'adminPanel'.tr().isEmpty ? 'Admin Panel' : 'adminPanel'.tr(),
              ),
              actions: [
                BlocBuilder<ThemeCubit, bool>(
                  builder: (context, isLight) {
                    return IconButton(
                      icon: Icon(isLight ? Icons.dark_mode : Icons.light_mode),
                      onPressed: () => context.read<ThemeCubit>().toggleTheme(),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.dashboard),
                  tooltip: 'dashboard'.tr(),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminDashboardScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.build),
                  tooltip: 'manageServices'.tr(),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ServicesManagementScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.assignment),
                  tooltip: 'manageOrders'.tr(),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrdersManagementScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add_business),
                  tooltip: 'Add Auto Service',
                  onPressed: () => _showAddTenantDialog(context),
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
            body: BlocBuilder<AdminCubit, AdminState>(
              builder: (context, state) {
                if (state is AdminLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is AdminLoaded) {
                  return DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          tabs: [
                            Tab(
                              text: "users".tr().isEmpty
                                  ? "Users"
                                  : "users".tr(),
                            ),
                            Tab(
                              text: "serviceCenters".tr().isEmpty
                                  ? "Service Centers"
                                  : "serviceCenters".tr(),
                            ),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Users Tab
                              _buildUsersList(context, state),
                              // Service Centers Tab
                              _buildTenantsList(context, state),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (state is AdminError) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                return Center(child: Text('welcomeAdmin'.tr()));
              },
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
            RadioListTile<String>(
              title: Text('userRole'.tr()),
              value: 'user',
              groupValue: currentRole,
              onChanged: (value) {
                if (value != null && context.mounted) {
                  Navigator.pop(dialogContext);
                  context.read<AdminCubit>().updateUserRole(userId, value);
                }
              },
            ),
            RadioListTile<String>(
              title: Text('mechanicRole'.tr()),
              value: 'mechanic',
              groupValue: currentRole,
              onChanged: (value) {
                if (value != null && context.mounted) {
                  Navigator.pop(dialogContext);
                  context.read<AdminCubit>().updateUserRole(userId, value);
                }
              },
            ),
            RadioListTile<String>(
              title: Text('adminRole'.tr()),
              value: 'admin',
              groupValue: currentRole,
              onChanged: (value) {
                if (value != null && context.mounted) {
                  Navigator.pop(dialogContext);
                  context.read<AdminCubit>().updateUserRole(userId, value);
                }
              },
            ),
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
                  leading: Radio<String?>(
                    value: null,
                    groupValue: currentTenantId,
                    onChanged: (val) {
                      Navigator.pop(dialogContext);
                      context.read<AdminCubit>().updateUserTenant(userId, null);
                    },
                  ),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    context.read<AdminCubit>().updateUserTenant(userId, null);
                  },
                );
              }
              final tenant = tenants[index - 1];
              return ListTile(
                title: Text(tenant.name),
                leading: Radio<String?>(
                  value: tenant.id,
                  groupValue: currentTenantId,
                  onChanged: (val) {
                    Navigator.pop(dialogContext);
                    context.read<AdminCubit>().updateUserTenant(userId, val);
                  },
                ),
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

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('addServiceCenter'.tr()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'serviceCenterName'.tr(),
                  hintText: 'serviceCenterHint'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'address'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'phone'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final cubit = context.read<AdminCubit>();
                Navigator.pop(dialogContext);
                await cubit.createTenant(
                  name: nameController.text.trim(),
                  address: addressController.text.trim().isEmpty
                      ? null
                      : addressController.text.trim(),
                  phone: phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Service Center created. You can now assign users to it.',
                      ),
                    ),
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

  Widget _buildUsersList(BuildContext context, AdminLoaded state) {
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

  Widget _buildTenantsList(BuildContext context, AdminLoaded state) {
    if (state.tenants.isEmpty) {
      return Center(
        child: Text(
          "noServiceCentersFound".tr().isEmpty
              ? "No Service Centers Found"
              : "noServiceCentersFound".tr(),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<AdminCubit>().fetchProfiles(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Total Service Centers: ${state.tenants.length}",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: state.tenants.length,
              itemBuilder: (context, index) {
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
