import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/order_cubit.dart';
import 'package:supa/cubits/garage_cubit.dart';
import 'package:supa/components/app_loading_indicator.dart';
import 'package:supa/components/glass_container.dart';
import 'package:intl/intl.dart';
import 'package:supa/models/service_model.dart';

class CreateOrderScreen extends StatefulWidget {
  final Service? preSelectedService;
  final String? preFillDescription;

  const CreateOrderScreen({
    super.key,
    this.preSelectedService,
    this.preFillDescription,
  });

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _carModelController = TextEditingController();
  final _issueController = TextEditingController();
  String? _selectedVehicleId;
  DateTime? _scheduledAt;
  String? _selectedBranch;
  String _selectedUrgency = 'Normal';

  final List<String> _urgencies = ['Normal', 'Urgent', 'Emergency'];
  final List<String> _branches = [
    'Main Service Center',
    'West Branch & Body Shop',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedService != null) {
      _issueController.text =
          'Service: ${widget.preSelectedService!.name}\n${widget.preSelectedService!.description}';
    } else if (widget.preFillDescription != null) {
      _issueController.text = widget.preFillDescription!;
    }
  }

  @override
  void dispose() {
    _carModelController.dispose();
    _issueController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Service')),
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
            return const AppLoadingIndicator(message: 'Generating order...');
          }

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF673AB7), Color(0xFF0F0F1E)],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: GlassContainer(
                  borderRadius: BorderRadius.circular(24),
                  blur: 15,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.car_repair_outlined,
                            size: 60,
                            color: Colors.white70,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Premium Service Booking',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // --- VEHICLE SELECTION ---
                          _buildLabel('YOUR VEHICLE'),
                          BlocBuilder<GarageCubit, GarageState>(
                            builder: (context, garageState) {
                              if (garageState is VehiclesLoaded) {
                                if (garageState.vehicles.isEmpty) {
                                  return ElevatedButton.icon(
                                    onPressed: () =>
                                        _showAddVehicleDialog(context),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add a Vehicle First'),
                                  );
                                }
                                return DropdownButtonFormField<String>(
                                  value: _selectedVehicleId,
                                  dropdownColor: const Color(0xFF1E1E2E),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(
                                      Icons.directions_car,
                                      color: Colors.blue,
                                    ),
                                    hintText: 'Choose from garage',
                                    hintStyle: const TextStyle(
                                      color: Colors.white38,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
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
                                  validator: (v) =>
                                      v == null ? 'Selection required' : null,
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedVehicleId = val;
                                      final vehicle = garageState.vehicles
                                          .firstWhere((v) => v.id == val);
                                      _carModelController.text =
                                          '${vehicle.brand} ${vehicle.model}';
                                    });
                                  },
                                );
                              }
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          ),
                          const SizedBox(height: 20),

                          // --- BRANCH SELECTION ---
                          _buildLabel('SERVICE CENTER'),
                          DropdownButtonFormField<String>(
                            value: _selectedBranch,
                            dropdownColor: const Color(0xFF1E1E2E),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.store,
                                color: Colors.blue,
                              ),
                              hintText: 'Select location',
                              hintStyle: const TextStyle(color: Colors.white38),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: _branches
                                .map(
                                  (b) => DropdownMenuItem(
                                    value: b,
                                    child: Text(b),
                                  ),
                                )
                                .toList(),
                            validator: (v) =>
                                v == null ? 'Location required' : null,
                            onChanged: (val) =>
                                setState(() => _selectedBranch = val),
                          ),
                          const SizedBox(height: 20),

                          // --- URGENCY & DATE ---
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('URGENCY'),
                                    DropdownButtonFormField<String>(
                                      value: _selectedUrgency,
                                      dropdownColor: const Color(0xFF1E1E2E),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      items: _urgencies
                                          .map(
                                            (u) => DropdownMenuItem(
                                              value: u,
                                              child: Text(u),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) => setState(
                                        () => _selectedUrgency = val!,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('DATE/TIME'),
                                    GestureDetector(
                                      onTap: () => _pickDateTime(context),
                                      child: Container(
                                        height: 56,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.white24,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.event,
                                              size: 18,
                                              color: Colors.blue,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _scheduledAt == null
                                                  ? 'Select'
                                                  : DateFormat(
                                                      'MM/dd HH:mm',
                                                    ).format(_scheduledAt!),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // --- ISSUE DESCRIPTION ---
                          _buildLabel('ISSUE DESCRIPTION'),
                          TextFormField(
                            controller: _issueController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'What is wrong with the car?',
                              hintStyle: const TextStyle(color: Colors.white38),
                              fillColor: Colors.white.withAlpha(15),
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                          ),

                          const SizedBox(height: 32),

                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                if (_scheduledAt == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please select a date/time',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                context.read<OrderCubit>().createOrder(
                                  _carModelController.text,
                                  _issueController.text,
                                  vehicleId: _selectedVehicleId,
                                  scheduledAt: _scheduledAt,
                                  branchName: _selectedBranch,
                                  urgencyLevel: _selectedUrgency,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 8,
                            ),
                            child: const Text(
                              'CONFIRM APPOINTMENT',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
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

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showAddVehicleDialog(BuildContext context) {
    final brandC = TextEditingController();
    final modelC = TextEditingController();
    final yearC = TextEditingController();
    final plateC = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('New Vehicle', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: brandC,
              decoration: const InputDecoration(labelText: 'Brand'),
            ),
            TextField(
              controller: modelC,
              decoration: const InputDecoration(labelText: 'Model'),
            ),
            TextField(
              controller: yearC,
              decoration: const InputDecoration(labelText: 'Year'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: plateC,
              decoration: const InputDecoration(labelText: 'License Plate'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<GarageCubit>().addVehicle(
                brand: brandC.text,
                model: modelC.text,
                year: int.tryParse(yearC.text) ?? 2022,
                licensePlate: plateC.text,
                color: 'Not set',
              );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
