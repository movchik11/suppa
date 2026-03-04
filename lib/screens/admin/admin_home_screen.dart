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
      create: (context) => AdminCubit(),
      child: Scaffold(
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
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthCubit>().logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
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
                        "totalUsers".tr(
                          args: [state.profiles.length.toString()],
                        ),
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
                              subtitle: Text(
                                'roleLabel'.tr(args: [profile.role]),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Change Role Button
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
                                  // Delete Button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
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
            } else if (state is AdminError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            return Center(child: Text('welcomeAdmin'.tr()));
          },
        ),
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
            ListTile(
              title: Text('userRole'.tr()),
              leading: Radio<String>(
                value: 'user',
                groupValue: currentRole,
                onChanged: (value) {
                  if (value != null && context.mounted) {
                    Navigator.pop(dialogContext);
                    context.read<AdminCubit>().updateUserRole(userId, value);
                  }
                },
              ),
              onTap: () {
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  context.read<AdminCubit>().updateUserRole(userId, 'user');
                }
              },
            ),
            ListTile(
              title: Text('adminRole'.tr()),
              leading: Radio<String>(
                value: 'admin',
                groupValue: currentRole,
                onChanged: (value) {
                  if (value != null && context.mounted) {
                    Navigator.pop(dialogContext);
                    context.read<AdminCubit>().updateUserRole(userId, value);
                  }
                },
              ),
              onTap: () {
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  context.read<AdminCubit>().updateUserRole(userId, 'admin');
                }
              },
            ),
          ],
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
}
