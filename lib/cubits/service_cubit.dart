import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/models/service_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

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
    emit(ServiceLoading());
    try {
      final data = await supabase
          .from('services')
          .select()
          .order('created_at', ascending: false);

      final List<Service> services = (data as List)
          .map((item) => Service.fromMap(item))
          .toList();

      emit(ServicesLoaded(services));
    } catch (e) {
      emit(ServiceError('Failed to load services: ${e.toString()}'));
    }
  }

  // Create new service with optional image
  Future<void> createService({
    required String name,
    required String description,
    required double durationHours,
    required double price,
    XFile? image,
  }) async {
    emit(ServiceLoading());
    try {
      String? imageUrl;

      // Upload image if provided
      if (image != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final bytes = await image.readAsBytes();

        await supabase.storage
            .from('service-images')
            .uploadBinary(fileName, bytes);

        // Get public URL
        imageUrl = supabase.storage
            .from('service-images')
            .getPublicUrl(fileName);
      }

      // Insert service
      await supabase.from('services').insert({
        'name': name,
        'description': description,
        'duration_hours': durationHours,
        'price': price,
        'image_url': imageUrl,
      });

      emit(ServiceCreated());
      await fetchServices(); // Refresh list
    } catch (e) {
      emit(ServiceError('Failed to create service: ${e.toString()}'));
    }
  }

  // Update service
  Future<void> updateService({
    required String serviceId,
    required String name,
    required String description,
    required double durationHours,
    required double price,
    XFile? newImage,
    String? existingImageUrl,
  }) async {
    try {
      String? imageUrl = existingImageUrl;

      // Upload new image if provided
      if (newImage != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${newImage.name}';
        final bytes = await newImage.readAsBytes();

        await supabase.storage
            .from('service-images')
            .uploadBinary(fileName, bytes);
        imageUrl = supabase.storage
            .from('service-images')
            .getPublicUrl(fileName);
      }

      await supabase
          .from('services')
          .update({
            'name': name,
            'description': description,
            'duration_hours': durationHours,
            'price': price,
            'imageUrl': imageUrl,
          })
          .eq('id', serviceId);

      await fetchServices(); // Refresh list
    } catch (e) {
      emit(ServiceError('Failed to update service: ${e.toString()}'));
    }
  }

  // Delete service
  Future<void> deleteService(String serviceId) async {
    try {
      await supabase.from('services').delete().eq('id', serviceId);
      await fetchServices(); // Refresh list
    } catch (e) {
      emit(ServiceError('Failed to delete service: ${e.toString()}'));
    }
  }
}
