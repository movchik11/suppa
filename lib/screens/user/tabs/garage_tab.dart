import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/garage_cubit.dart';
import 'package:supa/models/vehicle_model.dart';
import 'package:supa/models/document_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:supa/utils/input_formatters.dart';
import 'package:lottie/lottie.dart';
import 'package:supa/components/ui/bouncy_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supa/screens/user/vehicle_service_history_screen.dart';
import 'package:supa/utils/haptics.dart';
import 'package:supa/components/ui/skeleton_wrapper.dart';

class GarageTab extends StatelessWidget {
  final VoidCallback? onNavigateToServices;
  const GarageTab({super.key, this.onNavigateToServices});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GarageCubit, GarageState>(
      listener: (context, state) {
        if (state is VehicleActionSuccess) {
          AppHaptics.success();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('garageUpdated'.tr())));
        } else if (state is GarageError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 80.0),
            child: FloatingActionButton(
              onPressed: () {
                AppHaptics.medium();
                _showVehicleDialog(context);
              },
              child: const Icon(Icons.add),
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, GarageState state) {
    final isLoading = state is GarageLoading;
    final vehicles = state is VehiclesLoaded ? state.vehicles : <Vehicle>[];
    final expenses = state is VehiclesLoaded ? state.expenses : [];

    if (state is VehiclesLoaded && vehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/car_repair.json',
              height: 150,
              repeat: true,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.car_repair, size: 100, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              'noVehicles'.tr(),
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 16,
              ),
            ),
            // ...
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                AppHaptics.medium();
                _showVehicleDialog(context);
              },
              icon: const Icon(Icons.add),
              label: Text('addVehicle'.tr()),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        AppHaptics.light();
        await context.read<GarageCubit>().fetchVehicles();
      },
      child: SkeletonWrapper(
        isLoading: isLoading,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader(context, 'yourVehicles'.tr()),
            const SizedBox(height: 12),
            if (isLoading)
              ...List.generate(
                3,
                (index) => _VehicleCard(
                  vehicle: Vehicle(
                    id: 'loading',
                    userId: 'loading',
                    brand: 'Loading',
                    model: 'Car Model',
                    year: 2024,
                    licensePlate: 'XX-0000-XX',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                ),
              )
            else
              ...vehicles.map((v) => _VehicleCard(vehicle: v)),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'recentExpenses'.tr()),
            const SizedBox(height: 12),
            _buildExpenseLedger(context, expenses, vehicles),
            const SizedBox(height: 100), // Space for FAB and Glass Nav Bar
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleLarge?.color,
      ),
    );
  }

  Widget _buildExpenseLedger(
    BuildContext context,
    List<dynamic> expenses,
    List<Vehicle> vehicles,
  ) {
    if (expenses.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'noExpensesYet'.tr(),
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: expenses.take(5).map((e) {
          final vehicle = vehicles.isEmpty
              ? null
              : vehicles.firstWhere(
                  (v) => v.id == e.vehicleId,
                  orElse: () => vehicles.first,
                );

          if (vehicle == null) return const SizedBox.shrink();
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.white12,
              child: Icon(Icons.receipt_long, size: 20, color: Colors.blue),
            ),
            title: Text((e.category as String? ?? 'other').toLowerCase().tr()),
            subtitle: Text('${vehicle.brand} ${vehicle.model}'),
            trailing: Text(
              '-${e.amount.toStringAsFixed(2)} TMT',
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showVehicleDialog(BuildContext context, {Vehicle? initialVehicle}) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<GarageCubit>(),
        child: _VehicleFormDialog(initialVehicle: initialVehicle),
      ),
    );
  }
}

class _VehicleFormDialog extends StatefulWidget {
  final Vehicle? initialVehicle;
  const _VehicleFormDialog({this.initialVehicle});

