import 'package:supa/cubits/tenant_cubit.dart';
import 'package:supa/models/tenant_model.dart';
import 'package:supa/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/auth_cubit.dart';
import 'package:supa/cubits/admin_cubit.dart';
import 'package:supa/screens/admin/admin_dashboard_screen.dart';
import 'package:supa/screens/admin/orders_management_screen.dart';
import 'package:supa/screens/admin/services_management_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class MechanicHomeScreen extends StatelessWidget {
  const MechanicHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    String? tenantId;
    if (authState is AuthAuthenticated) {
      tenantId = authState.tenantId;
    }

    return BlocProvider(
      create: (context) => AdminCubit(tenantId: tenantId)..fetchProfiles(),
      child: BlocBuilder<TenantCubit, TenantState>(
        builder: (context, tenantState) {
          String centerName = '...';
          if (tenantState is TenantLoaded && tenantId != null) {
            final tenant = tenantState.tenants.firstWhere(
              (t) => t.id == tenantId,
              orElse: () => Tenant(id: '', name: 'Unknown', createdAt: DateTime.now()),
            );
            centerName = tenant.name;
          }

          return DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                          : [Colors.blue.shade900, Colors.blue.shade700],
                    ),
                  ),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'mechanicPanel'.tr().isEmpty ? 'Mechanic Panel' : 'mechanicPanel'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.business, size: 12, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          centerName,
                          style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white24,
                      child: IconButton(
                        icon: const Icon(Icons.logout, size: 18, color: Colors.white),
                        onPressed: () {
                          context.read<AuthCubit>().logout();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                  ),
                ],
                bottom: TabBar(
                  tabs: [
                    Tab(child: Text('dashboard'.tr(), style: const TextStyle(fontSize: 12))),
                    Tab(child: Text('orders'.tr(), style: const TextStyle(fontSize: 12))),
                    Tab(child: Text('services'.tr(), style: const TextStyle(fontSize: 12))),
                  ],
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                ),
              ),
              body: TabBarView(
                children: [
                  AdminDashboardScreen(tenantId: tenantId),
                  OrdersManagementScreen(tenantId: tenantId),
                  ServicesManagementScreen(tenantId: tenantId),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
