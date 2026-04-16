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
    String? mechanicName;

    if (authState is AuthAuthenticated) {
      tenantId = authState.tenantId;
      mechanicName = authState.user.email;
    }

    return BlocProvider(
      create: (context) => AdminCubit(tenantId: tenantId)..fetchProfiles(),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1A2E)
                : Colors.blue.shade900,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'mechanicPanel'.tr().isEmpty
                      ? 'Mechanic Panel'
                      : 'mechanicPanel'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  mechanicName ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => context.read<AuthCubit>().logout(),
              ),
            ],
            bottom: TabBar(
              tabs: [
                Tab(icon: const Icon(Icons.dashboard), text: 'dashboard'.tr()),
                Tab(icon: const Icon(Icons.assignment), text: 'orders'.tr()),
                Tab(icon: const Icon(Icons.build), text: 'services'.tr()),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
            ),
          ),
          body: const TabBarView(
            children: [
              AdminDashboardScreen(),
              OrdersManagementScreen(),
              ServicesManagementScreen(),
            ],
          ),
        ),
      ),
    );
  }
}
