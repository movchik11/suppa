import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/order_cubit.dart';
import 'package:supa/cubits/garage_cubit.dart';
import 'package:supa/cubits/service_cubit.dart';
import 'package:supa/components/app_loading_indicator.dart';
import 'package:supa/components/glass_container.dart';
import 'package:supa/models/service_model.dart';
import 'package:easy_localization/easy_localization.dart';

class CreateOrderScreen extends StatefulWidget {
  final Service? preSelectedService;
  final String? preFillDescription;
  final String? suggestedServiceTitle;

  const CreateOrderScreen({
    super.key,
    this.preSelectedService,
    this.preFillDescription,
    this.suggestedServiceTitle,
  });

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _carModelController = TextEditingController();
  final _issueController = TextEditingController();
  String? _selectedVehicleId;
  String? _selectedServiceId; // New state for dropdown
  DateTime? _scheduledAt;
  String? _selectedBranch;
  String _selectedUrgency = 'normal';

  final List<String> _urgencies = ['normal', 'urgent', 'emergency'];
  final List<String> _branches = ['mainBranch', 'westBranch'];

  @override
  void initState() {
    super.initState();
    // Ensure services are loaded
    context.read<ServiceCubit>().fetchServices();
    if (widget.preFillDescription != null) {
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
      appBar: AppBar(
        title: Text(
          widget.preSelectedService != null
              ? widget.preSelectedService!.name
              : (widget.suggestedServiceTitle ?? 'bookService'.tr()),
        ),
      ),
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is OrderCreated) {
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('orderSuccess'.tr()),
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
            return AppLoadingIndicator(message: 'generatingOrder'.tr());
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).scaffoldBackgroundColor,
                ],
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
                            'premiumBooking'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.titleLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // --- SERVICE SELECTION (If not pre-selected) ---
                          if (widget.preSelectedService == null) ...[
                            _buildLabel('selectService'.tr()),
                            BlocBuilder<ServiceCubit, ServiceState>(
                              builder: (context, serviceState) {
                                if (serviceState is ServicesLoaded) {
                                  // Ensure selected ID is valid
                                  if (_selectedServiceId != null &&
                                      !serviceState.services.any(
                                        (s) => s.id == _selectedServiceId,
                                      )) {
                                    _selectedServiceId = null;
                                  }

                                  return DropdownButtonFormField<String>(
                                    value: _selectedServiceId,
                                    dropdownColor: const Color(0xFF1E1E2E),
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.build,
                                        color: Colors.blue,
                                      ),
                                      // ignore: use_build_context_synchronously
                                      hintText: 'chooseFromCatalog'.tr(),
                                      hintStyle: TextStyle(
                                        color: Theme.of(context).hintColor,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    items: serviceState.services
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s.id,
                                            child: Text(s.name),
                                          ),
                                        )
                                        .toList(),
                                    validator: (v) => v == null
                                        ? 'selectionRequired'.tr()
                                        : null,
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedServiceId = val;
                                      });
                                    },
                                  );
                                }
                                return const Center(
                                  child: LinearProgressIndicator(),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],

                          // --- PRE-SELECTED SERVICE (User Feedback) ---
                          if (widget.preSelectedService != null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(25),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.blue.withAlpha(100),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'selectedService'.tr(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade200,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          widget.preSelectedService!.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          '\$${widget.preSelectedService!.price.toStringAsFixed(2)} • ${widget.preSelectedService!.durationHours}h',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // --- VEHICLE SELECTION ---
                          _buildLabel('yourVehicle'.tr()),
                          BlocBuilder<GarageCubit, GarageState>(
                            builder: (context, garageState) {
                              if (garageState is VehiclesLoaded) {
                                if (garageState.vehicles.isEmpty) {
                                  return ElevatedButton.icon(
                                    onPressed: () =>
                                        _showAddVehicleDialog(context),
                                    icon: const Icon(Icons.add),
                                    label: Text('addVehicleFirst'.tr()),
                                  );
                                }
                                return DropdownButtonFormField<String>(
                                  initialValue: _selectedVehicleId,
                                  dropdownColor: const Color(0xFF1E1E2E),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(
                                      Icons.directions_car,
                                      color: Colors.blue,
                                    ),
                                    hintText: 'chooseFromGarage'.tr(),
                                    hintStyle: TextStyle(
                                      color: Theme.of(context).hintColor,
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
                                  validator: (v) => v == null
                                      ? 'selectionRequired'.tr()
                                      : null,
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
                          _buildLabel('serviceCenter'.tr()),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedBranch,
                            dropdownColor: const Color(0xFF1E1E2E),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.store,
                                color: Colors.blue,
                              ),
                              hintText: 'selectLocation'.tr(),
                              hintStyle: TextStyle(
                                color: Theme.of(context).hintColor,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: _branches
                                .map(
                                  (b) => DropdownMenuItem(
                                    value: b,
                                    child: Text(b.tr()),
                                  ),
                                )
                                .toList(),
                            validator: (v) =>
                                v == null ? 'locationRequired'.tr() : null,
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
                                    _buildLabel('urgency'.tr()),
                                    DropdownButtonFormField<String>(
                                      initialValue: _selectedUrgency,
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
                                              child: Text(u.tr()),
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
                                    _buildLabel('dateTime'.tr()),
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
                                                  ? 'select'.tr()
                                                  : DateFormat(
                                                      'MM/dd HH:mm',
                                                    ).format(_scheduledAt!),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge?.color,
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
                          _buildLabel('issueDescription'.tr()),
                          TextFormField(
                            controller: _issueController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'describeIssue'.tr(),
                              hintStyle: TextStyle(
                                color: Theme.of(context).hintColor,
                              ),
                              fillColor: Theme.of(
                                context,
                              ).cardColor.withAlpha(51),
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'required'.tr()
                                : null,
                          ),

                          const SizedBox(height: 32),

                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                if (_scheduledAt == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('selectDateTime'.tr()),
                                    ),
                                  );
                                  return;
                                }
                                String? serviceName =
                                    widget.preSelectedService?.name;
                                if (serviceName == null &&
                                    _selectedServiceId != null) {
                                  final serviceState = context
                                      .read<ServiceCubit>()
                                      .state;
                                  if (serviceState is ServicesLoaded) {
                                    final s = serviceState.services.firstWhere(
                                      (s) => s.id == _selectedServiceId,
                                    );
                                    serviceName = s.name;
                                  }
                                }

                                context.read<OrderCubit>().createOrder(
                                  serviceName ??
                                      widget.suggestedServiceTitle ??
                                      'General Service',
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
                            child: Text(
                              'confirmAppointment'.tr(),
                              style: const TextStyle(
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
    final modelC = TextEditingController();
    final plateC = TextEditingController();
    String? sBrand;
    String? sColor;
    int? sYear;

    final List<String> brands = [
      'Opel',
      'BMW',
      'Mercedes',
      'Toyota',
      'Ford',
      'Hyundai',
      'Kia',
      'Other',
    ];
    final List<String> colors = [
      'White',
      'Black',
      'Silver',
      'Grey',
      'Blue',
      'Red',
      'Gold',
    ];
    final List<int> years = List.generate(27, (index) => 2026 - index);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          title: Text(
            'newVehicle'.tr(),
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: sBrand,
                    dropdownColor: const Color(0xFF1E1E2E),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(labelText: 'brand'.tr()),
                    items: brands
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (val) => setState(() => sBrand = val),
                  ),
                  TextField(
                    controller: modelC,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(labelText: 'model'.tr()),
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: sYear,
                    dropdownColor: const Color(0xFF1E1E2E),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(labelText: 'year'.tr()),
                    items: years
                        .map(
                          (y) => DropdownMenuItem(
                            value: y,
                            child: Text(y.toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => sYear = val),
                  ),
                  TextFormField(
                    controller: plateC,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      labelText: '${'licensePlate'.tr()} (XX-XXXX-XX)',
                      hintText: 'e.g. AG-1234-LB',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'plateRequired'.tr();
                      final reg = RegExp(r'^[A-Z]{2}-\d{4}-[A-Z]{2}$');
                      if (!reg.hasMatch(value)) return 'Format: XX-XXXX-XX';
                      final suffix = value.substring(value.length - 2);
                      final allowed = ['AG', 'LB', 'MR', 'DZ', 'AH', 'AK'];
                      if (!allowed.contains(suffix))
                        return 'Invalid regional code';
                      return null;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: sColor,
                    dropdownColor: const Color(0xFF1E1E2E),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(labelText: 'color'.tr()),
                    items: colors
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setState(() => sColor = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate() &&
                    sBrand != null &&
                    modelC.text.isNotEmpty) {
                  context.read<GarageCubit>().addVehicle(
                    brand: sBrand!,
                    model: modelC.text,
                    year: sYear,
                    licensePlate: plateC.text,
                    color: sColor ?? 'Not set',
                  );
                  Navigator.pop(ctx);
                }
              },
              child: Text('save'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
