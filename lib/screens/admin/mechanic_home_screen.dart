import 'package:supa/cubits/tenant_cubit.dart';
import 'package:supa/models/tenant_model.dart';
import 'package:supa/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/auth_cubit.dart';
import 'package:supa/cubits/admin_cubit.dart';
import 'package:supa/cubits/theme_cubit.dart';
import 'package:supa/models/service_model.dart';
import 'package:supa/cubits/service_cubit.dart';
import 'package:supa/screens/admin/admin_dashboard_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class MechanicHomeScreen extends StatefulWidget {
  const MechanicHomeScreen({super.key});

  @override
  State<MechanicHomeScreen> createState() => _MechanicHomeScreenState();
}

class _MechanicHomeScreenState extends State<MechanicHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    String? tenantId;
    if (authState is AuthAuthenticated) {
      tenantId = authState.tenantId;
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AdminCubit(tenantId: tenantId)..fetchProfiles()),
        if (tenantId != null)
          BlocProvider(create: (context) => ServiceCubit(tenantId: tenantId)..fetchServices()),
      ],
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
              floatingActionButton: Builder(
                builder: (fabContext) {
                  return FloatingActionButton(
                    backgroundColor: Colors.blueAccent,
                    child: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      if (tenantId != null) {
                        _showAddServiceDialog(fabContext, tenantId);
                      }
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServicesTab(BuildContext context, String? tenantId) {
    if (tenantId == null) return const Center(child: Text('Center not assigned', style: TextStyle(color: Colors.white)));
    
    return BlocBuilder<ServiceCubit, ServiceState>(
      builder: (context, state) {
        if (state is ServiceLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        List<Service> services = [];
        if (state is ServicesLoaded) {
          services = state.services;
        }

        if (services.isEmpty) return Center(child: Text('noServicesYet'.tr(), style: const TextStyle(color: Colors.white60)));
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final s = services[index];
            return Card(
              color: Colors.white.withAlpha(10),
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                title: Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('${s.price} TMT', style: const TextStyle(color: Colors.white70)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                      onPressed: () => _showEditServiceDialog(context, s),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _showDeleteServiceDialog(context, s),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddServiceDialog(BuildContext context, String tenantId) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    String category = 'catMaintenance';
    XFile? selectedImage;

    final Map<String, List<String>> categorySuggestions = {
      'catMaintenance': ['oilFluidChange', 'filterReplacement', 'sparkPlugCheck'],
      'catDiagElectronics': ['computerDiagnostics', 'chassisDiagnostics', 'electricalRepair'],
      'catCoreRepair': ['engineRepair', 'transmissionRepair', 'suspensionSteering', 'brakingSystem'],
      'catChassisWheels': ['tireFitting', 'wheelAlignment'],
      'catBodyVisual': ['bodyWork', 'paintPolishing', 'glassRepair'],
      'catAdditional': ['airConditioning', 'tuningEquipment', 'preSalePrep'],
    };

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stateContext, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('addNewService'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Picker
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setDialogState(() => selectedImage = picked);
                    }
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(16),
                      image: selectedImage != null
                          ? DecorationImage(image: FileImage(File(selectedImage!.path)), fit: BoxFit.cover)
                          : null,
                    ),
                    child: selectedImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo, color: Colors.white70, size: 32),
                              const SizedBox(height: 8),
                              Text('addPhoto'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: category,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'category'.tr(),
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withAlpha(5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: categorySuggestions.keys
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.tr())))
                      .toList(),
                  onChanged: (val) => setDialogState(() => category = val!),
                ),
                const SizedBox(height: 16),

                // Suggestions
                Text('suggestions'.tr(), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: (categorySuggestions[category] ?? [])
                        .map((s) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(s.tr(), style: const TextStyle(fontSize: 12)),
                                backgroundColor: Colors.blueAccent.withAlpha(30),
                                labelStyle: const TextStyle(color: Colors.blueAccent),
                                onPressed: () => setDialogState(() => nameController.text = s.tr()),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'serviceName'.tr(),
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'description'.tr(),
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'priceLabel'.tr(),
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('cancel'.tr(), style: const TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<ServiceCubit>().createService(
                  name: nameController.text,
                  description: descController.text,
                  price: double.tryParse(priceController.text) ?? 0.0,
                  durationHours: 1.0, // Default to 1 hour as it's removed from UI
                  category: category,
                  tenantId: tenantId,
                  image: selectedImage,
                );
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('add'.tr(), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditServiceDialog(BuildContext context, Service service) {
    final nameController = TextEditingController(text: service.name);
    final descController = TextEditingController(text: service.description);
    final priceController = TextEditingController(text: service.price.toString());
    String category = service.category;
    XFile? selectedImage;

    final Map<String, List<String>> categorySuggestions = {
      'catMaintenance': ['oilFluidChange', 'filterReplacement', 'sparkPlugCheck'],
      'catDiagElectronics': ['computerDiagnostics', 'chassisDiagnostics', 'electricalRepair'],
      'catCoreRepair': ['engineRepair', 'transmissionRepair', 'suspensionSteering', 'brakingSystem'],
      'catChassisWheels': ['tireFitting', 'wheelAlignment'],
      'catBodyVisual': ['bodyWork', 'paintPolishing', 'glassRepair'],
      'catAdditional': ['airConditioning', 'tuningEquipment', 'preSalePrep'],
    };

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stateContext, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('edit'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Picker
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setDialogState(() => selectedImage = picked);
                    }
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(16),
                      image: selectedImage != null
                          ? DecorationImage(image: FileImage(File(selectedImage!.path)), fit: BoxFit.cover)
                          : (service.imageUrl != null
                              ? DecorationImage(image: NetworkImage(service.imageUrl!), fit: BoxFit.cover)
                              : null),
                    ),
                    child: selectedImage == null && service.imageUrl == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo, color: Colors.white70, size: 32),
                              const SizedBox(height: 8),
                              Text('addPhoto'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: categorySuggestions.containsKey(category) ? category : 'catMaintenance',
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'category'.tr(),
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withAlpha(5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: categorySuggestions.keys
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.tr())))
                      .toList(),
                  onChanged: (val) => setDialogState(() => category = val!),
                ),
                const SizedBox(height: 16),

                // Suggestions
                Text('suggestions'.tr(), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: (categorySuggestions[category] ?? [])
                        .map((s) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(s.tr(), style: const TextStyle(fontSize: 12)),
                                backgroundColor: Colors.blueAccent.withAlpha(30),
                                labelStyle: const TextStyle(color: Colors.blueAccent),
                                onPressed: () => setDialogState(() => nameController.text = s.tr()),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'serviceName'.tr(),
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'description'.tr(),
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'priceLabel'.tr(),
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('cancel'.tr(), style: const TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<ServiceCubit>().updateService(
                  serviceId: service.id,
                  name: nameController.text,
                  description: descController.text,
                  price: double.tryParse(priceController.text) ?? 0.0,
                  durationHours: service.durationHours,
                  category: category,
                  tenantId: service.tenantId,
                  newImage: selectedImage,
                  existingImageUrl: service.imageUrl,
                );
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('save'.tr(), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteServiceDialog(BuildContext context, Service service) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('deleteService'.tr(), style: const TextStyle(color: Colors.white)),
        content: Text(
          'confirmDeleteService'.tr(args: [service.name]),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('no'.tr())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              context.read<ServiceCubit>().deleteService(service.id);
              Navigator.pop(dialogContext);
            },
            child: Text('yes'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
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

