import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/models/service_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supa/services/cache_service.dart';

// States
abstract class ServiceState {}

class ServiceInitial extends ServiceState {}

class ServiceLoading extends ServiceState {}

class ServicesLoaded extends ServiceState {
  final List<Service> services;
  ServicesLoaded(this.services);
}

class ServiceCreated extends ServiceState {}

class ServiceError extends ServiceState {
  final String message;
  ServiceError(this.message);
}

// Cubit
class ServiceCubit extends Cubit<ServiceState> {
  final SupabaseClient supabase;

  ServiceCubit() : supabase = Supabase.instance.client, super(ServiceInitial());

  // Fetch all services
  Future<void> fetchServices() async {
    // 1. Load from cache first
    final cachedServices = CacheService.getCachedData<Service>(
      CacheService.servicesBox,
    );
    if (cachedServices.isNotEmpty) {
      emit(ServicesLoaded(cachedServices));
    } else {
      emit(ServiceLoading());
    }

    try {
      // 2. Fetch from network
      final data = await supabase
          .from('services')
          .select()
          .order('created_at', ascending: false);

      final List<Service> services = (data as List)
          .map((item) => Service.fromMap(item))
          .toList();

      // 3. Update cache
      await CacheService.cacheData<Service>(CacheService.servicesBox, services);

      emit(ServicesLoaded(services));
    } catch (e) {
      // If network fails and we have no cache, show error
      if (CacheService.getCachedData<Service>(
        CacheService.servicesBox,
      ).isEmpty) {
        emit(ServiceError('Failed to load services: ${e.toString()}'));
      }
    }
  }

  // Create new service with optional image
  Future<void> createService({
    required String name,
    required String description,
    required double durationHours,
    required double price,
    required String category,
    String? tenantId,
    XFile? image,
  }) async {
    emit(ServiceLoading());
    try {
      String? imageUrl;

      if (image != null) {
        final sanitizedName = image.name.replaceAll(
          RegExp(r'[^a-zA-Z0-9._-]'),
          '_',
        );
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
        final bytes = await image.readAsBytes();

        await supabase.storage
            .from('service-images')
            .uploadBinary(fileName, bytes);
        imageUrl = supabase.storage
            .from('service-images')
            .getPublicUrl(fileName);
      }

      await supabase.from('services').insert({
        'name': name,
        'description': description,
        'duration_hours': durationHours,
        'price': price,
        'category': category,
        'image_url': imageUrl,
        'tenant_id': tenantId,
      });

      emit(ServiceCreated());
      await fetchServices();
    } catch (e) {
      emit(ServiceError('Failed to create service: ${e.toString()}'));
    }
  }

  Future<void> updateService({
    required String serviceId,
    required String name,
    required String description,
    required double durationHours,
    required double price,
    required String category,
    String? tenantId,
    XFile? newImage,
    String? existingImageUrl,
  }) async {
    try {
      String? imageUrl = existingImageUrl;

      if (newImage != null) {
        final sanitizedName = newImage.name.replaceAll(
          RegExp(r'[^a-zA-Z0-9._-]'),
          '_',
        );
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
        final bytes = await newImage.readAsBytes();

        await supabase.storage
            .from('service-images')
            .uploadBinary(fileName, bytes);
        imageUrl = supabase.storage
            .from('service-images')
            .getPublicUrl(fileName);
      }

      final Map<String, dynamic> updateData = {
        'name': name,
        'description': description,
        'duration_hours': durationHours,
        'price': price,
        'category': category,
        'image_url': imageUrl,
      };

      if (tenantId != null) {
        updateData['tenant_id'] = tenantId;
      }

      await supabase.from('services').update(updateData).eq('id', serviceId);

      await fetchServices();
    } catch (e) {
      emit(ServiceError('Failed to update service: ${e.toString()}'));
    }
  }

  // Delete service
  Future<void> deleteService(String serviceId) async {
    try {
      await supabase.from('services').delete().eq('id', serviceId);
      await fetchServices();
    } catch (e) {
      emit(ServiceError('Failed to delete service: ${e.toString()}'));
    }
  }

  // Sort services
  void sortServices(String sortBy) {
    if (state is! ServicesLoaded) return;

    final currentServices = (state as ServicesLoaded).services;
    final List<Service> sorted = List.from(currentServices);

    if (sortBy == 'price_asc') {
      sorted.sort((a, b) => a.price.compareTo(b.price));
    } else if (sortBy == 'price_desc') {
      sorted.sort((a, b) => b.price.compareTo(a.price));
    } else if (sortBy == 'duration_asc') {
      sorted.sort((a, b) => a.durationHours.compareTo(b.durationHours));
    } else if (sortBy == 'duration_desc') {
      sorted.sort((a, b) => b.durationHours.compareTo(a.durationHours));
    }

    emit(ServicesLoaded(sorted));
  }

  void clear() {
    emit(ServiceInitial());
  }
}
