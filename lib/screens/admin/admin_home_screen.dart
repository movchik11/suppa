import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:supa/cubits/admin_cubit.dart';
import 'package:supa/cubits/auth_cubit.dart';
import 'package:supa/screens/admin/admin_dashboard_screen.dart';
import 'package:supa/screens/admin/orders_management_screen.dart';
import 'package:supa/screens/admin/services_management_screen.dart';
import 'package:supa/screens/auth/login_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminCubit(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          actions: [
            IconButton(
              icon: const Icon(Icons.dashboard),
              tooltip: 'Dashboard',
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
              tooltip: 'Manage Services',
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
              tooltip: 'Manage Orders',
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
              return Center(
                child: Lottie.asset(
                  'assets/animations/loading.json',
                  height: 200,
                  errorBuilder: (context, error, stackTrace) =>
                      const CircularProgressIndicator(),
                ),
              );
            } else if (state is AdminLoaded) {
              if (state.profiles.isEmpty) {
                return const Center(child: Text("No users found."));
              }
              return RefreshIndicator(
                onRefresh: () => context.read<AdminCubit>().fetchProfiles(),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Total Users: ${state.profiles.length}",
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
                              subtitle: Text('Role: ${profile.role}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Change Role Button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.swap_horiz,
                                      color: Colors.blue,
                                    ),
                                    tooltip: 'Change Role',
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
                                    tooltip: 'Delete User',
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
            return const Center(child: Text('Welcome, Admin!'));
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
        title: const Text('Change User Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('User'),
              leading: Radio(
                value: 'user',
                groupValue: currentRole,
                onChanged: (value) {
                  Navigator.pop(dialogContext);
                  context.read<AdminCubit>().updateUserRole(userId, 'user');
                },
              ),
            ),
            ListTile(
              title: const Text('Admin'),
              leading: Radio(
                value: 'admin',
                groupValue: currentRole,
                onChanged: (value) {
                  Navigator.pop(dialogContext);
                  context.read<AdminCubit>().updateUserRole(userId, 'admin');
                },
              ),
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
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AdminCubit>().deleteUser(userId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
