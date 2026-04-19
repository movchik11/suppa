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

                          const SizedBox(height: 100),
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

class _ServiceListItem extends StatefulWidget {
  final Service service;

  const _ServiceListItem({required this.service});

  @override
  State<_ServiceListItem> createState() => _ServiceListItemState();
}

class _ServiceListItemState extends State<_ServiceListItem> {
  bool _isReviewsExpanded = false;
  final _commentController = TextEditingController();
  int _selectedRating = 5;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void navigateToBooking() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateOrderScreen(preSelectedService: widget.service),
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
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Theme.of(context).dividerColor.withAlpha(50)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.service.imageUrl != null)
            AspectRatio(
              aspectRatio: 21 / 9,
              child: Hero(
                tag: 'service_image_${widget.service.id}',
                child: CachedNetworkImage(
                  imageUrl: widget.service.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.black12),
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
                        widget.service.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    Text(
                      '${widget.service.price.toStringAsFixed(2)} TMT',
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
                  widget.service.description,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (widget.service.durationHours > 0)
                      _buildChip(context, Icons.timer_outlined, '${widget.service.durationHours} h'),
                    const SizedBox(width: 8),
                    _buildChip(context, Icons.category_outlined, widget.service.category.tr()),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() => _isReviewsExpanded = !_isReviewsExpanded);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isReviewsExpanded ? Colors.amber : Colors.amber.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 16, color: _isReviewsExpanded ? Colors.white : Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '5.0',
                              style: TextStyle(
                                fontSize: 13,
                                color: _isReviewsExpanded ? Colors.white : Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              _isReviewsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              size: 16,
                              color: _isReviewsExpanded ? Colors.white : Colors.amber,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Expandable Reviews Section
                if (_isReviewsExpanded) _buildReviewsSection(context),
                
                const SizedBox(height: 20),
                BouncyButton(
                  onPressed: navigateToBooking,
                  child: ElevatedButton(
                    onPressed: navigateToBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text('bookAppointment'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).hintColor),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    return BlocProvider(
      create: (context) => ReviewCubit()..fetchReviewsByService(widget.service.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 32),
          Text('leaveReview'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StatefulBuilder(
            builder: (context, setReviewState) => Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) => IconButton(
                    icon: Icon(index < _selectedRating ? Icons.star : Icons.star_border, color: Colors.amber, size: 28),
                    onPressed: () => setReviewState(() => _selectedRating = index + 1),
                  )),
                ),
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'writeReviewHint'.tr(),
                    filled: true,
                    fillColor: Theme.of(context).dividerColor.withAlpha(10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                BlocBuilder<ReviewCubit, ReviewState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: (state is ReviewLoading)
                          ? null
                          : () async {
                              if (_commentController.text.trim().isEmpty) {
                                return;
                              }
                              await context.read<ReviewCubit>().addReview(
                                    serviceId: widget.service.id,
                                    tenantId: widget.service.tenantId ?? '',
                                    rating: _selectedRating,
                                    comment: _commentController.text.trim(),
                                  );
                              _commentController.clear();
                              setReviewState(() => _selectedRating = 5);
                              if (context.mounted) {
                                context
                                    .read<ReviewCubit>()
                                    .fetchReviewsByService(widget.service.id);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: state is ReviewLoading 
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text('submitReview'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          BlocBuilder<ReviewCubit, ReviewState>(
            builder: (context, state) {
              if (state is ReviewLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (state is ReviewsLoaded) {
                if (state.reviews.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'noReviewsYet'.tr(),
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.reviews.length,
                  itemBuilder: (context, index) {
                    final r = state.reviews[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor.withAlpha(10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Row(children: List.generate(5, (i) => Icon(i < r.rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 14))),
                              const Spacer(),
                              Text(DateFormat('dd.MM.yyyy').format(r.createdAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(r.comment, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    );
                  },
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }
}
