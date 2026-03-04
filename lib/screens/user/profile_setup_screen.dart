import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/profile_cubit.dart';
import 'package:supa/screens/user/initial_vehicle_screen.dart';
import 'package:supa/utils/input_formatters.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supa/components/glass_container.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF673AB7), Color(0xFF311B92), Color(0xFF0D47A1)],
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
                        const Icon(
                          Icons.person_add,
                          size: 80,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'setupProfileTitle'.tr(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'setupProfileSubtitle'.tr(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 40),
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'name'.tr(),
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'enterName'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _phoneController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [PhoneNumberFormatter()],
                          decoration: InputDecoration(
                            labelText: 'phone'.tr(),
                            prefixIcon: const Icon(Icons.phone_outlined),
                            hintText: '+993-6x-xx-xx-xx',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'enterPhone'.tr();
                            }
                            if (value.length < 15) return 'invalidPhone'.tr();
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        BlocConsumer<ProfileCubit, ProfileState>(
                          listener: (context, state) {
                            if (state is ProfileActionSuccess) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const InitialVehicleScreen(),
                                ),
                                (route) => false,
                              );
                            } else if (state is ProfileError) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(state.message)),
                              );
                            }
                          },
                          builder: (context, state) {
                            if (state is ProfileLoading) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              );
                            }
                            return ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<ProfileCubit>().updateProfile(
                                    displayName: _nameController.text,
                                    phoneNumber: _phoneController.text,
                                  );
                                }
                              },
                              child: Text('continue'.tr()),
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