  @override
  State<_VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<_VehicleFormDialog> {
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  XFile? _image;

  String? _selectedBrand;
  String? _selectedColor;
  int? _selectedYear;

  final List<String> _brands = [
    'Opel',
    'BMW',
    'Mercedes',
    'Toyota',
    'Ford',
    'Hyundai',
    'Kia',
    'Honda',
    'Mazda',
    'Nissan',
    'Volkswagen',
    'Audi',
    'Lexus',
    'Tesla',
    'Other',
  ];
  final List<String> _colors = [
    'White',
    'Black',
    'Silver',
    'Grey',
    'Blue',
    'Red',
    'Gold',
    'Green',
    'Yellow',
    'Brown',
    'Beige',
  ];
  final List<int> _years = List.generate(27, (index) => 2026 - index);

  @override
  void initState() {
    super.initState();
    if (widget.initialVehicle != null) {
      _selectedBrand = _brands.firstWhere(
        (b) => b.toLowerCase() == widget.initialVehicle!.brand.toLowerCase(),
        orElse: () => 'Other',
      );
      _modelController.text = widget.initialVehicle!.model;
      _selectedYear = widget.initialVehicle!.year;
      _plateController.text = widget.initialVehicle!.licensePlate ?? '';
      _selectedColor = _colors.firstWhere(
        (c) => c.toLowerCase() == widget.initialVehicle!.color?.toLowerCase(),
        orElse: () => 'White',
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialVehicle != null;
    return AlertDialog(
      title: Text(isEditing ? 'edit'.tr() : 'addVehicle'.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_image != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? Image.network(_image!.path, fit: BoxFit.cover)
                            : Image.file(File(_image!.path), fit: BoxFit.cover),
                      )
                    else if (widget.initialVehicle?.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: widget.initialVehicle!.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, color: Colors.red),
                              SizedBox(height: 4),
                              Text(
                                'Image Error',
                                style: TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_image == null &&
                        widget.initialVehicle?.imageUrl == null)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'addPhoto'.tr(),
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedBrand,
              decoration: InputDecoration(
                labelText: 'brand'.tr(),
                border: const OutlineInputBorder(),
              ),
              items: _brands.map((brand) {
                return DropdownMenuItem(value: brand, child: Text(brand));
              }).toList(),
              onChanged: (val) => setState(() => _selectedBrand = val),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _modelController,
              decoration: InputDecoration(labelText: 'model'.tr()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _selectedYear,
              decoration: InputDecoration(
                labelText: 'year'.tr(),
                border: const OutlineInputBorder(),
              ),
              items: _years.map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text(year.toString()),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedYear = val),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _plateController,
              inputFormatters: [LicensePlateFormatter()],
              decoration: InputDecoration(
                labelText: '${'licensePlate'.tr()} (XX-XXXX-XX)',
                hintText: 'e.g. AG-1234-LB',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Plate is required';
                final reg = RegExp(r'^[A-Z]{2}-\d{4}-[A-Z]{2}$');
                if (!reg.hasMatch(value)) return 'Format: XX-XXXX-XX';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedColor,
              decoration: InputDecoration(
                labelText: 'color'.tr(),
                border: const OutlineInputBorder(),
              ),
              items: _colors.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(c.toLowerCase().tr()),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedColor = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedBrand != null && _modelController.text.isNotEmpty) {
              if (isEditing) {
                context.read<GarageCubit>().updateVehicle(
                  vehicleId: widget.initialVehicle!.id,
                  brand: _selectedBrand!,
                  model: _modelController.text,
                  year: _selectedYear,
                  licensePlate: _plateController.text,
                  color: _selectedColor ?? 'Not set',
                  newImage: _image,
                  existingImageUrl: widget.initialVehicle!.imageUrl,
                );
              } else {
                context.read<GarageCubit>().addVehicle(
                  brand: _selectedBrand!,
                  model: _modelController.text,
                  year: _selectedYear,
                  licensePlate: _plateController.text,
                  color: _selectedColor ?? 'Not set',
                  image: _image,
                );
              }
              Navigator.pop(context);
            }
          },
          child: Text(isEditing ? 'update'.tr() : 'add'.tr()),
        ),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      onPressed: () {
        AppHaptics.medium();
        // Open edit dialog
        showDialog(
          context: context,
          builder: (dialogContext) => BlocProvider.value(
            value: context.read<GarageCubit>(),
            child: _VehicleFormDialog(initialVehicle: vehicle),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                  image: vehicle.imageUrl != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(vehicle.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: vehicle.imageUrl == null
                    ? const Icon(
                        Icons.directions_car,
                        color: Colors.blue,
                        size: 40,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.brand} ${vehicle.model}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (vehicle.nextServiceMileage != null)
                      _buildReminderBadge(
                        Icons.settings_suggest,
                        'serviceAt'.tr(
                          args: [vehicle.nextServiceMileage.toString()],
                        ),
                        Colors.orange,
                      ),
                    if (vehicle.insuranceExpiry != null)
                      _buildReminderBadge(
                        Icons.security,
                        '${'insAbbrev'.tr()}: ${DateFormat('MMM yyyy').format(vehicle.insuranceExpiry!)}',
                        Colors.blue,
                      ),
                    if (vehicle.nextServiceMileage == null &&
                        vehicle.insuranceExpiry == null)
                      Text(
                        '${'plate'.tr()}: ${vehicle.licensePlate ?? 'na'.tr()}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(height: 12),
                    _buildDocumentVault(
                      context,
                      vehicle.id,
                      (context.read<GarageCubit>().state as VehiclesLoaded)
                          .documents,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.history,
                      color: Colors.orange,
                      size: 20,
                    ),
                    onPressed: () {
                      AppHaptics.medium();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              VehicleServiceHistoryScreen(vehicle: vehicle),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_chart,
                      color: Colors.blue,
                      size: 20,
                    ),
                    onPressed: () {
                      AppHaptics.light();
                      _showExpenseDialog(context, vehicle.id);
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.file_copy,
                      color: Colors.green,
                      size: 20,
                    ),
                    onPressed: () {
                      AppHaptics.light();
                      _showDocumentDialog(context, vehicle.id);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () {
                      AppHaptics.medium();
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text('deleteTitle'.tr()),
                          content: Text('confirmDelete'.tr()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text('cancel'.tr()),
                            ),
                            TextButton(
                              onPressed: () {
                                context.read<GarageCubit>().deleteVehicle(
                                  vehicle.id,
                                );
                                Navigator.pop(dialogContext);
                              },
                              child: Text(
                                'delete'.tr(),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderBadge(IconData icon, String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showExpenseDialog(BuildContext context, String vehicleId) {
    final amountController = TextEditingController();
    String selectedCategory = 'Fuel';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('addExpense'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: '${'amount'.tr()} (TMT)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: InputDecoration(labelText: 'category'.tr()),
              items: ['Fuel', 'Repair', 'Service', 'Wash', 'Insurance', 'Other']
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.toLowerCase().tr()),
                    ),
                  )
                  .toList(),
              onChanged: (val) => selectedCategory = val!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null) {
                context.read<GarageCubit>().addExpense(
                  vehicleId: vehicleId,
                  amount: amount,
                  category: selectedCategory,
                );
                Navigator.pop(context);
              }
            },
            child: Text('add'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentVault(
    BuildContext context,
    String vehicleId,
    List<VehicleDocument> allDocs,
  ) {
    final docs = allDocs.where((d) => d.vehicleId == vehicleId).toList();
    if (docs.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 25,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final doc = docs[index];
          String typeStr = doc.type.toString();
          String typeLabel = typeStr;
          if (typeStr == 'Insurance') typeLabel = 'docInsurance'.tr();
          if (typeStr == 'TechPass') typeLabel = 'docTechPass'.tr();
          if (typeStr == 'License') typeLabel = 'docLicense'.tr();

          return Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(25),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.withAlpha(51)),
            ),
            child: Row(
              children: [
                const Icon(Icons.description, size: 12, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  typeLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDocumentDialog(BuildContext context, String vehicleId) {
    final picker = ImagePicker();
    XFile? selectedImage;
    String selectedType = 'Insurance';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('uploadDoc'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: InputDecoration(labelText: 'docType'.tr()),
                items: [
                  DropdownMenuItem(
                    value: 'Insurance',
                    child: Text('docInsurance'.tr()),
                  ),
                  DropdownMenuItem(
                    value: 'TechPass',
                    child: Text('docTechPass'.tr()),
                  ),
                  DropdownMenuItem(
                    value: 'License',
                    child: Text('docLicense'.tr()),
                  ),
                  DropdownMenuItem(
                    value: 'Other',
                    child: Text('docOther'.tr()),
                  ),
                ],
                onChanged: (val) => selectedType = val!,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final img = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (img != null) setState(() => selectedImage = img);
                },
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white12),
                    image: selectedImage != null
                        ? DecorationImage(
                            image: FileImage(File(selectedImage!.path)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              'selectPhoto'.tr(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedImage != null) {
                  dialogContext.read<GarageCubit>().addDocument(
                    vehicleId: vehicleId,
                    type: selectedType,
                    image: selectedImage!,
                  );
                  Navigator.pop(dialogContext);
                }
              },
              child: Text('add'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
