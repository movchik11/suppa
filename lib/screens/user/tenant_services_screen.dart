import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/service_cubit.dart';
import 'package:supa/models/service_model.dart';
import 'package:supa/models/tenant_model.dart';
import 'package:supa/screens/user/create_order_screen.dart';
import 'package:supa/cubits/review_cubit.dart';
import 'package:supa/components/app_loading_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lottie/lottie.dart';
import 'package:supa/components/ui/bouncy_button.dart';

class TenantServicesScreen extends StatefulWidget {
  final Tenant tenant;

  const TenantServicesScreen({super.key, required this.tenant});

  @override
  State<TenantServicesScreen> createState() => _TenantServicesScreenState();
}

class _TenantServicesScreenState extends State<TenantServicesScreen> {
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

    return BlocProvider(
      create: (context) => ServiceCubit(tenantId: widget.tenant.id)..fetchServices(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.tenant.name),
        ),
        body: Column(
          children: [
            // Center Details Header
            if (widget.tenant.phone != null || widget.tenant.address != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Theme.of(context).cardColor,
                child: Row(
                  children: [
                    if (widget.tenant.phone != null) ...[
                      const Icon(Icons.phone, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(widget.tenant.phone!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                    ],
                    if (widget.tenant.address != null) ...[
                      const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.tenant.address!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Category Selector
            _buildCategorySelector(categories, getCategoryLabel),

            Expanded(
              child: BlocBuilder<ServiceCubit, ServiceState>(
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

                    return RefreshIndicator(
                      onRefresh: () => context.read<ServiceCubit>().fetchServices(),
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        children: [
                          if (selectedCategory == 'all') ...[
                            _buildSectionHeader(context, 'allServices'.tr()),
                            const SizedBox(height: 12),
                          ] else ...[
                            if (_subServices[selectedCategory] != null) ...[
                              _buildSectionHeader(context, 'ourServices'.tr()),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 44,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _subServices[selectedCategory]!.length,
                                  itemBuilder: (context, index) {
                                    final sKey = _subServices[selectedCategory]![index];
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
                                              builder: (context) => CreateOrderScreen(
                                                suggestedServiceTitle: sKey.tr(),
                                              ),
                                            ),
                                          ).then((value) {
                                            if (value == true && context.mounted) {
                                              context.read<ServiceCubit>().fetchServices();
                                            }
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildSectionHeader(context, 'availableAppointments'.tr()),
                              const SizedBox(height: 12),
                            ],
                          ],

                          if (filteredServices.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 40),
                                child: Column(
                                  children: [
                                    Lottie.asset(
                                      'assets/animations/car_repair.json',
                                      height: 150,
                                      repeat: true,
                                    ),
                                    const SizedBox(height: 16),
                                    Text('noServicesInCategory'.tr()),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...filteredServices.map((service) => _ServiceListItem(service: service)),
                        ],
                      ),
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
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildCategorySelector(List<String> categories, String Function(String) getLabel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: DropdownButtonFormField<String>(
        initialValue: selectedCategory,
        decoration: InputDecoration(
          labelText: 'category'.tr(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    void navigateToBooking() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateOrderScreen(preSelectedService: service),
        ),
      ).then((value) {
        if (value == true && context.mounted) {
          context.read<ServiceCubit>().fetchServices();
        }
      });
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: BouncyButton(
        onPressed: navigateToBooking,
        child: InkWell(
          onTap: navigateToBooking,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (service.imageUrl != null)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Hero(
                    tag: 'service_image_${service.id}',
                    child: CachedNetworkImage(
                      imageUrl: service.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.white12),
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
                        if (service.estimatedTime != null) ...[
                          _buildBadge(context, Icons.timer, service.estimatedTime!),
                          const SizedBox(width: 12),
                        ],
                        _buildBadge(context, Icons.category, service.category.tr()),
                        if (service.tenantName != null) ...[
                          const SizedBox(width: 12),
                          _buildBadge(context, Icons.business, service.tenantName!),
                        ],
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _showReviewsBottomSheet(context, service),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.withAlpha(100)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, size: 14, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  'reviews'.tr().isEmpty ? 'Reviews' : 'reviews'.tr(),
                                  style: const TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: BouncyButton(
                        onPressed: navigateToBooking,
                        child: ElevatedButton(
                          onPressed: navigateToBooking,
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

  void _showReviewsBottomSheet(BuildContext context, Service service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return BlocProvider(
          create: (context) => ReviewCubit()..fetchReviewsByService(service.id),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'reviewsLabel'.tr().isEmpty ? 'Reviews for ${service.name}' : 'reviewsLabel'.tr(args: [service.name]),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: BlocBuilder<ReviewCubit, ReviewState>(
                    builder: (context, state) {
                      if (state is ReviewLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is ReviewsLoaded) {
                        if (state.reviews.isEmpty) {
                          return Center(
                            child: Text(
                              'noReviewsYet'.tr().isEmpty ? 'No reviews yet' : 'noReviewsYet'.tr()
                            ),
                          );
                        }
                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: state.reviews.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final review = state.reviews[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.withAlpha(30),
                                child: const Icon(Icons.person, color: Colors.blue),
                              ),
                              title: Row(
                                children: [
                                  ...List.generate(5, (i) => Icon(
                                    i < review.rating ? Icons.star : Icons.star_border,
                                    size: 16,
                                    color: Colors.amber,
                                  )),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(review.comment),
                              ),
                              trailing: Text(
                                DateFormat('dd.MM.yyyy').format(review.createdAt),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            );
                          },
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
