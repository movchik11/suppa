import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/garage_cubit.dart';
import 'package:supa/screens/home/home_screen.dart';
import 'package:supa/services/brand_model_service.dart';
import 'package:supa/utils/input_formatters.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supa/components/glass_container.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class InitialVehicleScreen extends StatefulWidget {
  const InitialVehicleScreen({super.key});

  @override
  State<InitialVehicleScreen> createState() => _InitialVehicleScreenState();
}

class _InitialVehicleScreenState extends State<InitialVehicleScreen> {
  final _plateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedBrand;
  String? _selectedModel;
  int? _selectedYear;
  String? _selectedColor;
  XFile? _image;

  final List<int> _years = List.generate(
    30,
    (index) => DateTime.now().year - index,
  );
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
                    const Color(0xFF673AB7),
                    const Color(0xFF311B92),
                    const Color(0xFF0D47A1),
                  ]
                : [
                    const Color(0xFFE3F2FD),
                    const Color(0xFFBBDEFB),
                    const Color(0xFF90CAF9),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.directions_car,
                          size: 80,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.blue[800],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'addFirstVehicleTitle'.tr(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.blue[900],
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'addFirstVehicleSubtitle'.tr(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white70
                                    : Colors.black87,
                              ),
                        ),
                        const SizedBox(height: 30),

                        // Image Picker
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withAlpha(25)
                                  : Colors.blue.withAlpha(25),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white38
                                    : Colors.blue.withAlpha(50),
                              ),
                            ),
                            child: _image != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: kIsWeb
                                        ? Image.network(
                                            _image!.path,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.file(
                                            File(_image!.path),
                                            fit: BoxFit.cover,
                                          ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.add_a_photo,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'addPhoto'.tr(),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Brand Dropdown
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(labelText: 'brand'.tr()),
                          items: BrandModelService.getBrands().map((brand) {
                            return DropdownMenuItem(
                              value: brand,
                              child: Text(
                                brand,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedBrand = val;
                              _selectedModel = null;
                            });
                          },
                          validator: (val) {
                            if (val == null) {
                              return 'selectBrand'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Model Dropdown
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(labelText: 'model'.tr()),
                          items: _selectedBrand == null
                              ? []
                              : BrandModelService.getModels(
                                  _selectedBrand!,
                                ).map((model) {
                                  return DropdownMenuItem(
                                    value: model,
                                    child: Text(
                                      model,
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedModel = val),
                          validator: (val) {
                            if (val == null) {
                              return 'selectModel'.tr();
                            }
                            return null;
                          },
                          disabledHint: Text(
                            'selectBrandFirst'.tr(),
                            style: TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white38
                                  : Colors.black38,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Year and Color Dropdowns
                        DropdownButtonFormField<int>(
                          decoration: InputDecoration(labelText: 'year'.tr()),
                          items: _years
                              .map(
                                (y) => DropdownMenuItem(
                                  value: y,
                                  child: Text(
                                    y.toString(),
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedYear = val),
                          validator: (val) =>
                              val == null ? 'selectYear'.tr() : null,
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(labelText: 'color'.tr()),
                          items: _colors
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c.toLowerCase().tr(),
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedColor = val),
                          validator: (val) =>
                              val == null ? 'selectColor'.tr() : null,
                        ),
                        const SizedBox(height: 20),

                        // License Plate
                        TextFormField(
                          controller: _plateController,
                          inputFormatters: [LicensePlateFormatter()],
                          decoration: InputDecoration(
                            labelText: 'licensePlate'.tr(),
                            prefixIcon: const Icon(Icons.credit_card_outlined),
                            hintText: 'AG-1234-LB',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'enterPlate'.tr();
                            }
                            final reg = RegExp(r'^[A-Z]{2}-\d{4}-[A-Z]{2}$');
                            if (!reg.hasMatch(value)) {
                              return 'invalidPlateFormat'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),

                        // Action Button
                        BlocConsumer<GarageCubit, GarageState>(
                          listener: (context, state) {
                            if (state is VehicleActionSuccess) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomeScreen(),
                                ),
                                (route) => false,
                              );
                            } else if (state is GarageError) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(state.message)),
                              );
                            }
                          },
                          builder: (context, state) {
                            if (state is GarageLoading) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              );
                            }
                            return ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<GarageCubit>().addVehicle(
                                    brand: _selectedBrand!,
                                    model: _selectedModel!,
                                    year: _selectedYear,
                                    licensePlate: _plateController.text,
                                    color: _selectedColor,
                                    image: _image,
                                  );
                                }
                              },
                              child: Text('finish'.tr()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
