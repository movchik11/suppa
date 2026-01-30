import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:supa/cubits/garage_cubit.dart';
import 'package:supa/models/vehicle_model.dart';
import 'package:image_picker/image_picker.dart';
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
      return Center(
        child: Lottie.asset(
          'assets/animations/loading.json',
          height: 200,
          errorBuilder: (context, error, stackTrace) =>
              const CircularProgressIndicator(),
        ),
      );
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
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.vehicles.length,
          itemBuilder: (context, index) {
            final vehicle = state.vehicles[index];
            return _VehicleCard(vehicle: vehicle);
          },
        ),
      );
    }
    return const SizedBox.shrink();
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
                                image: NetworkImage(
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
                          image: NetworkImage(vehicle.imageUrl!),
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
                    const SizedBox(height: 4),
                    if (vehicle.licensePlate != null)
                      Text(
                        'Plate: ${vehicle.licensePlate}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    if (vehicle.year != null)
                      Text(
                        'Year: ${vehicle.year}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
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
}
