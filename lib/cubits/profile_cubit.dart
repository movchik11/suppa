import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// States
abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Profile profile;
  ProfileLoaded(this.profile);
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

// Cubit
class ProfileCubit extends Cubit<ProfileState> {
  final SupabaseClient supabase;

  ProfileCubit() : supabase = Supabase.instance.client, super(ProfileInitial());

  Future<void> fetchProfile() async {
    emit(ProfileLoading());
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(ProfileError('User not authenticated'));
        return;
      }

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      emit(ProfileLoaded(Profile.fromMap(data)));
    } catch (e) {
      emit(ProfileError('Failed to fetch profile: ${e.toString()}'));
    }
  }

  Future<void> updateProfile({String? displayName, String? phoneNumber}) async {
    emit(ProfileLoading());
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase
          .from('profiles')
          .update({'display_name': displayName, 'phone_number': phoneNumber})
          .eq('id', userId);

      await fetchProfile();
    } catch (e) {
      emit(ProfileError('Failed to update profile: ${e.toString()}'));
    }
  }
}
