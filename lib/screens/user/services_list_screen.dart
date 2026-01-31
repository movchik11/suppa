import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:supa/cubits/service_cubit.dart';
import 'package:supa/models/service_model.dart';
import 'package:easy_localization/easy_localization.dart';

class ServicesListScreen extends StatelessWidget {
  const ServicesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ServiceCubit()..fetchServices(),
      child: Scaffold(
        appBar: AppBar(title: Text('ourServices'.tr())),
        body: BlocBuilder<ServiceCubit, ServiceState>(
          builder: (context, state) {
            if (state is ServiceLoading) {
              return Center(
                child: Lottie.asset(
                  'assets/animations/loading.json',
                  height: 200,
                  errorBuilder: (context, error, stackTrace) =>
                      const CircularProgressIndicator(),
                ),
              );
            } else if (state is ServicesLoaded) {
              if (state.services.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.construction, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('noServices'.tr()),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => context.read<ServiceCubit>().fetchServices(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.services.length,
                  itemBuilder: (context, index) {
                    final service = state.services[index];
                    return _ServiceListItem(service: service);
                  },
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
    );
  }
}

class _ServiceListItem extends StatelessWidget {
  final Service service;

  const _ServiceListItem({required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          if (service.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                service.imageUrl!,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: const Icon(Icons.car_repair, size: 60),
                ),
              ),
            ),
          // Details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  service.description,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 18,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'hoursArg'.tr(
                            args: [service.durationHours.toString()],
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    Text(
                      '\$${service.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
