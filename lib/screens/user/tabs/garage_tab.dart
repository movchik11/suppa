import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:supa/cubits/garage_cubit.dart';
import 'package:supa/models/vehicle_model.dart';

class GarageTab extends StatelessWidget {
  const GarageTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GarageCubit()..fetchVehicles(),
      child: BlocConsumer<GarageCubit, GarageState>(
        listener: (context, state) {
          if (state is VehicleAdded) {
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vehicle added to your garage!')),
            );
          } else if (state is GarageError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddVehicleDialog(context),
              child: const Icon(Icons.add),
            ),
            body: _buildBody(context, state),
          );
        },
      ),
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

  void _showAddVehicleDialog(BuildContext context) {
    final brandController = TextEditingController();
    final modelController = TextEditingController();
    final yearController = TextEditingController();
    final plateController = TextEditingController();
    final colorController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Vehicle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: brandController,
                decoration: const InputDecoration(labelText: 'Brand'),
              ),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(labelText: 'Model'),
              ),
              TextField(
                controller: yearController,
                decoration: const InputDecoration(labelText: 'Year'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: plateController,
                decoration: const InputDecoration(labelText: 'License Plate'),
              ),
              TextField(
                controller: colorController,
                decoration: const InputDecoration(labelText: 'Color'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (brandController.text.isNotEmpty &&
                  modelController.text.isNotEmpty) {
                context.read<GarageCubit>().addVehicle(
                  brand: brandController.text,
                  model: modelController.text,
                  year: int.tryParse(yearController.text),
                  licensePlate: plateController.text,
                  color: colorController.text,
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.directions_car,
                color: Colors.blue,
                size: 40,
              ),
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
              onPressed: () =>
                  context.read<GarageCubit>().deleteVehicle(vehicle.id),
            ),
          ],
        ),
      ),
    );
  }
}
