import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// States
abstract class AdminState {}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminLoaded extends AdminState {
  final List<Profile> profiles;
  AdminLoaded(this.profiles);
}

class AdminError extends AdminState {
  final String message;
  AdminError(this.message);
}

// Cubit
class AdminCubit extends Cubit<AdminState> {
  final SupabaseClient supabase;

  AdminCubit() : supabase = Supabase.instance.client, super(AdminInitial()) {
    fetchProfiles();
  }

  Future<void> fetchProfiles() async {
    emit(AdminLoading());
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      final List<Profile> profiles = (data as List)
          .map((item) => Profile.fromMap(item))
          .toList();

      emit(AdminLoaded(profiles));
    } catch (e) {
      emit(AdminError('Failed to load profiles: ${e.toString()}'));
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await supabase.from('profiles').delete().eq('id', userId);
      // Refresh the list after deletion
      await fetchProfiles();
    } catch (e) {
      emit(AdminError('Failed to delete user: ${e.toString()}'));
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await supabase
          .from('profiles')
          .update({'role': newRole})
          .eq('id', userId);
      // Refresh the list after update
      await fetchProfiles();
    } catch (e) {
      emit(AdminError('Failed to update role: ${e.toString()}'));
    }
  }
}
