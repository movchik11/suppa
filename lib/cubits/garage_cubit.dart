import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/models/vehicle_model.dart';
import 'package:supa/models/expense_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

// States
abstract class GarageState {}

class GarageInitial extends GarageState {}

class GarageLoading extends GarageState {}

class VehiclesLoaded extends GarageState {
  final List<Vehicle> vehicles;
  final List<Expense> expenses;
  VehiclesLoaded(this.vehicles, {this.expenses = const []});
}

class VehicleActionSuccess extends GarageState {}

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

      final expenseData = await supabase
          .from('vehicle_expenses')
          .select()
          .eq('profile_id', userId)
          .order('date', ascending: false);

      final List<Expense> expenses = (expenseData as List)
          .map((item) => Expense.fromMap(item))
          .toList();

      emit(VehiclesLoaded(vehicles, expenses: expenses));
    } catch (e) {
      emit(GarageError('Failed to load garage: ${e.toString()}'));
    }
  }

  // Add new vehicle with optional image
  Future<void> addVehicle({
    required String brand,
    required String model,
    int? year,
    String? licensePlate,
    String? color,
    XFile? image,
  }) async {
    emit(GarageLoading());
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(GarageError('User not logged in'));
        return;
      }

      String? imageUrl;
      if (image != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final bytes = await image.readAsBytes();
        await supabase.storage
            .from('vehicle-images')
            .uploadBinary(fileName, bytes);
        imageUrl = supabase.storage
            .from('vehicle-images')
            .getPublicUrl(fileName);
      }

      await supabase.from('vehicles').insert({
        'user_id': userId,
        'brand': brand,
        'model': model,
        'year': year,
        'license_plate': licensePlate,
        'color': color,
        'image_url': imageUrl,
      });

      emit(VehicleActionSuccess());
      await fetchVehicles();
    } catch (e) {
      emit(GarageError('Failed to add vehicle: ${e.toString()}'));
    }
  }

  // Update existing vehicle
  Future<void> updateVehicle({
    required String vehicleId,
    required String brand,
    required String model,
    int? year,
    String? licensePlate,
    String? color,
    XFile? newImage,
    String? existingImageUrl,
    DateTime? lastServiceDate,
    int? nextServiceMileage,
    DateTime? insuranceExpiry,
  }) async {
    emit(GarageLoading());
    try {
      String? imageUrl = existingImageUrl;

      if (newImage != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${newImage.name}';
        final bytes = await newImage.readAsBytes();
        await supabase.storage
            .from('vehicle-images')
            .uploadBinary(fileName, bytes);
        imageUrl = supabase.storage
            .from('vehicle-images')
            .getPublicUrl(fileName);
      }

      await supabase
          .from('vehicles')
          .update({
            'brand': brand,
            'model': model,
            'year': year,
            'license_plate': licensePlate,
            'color': color,
            'image_url': imageUrl,
            if (lastServiceDate != null)
              'last_service_date': lastServiceDate.toIso8601String(),
            if (nextServiceMileage != null)
              'next_service_mileage': nextServiceMileage,
            if (insuranceExpiry != null)
              'insurance_expiry': insuranceExpiry.toIso8601String(),
          })
          .eq('id', vehicleId);

      emit(VehicleActionSuccess());
      await fetchVehicles();
    } catch (e) {
      emit(GarageError('Failed to update vehicle: ${e.toString()}'));
    }
  }

  // Delete vehicle
  // Delete vehicle
  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await supabase.from('vehicles').delete().eq('id', vehicleId);
      await fetchVehicles();
    } catch (e) {
      emit(GarageError('Failed to delete vehicle: ${e.toString()}'));
    }
  }

  Future<void> addExpense({
    required String vehicleId,
    required double amount,
    required String category,
    String? description,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('vehicle_expenses').insert({
        'vehicle_id': vehicleId,
        'profile_id': userId,
        'amount': amount,
        'category': category,
        'description': description,
        'date': DateTime.now().toIso8601String(),
      });

      await fetchVehicles();
    } catch (e) {
      emit(GarageError('Failed to add expense: ${e.toString()}'));
    }
  }
}
