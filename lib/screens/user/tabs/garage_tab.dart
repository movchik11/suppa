import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:supa/cubits/garage_cubit.dart';
import 'package:supa/models/vehicle_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supa/components/app_loading_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class GarageTab extends StatelessWidget {
  const GarageTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GarageCubit, GarageState>(
      listener: (context, state) {
        if (state is VehicleActionSuccess) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Garage updated successfully!')),
          );
        } else if (state is GarageError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showVehicleDialog(context),
            child: const Icon(Icons.add),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, GarageState state) {
    if (state is GarageLoading) {
      return const AppLoadingIndicator();
    } else if (state is VehiclesLoaded) {
      if (state.vehicles.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/drifting_car.json',
                height: 200,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.directions_car,
                  size: 80,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Your garage is empty'),
              const SizedBox(height: 8),
              const Text(
                'Add your car to track repair history',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => context.read<GarageCubit>().fetchVehicles(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- MAINTENANCE OVERVIEW ---
            _buildMaintenanceOverview(state.vehicles),
            const SizedBox(height: 24),

            _buildSectionHeader('Your Vehicles'),
            const SizedBox(height: 12),
            ...state.vehicles.map((v) => _VehicleCard(vehicle: v)),

            const SizedBox(height: 24),
            _buildSectionHeader('Recent Expenses'),
            const SizedBox(height: 12),
            _buildExpenseLedger(state.expenses, state.vehicles),
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildMaintenanceOverview(List<Vehicle> vehicles) {
    int upcomingServices = vehicles
        .where(
          (v) =>
              v.nextServiceMileage != null ||
              (v.lastServiceDate != null &&
                  v.lastServiceDate!.isBefore(
                    DateTime.now().subtract(const Duration(days: 180)),
                  )),
        )
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withAlpha(51)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: Colors.blue, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$upcomingServices Upcoming Services',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Text(
                  'Keep your cars in top shape!',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildExpenseLedger(List<dynamic> expenses, List<Vehicle> vehicles) {
    if (expenses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No expenses recorded yet',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: expenses.take(5).map((e) {
          final vehicle = vehicles.firstWhere(
            (v) => v.id == e.vehicleId,
            orElse: () => vehicles.first,
          );
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.white12,
              child: Icon(Icons.receipt_long, size: 20, color: Colors.blue),
            ),
            title: Text(e.category),
            subtitle: Text('${vehicle.brand} ${vehicle.model}'),
            trailing: Text(
              '-\$${e.amount.toStringAsFixed(2)}',
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
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();
  XFile? _image;

  @override
  void initState() {
    super.initState();
    if (widget.initialVehicle != null) {
      _brandController.text = widget.initialVehicle!.brand;
      _modelController.text = widget.initialVehicle!.model;
      _yearController.text = widget.initialVehicle!.year?.toString() ?? '';
      _plateController.text = widget.initialVehicle!.licensePlate ?? '';
      _colorController.text = widget.initialVehicle!.color ?? '';
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
      title: Text(isEditing ? 'Edit Vehicle' : 'Add Vehicle'),
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
                  image: _image != null
                      ? DecorationImage(
                          image: FileImage(File(_image!.path)),
                          fit: BoxFit.cover,
                        )
                      : (widget.initialVehicle?.imageUrl != null
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(
                                  widget.initialVehicle!.imageUrl!,
                                ),
                                fit: BoxFit.cover,
                              )
                            : null),
                ),
                child: _image == null && widget.initialVehicle?.imageUrl == null
                    ? const Icon(
                        Icons.add_a_photo,
                        size: 40,
                        color: Colors.grey,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _brandController,
              decoration: const InputDecoration(labelText: 'Brand'),
            ),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(labelText: 'Model'),
            ),
            TextField(
              controller: _yearController,
              decoration: const InputDecoration(labelText: 'Year'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _plateController,
              decoration: const InputDecoration(labelText: 'License Plate'),
            ),
            TextField(
              controller: _colorController,
              decoration: const InputDecoration(labelText: 'Color'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_brandController.text.isNotEmpty &&
                _modelController.text.isNotEmpty) {
              if (isEditing) {
                context.read<GarageCubit>().updateVehicle(
                  vehicleId: widget.initialVehicle!.id,
                  brand: _brandController.text,
                  model: _modelController.text,
                  year: int.tryParse(_yearController.text),
                  licensePlate: _plateController.text,
                  color: _colorController.text,
                  newImage: _image,
                  existingImageUrl: widget.initialVehicle!.imageUrl,
                );
              } else {
                context.read<GarageCubit>().addVehicle(
                  brand: _brandController.text,
                  model: _modelController.text,
                  year: int.tryParse(_yearController.text),
                  licensePlate: _plateController.text,
                  color: _colorController.text,
                  image: _image,
                );
              }
              Navigator.pop(context);
            }
          },
          child: Text(isEditing ? 'Save' : 'Add'),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          // Open edit dialog
          showDialog(
            context: context,
            builder: (dialogContext) => BlocProvider.value(
              value: context.read<GarageCubit>(),
              child: _VehicleFormDialog(initialVehicle: vehicle),
            ),
          );
        },
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
                        'Service at ${vehicle.nextServiceMileage} km',
                        Colors.orange,
                      ),
                    if (vehicle.insuranceExpiry != null)
                      _buildReminderBadge(
                        Icons.security,
                        'Ins: ${DateFormat('MMM yyyy').format(vehicle.insuranceExpiry!)}',
                        Colors.blue,
                      ),
                    if (vehicle.nextServiceMileage == null &&
                        vehicle.insuranceExpiry == null)
                      Text(
                        'Plate: ${vehicle.licensePlate ?? 'N/A'}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_chart, color: Colors.blue, size: 20),
                onPressed: () => _showExpenseDialog(context, vehicle.id),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Delete Vehicle'),
                      content: const Text(
                        'Are you sure you want to remove this vehicle from your garage?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<GarageCubit>().deleteVehicle(
                              vehicle.id,
                            );
                            Navigator.pop(dialogContext);
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
        title: const Text('Add Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount (\$)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                'Fuel',
                'Repair',
                'Service',
                'Wash',
                'Insurance',
                'Other',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => selectedCategory = val!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
