import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/service_cubit.dart';
import 'package:supa/models/service_model.dart';
import 'package:supa/screens/user/create_order_screen.dart';
import 'package:supa/components/app_loading_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:easy_localization/easy_localization.dart';

class ServicesTab extends StatefulWidget {
  const ServicesTab({super.key});

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  String selectedCategory = 'all';

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

  @override
  Widget build(BuildContext context) {
    final List<String> categories = [
      'all',
      'catMaintenance',
      'catDiagElectronics',
      'catCoreRepair',
      'catChassisWheels',
      'catBodyVisual',
      'catAdditional',
    ];

    String getCategoryLabel(String cat) {
      return cat.tr();
    }

    return BlocBuilder<ServiceCubit, ServiceState>(
      builder: (context, state) {
        if (state is ServiceLoading) {
          return const AppLoadingIndicator();
        } else if (state is ServicesLoaded) {
          final filteredServices = selectedCategory == 'all'
              ? state.services
              : state.services
                    .where(
                      (s) =>
                          s.category.toLowerCase() ==
                          selectedCategory.toLowerCase(),
                    )
                    .toList();

          return Column(
            children: [
              // --- CATEGORY SELECTOR ---
              _buildCategorySelector(categories, getCategoryLabel),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<ServiceCubit>().fetchServices(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (selectedCategory == 'all') ...[
                        _buildSectionHeader(context, 'allServices'.tr()),
                        const SizedBox(height: 12),
                      ] else ...[
                        // --- SUGGESTIONS FOR CATEGORY ---
                        if (_subServices[selectedCategory] != null) ...[
                          _buildSectionHeader(context, 'ourServices'.tr()),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 44,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _subServices[selectedCategory]!.length,
                              itemBuilder: (context, index) {
                                final sKey =
                                    _subServices[selectedCategory]![index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ActionChip(
                                    label: Text(
                                      sKey.tr(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    backgroundColor: Colors.blue.withAlpha(20),
                                    side: const BorderSide(color: Colors.blue),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CreateOrderScreen(
                                                suggestedServiceTitle: sKey
                                                    .tr(),
                                              ),
                                        ),
                                      ).then((value) {
                                        if (value == true) {
                                          context
                                              .read<ServiceCubit>()
                                              .fetchServices();
                                        }
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                            context,
                            'availableAppointments'.tr(),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],

                      if (filteredServices.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Text('noServicesInCategory'.tr()),
                          ),
                        )
                      else
                        ...filteredServices.map(
                          (service) => _ServiceListItem(service: service),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else if (state is ServiceError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 80, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.message),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: Theme.of(context).textTheme.titleLarge?.color,
      ),
    );
  }

  Widget _buildCategorySelector(
    List<String> categories,
    String Function(String) getLabel,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: DropdownButtonFormField<String>(
        initialValue: selectedCategory,
        decoration: InputDecoration(
          labelText: 'category'.tr(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        items: categories.map((category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(getLabel(category)),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() => selectedCategory = val);
          }
        },
      ),
    );
  }
}

class _ServiceListItem extends StatelessWidget {
  final Service service;

  const _ServiceListItem({required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (service.imageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: CachedNetworkImage(
                  imageUrl: service.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.white12),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                    ),
                    Text(
                      '${service.price.toStringAsFixed(2)} TMT',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  service.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildBadge(
                      context,
                      Icons.timer,
                      service.estimatedTime ?? '${service.durationHours}h',
                    ),
                    const SizedBox(width: 12),
                    _buildBadge(context, Icons.category, service.category.tr()),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CreateOrderScreen(preSelectedService: service),
                        ),
                      ).then((value) {
                        if (value == true) {
                          // Refresh services if order was created
                          context.read<ServiceCubit>().fetchServices();
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'bookAppointment'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withAlpha(128),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }
}
