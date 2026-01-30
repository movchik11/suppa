import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/models/vehicle_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// States
abstract class GarageState {}

class GarageInitial extends GarageState {}

class GarageLoading extends GarageState {}

class VehiclesLoaded extends GarageState {
  final List<Vehicle> vehicles;
  VehiclesLoaded(this.vehicles);
}

class VehicleAdded extends GarageState {}

class GarageError extends GarageState {
  final String message;
  GarageError(this.message);
}

// Cubit
class GarageCubit extends Cubit<GarageState> {
  final SupabaseClient supabase;

  GarageCubit() : supabase = Supabase.instance.client, super(GarageInitial());

  // Fetch user's vehicles
  Future<void> fetchVehicles() async {
    emit(GarageLoading());
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(GarageError('User not logged in'));
        return;
      }

      final data = await supabase
          .from('vehicles')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<Vehicle> vehicles = (data as List)
          .map((item) => Vehicle.fromMap(item))
          .toList();

      emit(VehiclesLoaded(vehicles));
    } catch (e) {
      emit(GarageError('Failed to load garage: ${e.toString()}'));
    }
  }

  // Add new vehicle
  Future<void> addVehicle({
    required String brand,
    required String model,
    int? year,
    String? licensePlate,
    String? color,
  }) async {
    emit(GarageLoading());
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(GarageError('User not logged in'));
        return;
      }

      await supabase.from('vehicles').insert({
        'user_id': userId,
        'brand': brand,
        'model': model,
        'year': year,
        'license_plate': licensePlate,
        'color': color,
      });

      emit(VehicleAdded());
      await fetchVehicles(); // Refresh list
    } catch (e) {
      emit(GarageError('Failed to add vehicle: ${e.toString()}'));
    }
  }

  // Delete vehicle
  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await supabase.from('vehicles').delete().eq('id', vehicleId);
      await fetchVehicles(); // Refresh list
    } catch (e) {
      emit(GarageError('Failed to delete vehicle: ${e.toString()}'));
    }
  }
}
