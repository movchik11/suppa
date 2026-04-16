import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/tenant_cubit.dart';
import 'package:supa/components/app_loading_indicator.dart';
import 'package:supa/screens/user/tenant_services_screen.dart';
import 'package:supa/components/ui/bouncy_button.dart';
import 'package:easy_localization/easy_localization.dart';

class TenantsTab extends StatefulWidget {
  const TenantsTab({super.key});

  @override
  State<TenantsTab> createState() => _TenantsTabState();
}

class _TenantsTabState extends State<TenantsTab> {
  @override
  void initState() {
    super.initState();
    context.read<TenantCubit>().fetchTenants();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TenantCubit, TenantState>(
      builder: (context, state) {
        if (state is TenantLoading) {
          return const AppLoadingIndicator();
        } else if (state is TenantLoaded) {
          final tenants = state.tenants;
          
          if (tenants.isEmpty) {
            return Center(
              child: Text(
                'noServiceCenters'.tr().isEmpty ? 'No Service Centers found' : 'noServiceCenters'.tr(),
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<TenantCubit>().fetchTenants(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: tenants.length,
              itemBuilder: (context, index) {
                final tenant = tenants[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  elevation: 0,
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: BouncyButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TenantServicesScreen(tenant: tenant),
                        ),
                      );
                    },
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TenantServicesScreen(tenant: tenant),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withAlpha(20),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.business, color: Colors.blue, size: 32),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tenant.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Theme.of(context).textTheme.titleLarge?.color,
                                        ),
                                      ),
                                      if (tenant.address != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          tenant.address!,
                                          style: TextStyle(
                                            color: Theme.of(context).hintColor,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      if (tenant.phone != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.phone, size: 14, color: Theme.of(context).hintColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              tenant.phone!,
                                              style: TextStyle(
                                                color: Theme.of(context).hintColor,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        } else if (state is TenantError) {
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
    );
  }
}
