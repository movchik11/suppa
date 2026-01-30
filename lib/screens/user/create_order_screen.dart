import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:supa/components/glass_container.dart';
import 'package:supa/cubits/order_cubit.dart';
import 'package:supa/cubits/garage_cubit.dart';
import 'package:intl/intl.dart';
import 'package:supa/models/service_model.dart';

class CreateOrderScreen extends StatefulWidget {
  final Service? preSelectedService;
  const CreateOrderScreen({super.key, this.preSelectedService});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _carModelController = TextEditingController();
  final _issueController = TextEditingController();
  String? _selectedVehicleId;
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedService != null) {
      _issueController.text =
          'Service: ${widget.preSelectedService!.name}\n${widget.preSelectedService!.description}';
    }
  }

  void dispose() {
    _carModelController.dispose();
    _issueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Service Order')),
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is OrderCreated) {
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Order created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          } else if (state is OrderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is OrderLoading) {
            return Center(
              child: Lottie.asset(
                'assets/animations/loading.json',
                height: 200,
                errorBuilder: (context, error, stackTrace) =>
                    const CircularProgressIndicator(),
              ),
            );
          }

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF673AB7),
                  Color(0xFF311B92),
                  Color(0xFF0D47A1),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: GlassContainer(
                  borderRadius: BorderRadius.circular(20),
                  blur: 10,
                  borderGradient: LinearGradient(
                    colors: [
                      Colors.white.withAlpha(153),
                      Colors.white.withAlpha(26),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withAlpha(26),
                      Colors.white.withAlpha(13),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.car_repair,
                            size: 80,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Service Request',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                          if (widget.preSelectedService != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Booking: ${widget.preSelectedService!.name}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.amberAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(height: 40),
                          // Vehicle Selection Dropdown
                          BlocBuilder<GarageCubit, GarageState>(
                            builder: (context, garageState) {
                              if (garageState is VehiclesLoaded &&
                                  garageState.vehicles.isNotEmpty) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedVehicleId,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        dropdownColor: const Color(0xFF311B92),
                                        decoration: const InputDecoration(
                                          labelText: 'Select Your Vehicle',
                                          labelStyle: TextStyle(
                                            color: Colors.white70,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.directions_car,
                                            color: Colors.white70,
                                          ),
                                          fillColor: Colors.white12,
                                          filled: true,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(10),
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        items: garageState.vehicles
                                            .map(
                                              (v) => DropdownMenuItem(
                                                value: v.id,
                                                child: Text(
                                                  '${v.brand} ${v.model} (${v.licensePlate})',
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            _selectedVehicleId = val;
                                            final vehicle = garageState.vehicles
                                                .firstWhere((v) => v.id == val);
                                            _carModelController.text =
                                                '${vehicle.brand} ${vehicle.model}';
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _showAddVehicleDialog(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white24,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: const Icon(Icons.add),
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: Text(
                                '— OR —',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          TextFormField(
                            controller: _carModelController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Car Model',
                              labelStyle: TextStyle(color: Colors.white70),
                              hintText: 'e.g., Toyota Camry 2020',
                              hintStyle: TextStyle(color: Colors.white38),
                              prefixIcon: Icon(
                                Icons.directions_car,
                                color: Colors.white70,
                              ),
                              fillColor: Colors.white12,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your car model';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _issueController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: 'Issue Description',
                              labelStyle: TextStyle(color: Colors.white70),
                              hintText: 'Describe the problem...',
                              hintStyle: TextStyle(color: Colors.white38),
                              prefixIcon: Icon(
                                Icons.description,
                                color: Colors.white70,
                              ),
                              fillColor: Colors.white12,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please describe the issue';
                              }
                              if (value.length < 10) {
                                return 'Please provide more details';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          // Date & Time Picker
                          GestureDetector(
                            onTap: () => _pickDateTime(context),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Scheduled Date & Time',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          _scheduledAt == null
                                              ? 'Tap to select'
                                              : DateFormat(
                                                  'MMM d, yyyy HH:mm',
                                                ).format(_scheduledAt!),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.edit,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                context.read<OrderCubit>().createOrder(
                                  _carModelController.text,
                                  _issueController.text,
                                  vehicleId: _selectedVehicleId,
                                  scheduledAt: _scheduledAt,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.deepPurple,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Submit Request',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _scheduledAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
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
              context.read<GarageCubit>().addVehicle(
                brand: brandController.text,
                model: modelController.text,
                year: int.tryParse(yearController.text) ?? 2020,
                licensePlate: plateController.text,
                color: colorController.text,
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
