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
  String selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final List<String> categories = [
      'all',
      'general',
      'engine',
      'body',
      'diagnostics',
      'tires',
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
                      // --- COMBO PACKS SECTION ---
                      if (selectedCategory == 'all') ...[
                        _buildSectionHeader(context, 'specialComboPacks'.tr()),
                        const SizedBox(height: 12),
                        _buildComboPacks(
                          context,
                          state.services.where((s) => s.isCombo).toList(),
                        ),
                        const SizedBox(height: 24),
                        _buildSectionHeader(context, 'allServices'.tr()),
                        const SizedBox(height: 12),
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
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(getLabel(category)),
              onSelected: (val) {
                setState(() => selectedCategory = category);
              },
              backgroundColor: Theme.of(context).cardColor,
              selectedColor: Colors.blue.withAlpha(51),
              checkmarkColor: Colors.blue,
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue : Theme.of(context).hintColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.blue : Colors.transparent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildComboPacks(BuildContext context, List<Service> combos) {
    if (combos.isEmpty) {
      return Center(child: Text('noPromoPacks'.tr()));
    }
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: combos.length,
        itemBuilder: (context, index) {
          final service = combos[index];
          return _buildComboCard(context, service);
        },
      ),
    );
  }

  Widget _buildComboCard(BuildContext context, Service service) {
    final color = Colors.blue;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CreateOrderScreen(preSelectedService: service),
          ),
        );
      },
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withAlpha(51),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'promoPack'.tr(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              service.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            Text(
              service.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Text(
              '\$${service.price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ],
        ),
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
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: service.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.white12),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            service.rating.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                      '\$${service.price.toStringAsFixed(2)}',
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
                    _buildBadge(context, Icons.category, service.category),
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
                      );
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
