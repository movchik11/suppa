import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/admin_cubit.dart';
import 'package:supa/cubits/order_cubit.dart';
import 'package:supa/cubits/auth_cubit.dart';
import 'package:supa/screens/admin/admin_dashboard_screen.dart';
import 'package:supa/cubits/theme_cubit.dart';
import 'package:supa/screens/auth/login_screen.dart';
import 'package:supa/screens/user/tenant_services_screen.dart';
import 'package:supa/models/tenant_model.dart';
import 'package:supa/models/service_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';

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
                      length: role == 'admin' ? 3 : 2,
                      child: Column(
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
                                        'adminPanel'.tr().isEmpty ? 'Admin Panel' : 'adminPanel'.tr(),
                                        style: GoogleFonts.outfit(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Opacity(
                                        opacity: 0.7,
                                        child: Text('liveMonitoring'.tr().isEmpty ? 'Live Service Monitoring' : 'liveMonitoring'.tr(), style: const TextStyle(color: Colors.white, fontSize: 13)),
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
                                      (context) => false,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                TabBar(
                                  labelColor: Colors.blue,
                                  unselectedLabelColor: Colors.grey[600],
                                  indicatorColor: Colors.blue,
                                  indicatorWeight: 3,
                                  dividerColor: Colors.transparent,
                                  tabs: [
                                    if (role == 'admin') Tab(text: "management".tr().isEmpty ? "Management" : "management".tr()),
                                    Tab(text: "users".tr().isEmpty ? "Users" : "users".tr()),
                                    Tab(text: "centers".tr().isEmpty ? "Centers" : "centers".tr()),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                if (role == 'admin') const AdminDashboardScreen(),
                                _buildUsersList(context, state, role),
                                _buildTenantsList(context, state, role),
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
    final cubit = context.read<AdminCubit>();
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
                cubit.updateUserRole(userId, value);
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
    final cubit = context.read<AdminCubit>();
    final tenants = await cubit.fetchTenants();

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
                    cubit.updateUserTenant(userId, null);
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
                  cubit.updateUserTenant(
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
    final cubit = context.read<AdminCubit>();
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
              cubit.deleteUser(userId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }

  void _showAddTenantDialog(BuildContext context) {
    final cubit = context.read<AdminCubit>();
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    File? selectedImage;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stateContext, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'addServiceCenter'.tr(),
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setState(() => selectedImage = File(picked.path));
                      }
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(30),
                        borderRadius: BorderRadius.circular(15),
                        image: selectedImage != null
                            ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: selectedImage == null
                          ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildModernField(
                    controller: nameController,
                    label: 'serviceCenterName'.tr(),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildModernField(
                    controller: addressController,
                    label: 'address'.tr(),
                  ),
                  const SizedBox(height: 12),
                  _buildModernField(
                    controller: phoneController,
                    label: 'phone'.tr(),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('cancel'.tr(), style: const TextStyle(color: Colors.white60)),
            ),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    String? imageUrl;
                    if (selectedImage != null) {
                      imageUrl = await cubit.uploadImage(selectedImage!.path, 'tenants');
                    }
                    await cubit.createTenant(
                      name: nameController.text.trim(),
                      address: addressController.text.trim(),
                      phone: phoneController.text.trim(),
                      imageUrl: imageUrl,
                    );
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('add'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTenantDialog(BuildContext context, Tenant tenant) {
    final cubit = context.read<AdminCubit>();
    final nameController = TextEditingController(text: tenant.name);
    final addressController = TextEditingController(text: tenant.address);
    final phoneController = TextEditingController(text: tenant.phone);
    final formKey = GlobalKey<FormState>();
    File? selectedImage;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stateContext, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'editServiceCenter'.tr(),
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setState(() => selectedImage = File(picked.path));
                      }
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(30),
                        borderRadius: BorderRadius.circular(15),
                        image: selectedImage != null
                            ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover)
                            : (tenant.imageUrl != null
                                ? DecorationImage(image: NetworkImage(tenant.imageUrl!), fit: BoxFit.cover)
                                : null),
                      ),
                      child: selectedImage == null && tenant.imageUrl == null
                          ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildModernField(
                    controller: nameController,
                    label: 'serviceCenterName'.tr(),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildModernField(
                    controller: addressController,
                    label: 'address'.tr(),
                  ),
                  const SizedBox(height: 12),
                  _buildModernField(
                    controller: phoneController,
                    label: 'phone'.tr(),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('cancel'.tr(), style: const TextStyle(color: Colors.white60)),
            ),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setState(() => isSaving = true);
                          try {
                            String? imageUrl = tenant.imageUrl;
                            if (selectedImage != null) {
                              final newUrl = await cubit.uploadImage(selectedImage!.path, 'tenants');
                              if (newUrl != null) imageUrl = newUrl;
                            }
                            await cubit.updateTenant(
                              id: tenant.id,
                              name: nameController.text.trim(),
                              address: addressController.text.trim(),
                              phone: phoneController.text.trim(),
                              imageUrl: imageUrl,
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          } catch (e) {
                            if (stateContext.mounted) {
                              ScaffoldMessenger.of(stateContext).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                              );
                            }
                          } finally {
                            if (stateContext.mounted) {
                              setState(() => isSaving = false);
                            }
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('save'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
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
          'confirmDeleteCenter'.tr(args: [tenant.name]).isEmpty 
              ? 'Confirm delete ${tenant.name}? All associated data may be affected.'
              : 'confirmDeleteCenter'.tr(args: [tenant.name]),
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
    
    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    final services = await cubit.fetchServicesForTenant(tenant.id);

    if (!context.mounted) return;
    Navigator.pop(context); // Pop loading dialog

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stateContext, setDialogState) => AlertDialog(
          title: Text('${tenant.name}: ${'services'.tr()}'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (services.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('noServicesInCategory'.tr()),
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                onPressed: () => _showEditServiceDialog(
                                  context,
                                  tenant.id,
                                  service,
                                  () async {
                                    final updated = await cubit.fetchServicesForTenant(tenant.id);
                                    setDialogState(() {
                                      services.clear();
                                      services.addAll(updated);
                                    });
                                  },
                                ),
                              ),
                              IconButton(
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
                            ],
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
                  label: Text('addService'.tr()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('close'.tr()),
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
    final cubit = context.read<AdminCubit>();
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
        builder: (stateContext, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'addNewService'.tr(),
            style:
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Suggestions Chips
                  Text(
                    'suggestions'.tr(),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
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
                  Text(
                    'category'.tr(),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
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
                    label: 'serviceName'.tr(),
                    validator: (v) => v!.isEmpty ? 'required'.tr() : null,
                  ),
                  const SizedBox(height: 12),
                  _buildModernField(
                    controller: descController,
                    label: 'description'.tr(),
                    maxLines: 2,
                    validator: (v) => v!.isEmpty ? 'required'.tr() : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernField(
                          controller: durationController,
                          label: 'durationHoursLabel'.tr(),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              double.tryParse(v ?? '') == null ? '?' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModernField(
                          controller: priceController,
                          label: 'priceLabel'.tr(),
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
              child: Text(
                'cancel'.tr(),
                style: const TextStyle(color: Colors.white54),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final newService = Service(
                      id: '',
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                      price: double.parse(priceController.text),
                      category: selectedCategory,
                      durationHours: double.parse(durationController.text),
                      tenantId: tenantId,
                    );
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
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
                child: Text(
                  'create'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditServiceDialog(
    BuildContext context,
    String tenantId,
    Service service,
    VoidCallback onUpdated,
  ) {
    final cubit = context.read<AdminCubit>();
    final nameController = TextEditingController(text: service.name);
    final priceController =
        TextEditingController(text: service.price.toString());
    final descController = TextEditingController(text: service.description);
    final durationController =
        TextEditingController(text: service.durationHours.toString());
    String selectedCategory = service.category;
    final formKey = GlobalKey<FormState>();

    final categories = [
      'Тех. обслуживание',
      'Ремонт двигателя',
      'Ходовая часть',
      'Электрика',
      'Кузовной ремонт',
      'Шиномонтаж',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stateContext, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'editService'.tr().isEmpty ? 'Edit Service' : 'editService'.tr(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Dropdown
                  Text(
                    'category'.tr(),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
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
                    label: 'serviceName'.tr(),
                    validator: (v) => v!.isEmpty ? 'required'.tr() : null,
                  ),
                  const SizedBox(height: 12),
                  _buildModernField(
                    controller: descController,
                    label: 'description'.tr(),
                    maxLines: 2,
                    validator: (v) => v!.isEmpty ? 'required'.tr() : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernField(
                          controller: durationController,
                          label: 'durationHoursLabel'.tr(),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              double.tryParse(v ?? '') == null ? '?' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModernField(
                          controller: priceController,
                          label: 'priceLabel'.tr(),
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
              child: Text(
                'cancel'.tr(),
                style: const TextStyle(color: Colors.white54),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final updatedService = Service(
                      id: service.id,
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                      price: double.parse(priceController.text),
                      category: selectedCategory,
                      durationHours: double.parse(durationController.text),
                      tenantId: tenantId,
                    );
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    await cubit.updateService(updatedService);
                    onUpdated();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'save'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withAlpha(20),
                        Theme.of(context).primaryColor.withAlpha(5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Material(
                      color: Colors.transparent,
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
                                      color: Theme.of(context).primaryColor.withAlpha(30),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.business,
                                      color: Colors.deepPurple,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tenant.name,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        if (tenant.address != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Opacity(
                                              opacity: 0.7,
                                              child: Text(
                                                tenant.address!,
                                                style: const TextStyle(fontSize: 14),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (role == 'admin')
                                    IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed: () => _showTenantOptions(context, tenant),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  if (tenant.phone != null)
                                    _buildCenterFeature(
                                      context,
                                      Icons.phone_in_talk,
                                      tenant.phone!,
                                      Colors.blue,
                                    ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'select'.tr().toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildCenterFeature(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showTenantOptions(BuildContext context, Tenant tenant) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (modalContext) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_task, color: Colors.purple),
              title: const Text('Manage Services'),
              onTap: () {
                Navigator.pop(modalContext);
                _showManageServicesDialog(context, tenant);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Center'),
              onTap: () {
                Navigator.pop(modalContext);
                _showEditTenantDialog(context, tenant);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Center'),
              onTap: () {
                Navigator.pop(modalContext);
                _showDeleteTenantDialog(context, tenant);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Settings Sheet for Admin/Mechanic
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

  // Removed old dashboardStats and _buildStatCard as they are replaced by AdminDashboardScreen
}

