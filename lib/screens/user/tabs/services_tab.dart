import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:supa/cubits/service_cubit.dart';
import 'package:supa/models/service_model.dart';
import 'package:supa/screens/user/create_order_screen.dart';
import 'package:supa/components/app_loading_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ServicesTab extends StatefulWidget {
  const ServicesTab({super.key});

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  String selectedCategory = 'All';
  final List<String> categories = [
    'All',
    'General',
    'Engine',
    'Body',
    'Diagnostics',
    'Tires',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceCubit, ServiceState>(
      builder: (context, state) {
        if (state is ServiceLoading) {
          return const AppLoadingIndicator();
        } else if (state is ServicesLoaded) {
          final filteredServices = selectedCategory == 'All'
              ? state.services
              : state.services
                    .where((s) => s.category == selectedCategory)
                    .toList();

          return Column(
            children: [
              // --- CATEGORY SELECTOR ---
              _buildCategorySelector(),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<ServiceCubit>().fetchServices(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // --- COMBO PACKS SECTION ---
                      if (selectedCategory == 'All') ...[
                        _buildSectionHeader('Special Combo Packs'),
                        const SizedBox(height: 12),
                        _buildComboPacks(),
                        const SizedBox(height: 24),
                        _buildSectionHeader('All Services'),
                        const SizedBox(height: 12),
                      ],

                      if (filteredServices.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Text('No services in this category'),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCategorySelector() {
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
              label: Text(category),
              onSelected: (val) {
                setState(() => selectedCategory = category);
              },
              backgroundColor: Colors.white12,
              selectedColor: Colors.blue.withAlpha(51),
              checkmarkColor: Colors.blue,
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildComboPacks() {
    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildComboCard(
            'Full Maintenance',
            'Oil + Filters + Check',
            '89.99',
            const Color(0xFF673AB7),
          ),
          _buildComboCard(
            'Winter Ready',
            'Tires + Battery + Fluids',
            '120.00',
            const Color(0xFF1E88E5),
          ),
        ],
      ),
    );
  }

  Widget _buildComboCard(String title, String desc, String price, Color color) {
    return Container(
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
            child: const Text(
              'SAVE 20%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            desc,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const Spacer(),
          Text(
            '\$$price',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
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
      color: Colors.white.withAlpha(13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.white12),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
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
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildBadge(
                      Icons.timer,
                      service.estimatedTime ?? '${service.durationHours}h',
                    ),
                    const SizedBox(width: 12),
                    _buildBadge(Icons.category, service.category),
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
                    child: const Text(
                      'Book Appointment',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
