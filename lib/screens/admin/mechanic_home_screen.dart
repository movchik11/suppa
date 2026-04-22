import 'package:supa/cubits/tenant_cubit.dart';
import 'package:supa/models/tenant_model.dart';
import 'package:supa/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/auth_cubit.dart';
import 'package:supa/cubits/admin_cubit.dart';
import 'package:supa/cubits/theme_cubit.dart';
import 'package:supa/models/service_model.dart';
import 'package:supa/screens/admin/admin_dashboard_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';

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
            length: 2,
            child: Scaffold(
              backgroundColor: const Color(0xFF0F172A),
              body: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade900, Colors.indigo.shade800],
                      ),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'mechanicPanel'.tr().isEmpty ? 'Mechanic Panel' : 'mechanicPanel'.tr(),
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.business, size: 14, color: Colors.white70),
                                  const SizedBox(width: 6),
                                  Text(
                                    centerName,
                                    style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white),
                          onPressed: () => _showSettingsSheet(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () {
                            context.read<AuthCubit>().logout();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TabBar(
                    tabs: [
                      Tab(text: 'dashboard'.tr()),
                      Tab(text: 'services'.tr()),
                    ],
                    labelColor: Colors.blueAccent,
                    unselectedLabelColor: Colors.white60,
                    indicatorColor: Colors.blueAccent,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        const AdminDashboardScreen(),
                        _buildServicesTab(context, tenantId),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildServicesTab(BuildContext context, String? tenantId) {
    if (tenantId == null) return const Center(child: Text('Center not assigned'));
    
    return FutureBuilder<List<Service>>(
      future: context.read<AdminCubit>().fetchServicesForTenant(tenantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final services = snapshot.data ?? [];
        if (services.isEmpty) return Center(child: Text('noServicesYet'.tr()));
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final s = services[index];
            return Card(
              color: Colors.white.withAlpha(10),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('${s.price} TMT', style: const TextStyle(color: Colors.white70)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                  onPressed: () {
                    // Logic to edit service can be added here
                    // Actually, let's keep it simple for now or use the dialog from AdminHomeScreen if possible
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      backgroundColor: const Color(0xFF1E293B),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('settings'.tr(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.greenAccent),
              title: Text('language'.tr(), style: const TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white24),
              onTap: () => _showLanguagePicker(context),
            ),
            const Divider(color: Colors.white10),
            _buildThemeSwitch(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSwitch(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state;
    return ListTile(
      leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: Colors.orangeAccent),
      title: Text('themeSettings'.tr(), style: const TextStyle(color: Colors.white)),
      trailing: Switch(
        value: isDark,
        onChanged: (val) => context.read<ThemeCubit>().toggleTheme(),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('language'.tr(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _buildLangTile(context, 'English', 'en'),
          _buildLangTile(context, 'Русский', 'ru'),
          _buildLangTile(context, 'Türkmençe', 'tk'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLangTile(BuildContext context, String name, String code) {
    final isSelected = context.locale.languageCode == code;
    return ListTile(
      title: Text(name, style: const TextStyle(color: Colors.white)),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blueAccent) : null,
      onTap: () {
        context.setLocale(Locale(code));
        Navigator.pop(context);
      },
    );
  }
}
