import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supa/cubits/service_cubit.dart';
import 'package:supa/cubits/theme_cubit.dart';
import 'package:supa/models/service_model.dart';

class ServicesManagementScreen extends StatelessWidget {
  const ServicesManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ServiceCubit()..fetchServices(),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('manageServices'.tr()),
            actions: [
              PopupMenuButton<Locale>(
                icon: const Icon(Icons.language),
                onSelected: (locale) {
                  context.setLocale(locale);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: Locale('en'),
                    child: Text('English'),
                  ),
                  const PopupMenuItem(
                    value: Locale('ru'),
                    child: Text('Русский'),
                  ),
                  const PopupMenuItem(
                    value: Locale('tk'),
                    child: Text('Türkmençe'),
                  ),
                ],
              ),
              BlocBuilder<ThemeCubit, bool>(
                builder: (context, isLight) {
                  return IconButton(
                    icon: Icon(isLight ? Icons.dark_mode : Icons.light_mode),
                    onPressed: () => context.read<ThemeCubit>().toggleTheme(),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => context.read<ServiceCubit>().fetchServices(),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddServiceDialog(context),
            icon: const Icon(Icons.add),
            label: Text('addService'.tr()),
          ),
          body: BlocConsumer<ServiceCubit, ServiceState>(
            listener: (context, state) {
              if (state is ServiceCreated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('serviceCreated'.tr()),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is ServiceError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is ServiceLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ServicesLoaded) {
                if (state.services.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.construction,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text('noServicesYet'.tr()),
                        SizedBox(height: 8),
                        Text(
                          'addFirstService'.tr(),
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => context.read<ServiceCubit>().fetchServices(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: state.services.length,
                    itemBuilder: (context, index) {
                      final service = state.services[index];
                      return GestureDetector(
                        onTap: () => _showEditServiceDialog(context, service),
                        child: _ServiceCard(service: service),
                      );
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  void _showAddServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while loading
      builder: (dialogContext) => _ServiceFormDialog(
        onSubmit: (name, description, duration, price, category, image) async {
          await context.read<ServiceCubit>().createService(
            name: name,
            description: description,
            durationHours: duration,
            price: price,
            category: category,
            image: image,
          );
        },
      ),
    );
  }

  void _showEditServiceDialog(BuildContext context, Service service) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while loading
      builder: (dialogContext) => _ServiceFormDialog(
        initialService: service,
        onSubmit: (name, description, duration, price, category, image) async {
          await context.read<ServiceCubit>().updateService(
            serviceId: service.id,
            name: name,
            description: description,
            durationHours: duration,
            price: price,
            category: category,
            newImage: image,
            existingImageUrl: service.imageUrl,
          );
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: service.imageUrl != null
                  ? Image.network(
                      service.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.car_repair, size: 50),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.car_repair, size: 50),
                    ),
            ),
          ),
          // Details
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${service.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${service.durationHours}h',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showDeleteDialog(context, service.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String serviceId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('deleteService'.tr()),
        content: Text('confirmDeleteService'.tr(args: [service.name])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ServiceCubit>().deleteService(serviceId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }
}

class _ServiceFormDialog extends StatefulWidget {
  final Service? initialService;
  final Future<void> Function(
    String name,
    String description,
    double duration,
    double price,
    String category,
    XFile? image,
  )
  onSubmit;

  const _ServiceFormDialog({required this.onSubmit, this.initialService});

  @override
  State<_ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<_ServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
  late TextEditingController _priceController;
  String _selectedCategory = 'catMaintenance';
  XFile? _selectedImage;
  Uint8List? _webImageBytes;
  bool _isLoading = false;

  final Map<String, List<String>> _subServices = {
    'catMaintenance': ['oilFluidChange', 'filterReplacement', 'sparkPlugCheck'],
    'catDiagElectronics': [
      'computerDiagnostics',
      'chassisDiagnostics',
      'electricalRepair',
    ],
    'catCoreRepair': [
      'engineRepair',
      'transmissionRepair',
      'suspensionSteering',
      'brakingSystem',
    ],
    'catChassisWheels': ['tireFitting', 'wheelAlignment'],
    'catBodyVisual': ['bodyWork', 'paintPolishing', 'glassRepair'],
    'catAdditional': ['airConditioning', 'tuningEquipment', 'preSalePrep'],
  };

  final List<String> _categories = [
    'catMaintenance',
    'catDiagElectronics',
    'catCoreRepair',
    'catChassisWheels',
    'catBodyVisual',
    'catAdditional',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialService?.name ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialService?.description ?? '',
    );
    _durationController = TextEditingController(
      text: widget.initialService?.durationHours.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: widget.initialService?.price.toString() ?? '',
    );
    _selectedCategory = widget.initialService?.category ?? 'catMaintenance';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  bool _isPickingImage = false;

  Future<void> _pickImage() async {
    if (_isPickingImage) return;

    // Unfocus to avoid keyboard/picker conflict jank
    FocusScope.of(context).unfocus();

    setState(() {
      _isPickingImage = true;
    });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024, // Resize to prevent memory issues with massive photos
        imageQuality: 85, // Compress slightly
      );
      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _selectedImage = pickedFile;
            _webImageBytes = bytes;
          });
        } else {
          setState(() {
            _selectedImage = pickedFile;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('addNewService'.tr()),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                              : Image.file(
                                  File(_selectedImage!.path),
                                  fit: BoxFit.cover,
                                ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 50,
                              color: Colors.blue[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'tapToAddPhoto'.tr(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: Text('choosePhoto'.tr()),
              ),
              const SizedBox(height: 24),
              // Category Selection First (moved up for better flow)
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'category'.tr(),
                  border: const OutlineInputBorder(),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat.tr()));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 24),
              // Sub-service templates
              if (_subServices[_selectedCategory] != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'suggestions'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _subServices[_selectedCategory]!.map((s) {
                    return ActionChip(
                      label: Text(s.tr(), style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.blue.withAlpha(20),
                      onPressed: () {
                        setState(() {
                          _nameController.text = s.tr();
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'serviceName'.tr(),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'description'.tr(),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                decoration: InputDecoration(
                  labelText: 'durationHoursLabel'.tr(),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (double.tryParse(value!) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'priceLabel'.tr(),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (double.tryParse(value!) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);
                    try {
                      await widget.onSubmit(
                        _nameController.text,
                        _descriptionController.text,
                        double.parse(_durationController.text),
                        double.parse(_priceController.text),
                        _selectedCategory,
                        _selectedImage,
                      );
                      if (mounted) Navigator.pop(context);
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.initialService != null ? 'update'.tr() : 'create'.tr(),
                ),
        ),
      ],
    );
  }
}
