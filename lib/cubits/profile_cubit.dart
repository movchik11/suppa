import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supa/services/cache_service.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';

// States
abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Profile profile;
  ProfileLoaded(this.profile);
}

class ProfileActionSuccess extends ProfileState {}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

// Cubit
class ProfileCubit extends Cubit<ProfileState> {
  final SupabaseClient supabase;

  ProfileCubit() : supabase = Supabase.instance.client, super(ProfileInitial());

  Future<Uint8List> _compressImage(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length < 200 * 1024) return bytes; // Avatars can be smaller

    final result = await FlutterImageCompress.compressWithList(
      bytes,
      minHeight: 512,
      minWidth: 512,
      quality: 80,
    );
    return result;
  }

  Future<void> fetchProfile() async {
    // 1. Load from cache first
    final cachedProfile = CacheService.getCachedProfile();
    if (cachedProfile != null) {
      emit(ProfileLoaded(cachedProfile));
    } else {
      emit(ProfileLoading());
    }

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (cachedProfile == null) emit(ProfileError('User not authenticated'));
        return;
      }

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
        emit(ProfileError('profileNotFound'.tr()));
        return;
      }

      final profile = Profile.fromMap(data);

      // 2. Update cache
      await CacheService.cacheProfile(profile);

      emit(ProfileLoaded(profile));
    } catch (e) {
      if (CacheService.getCachedProfile() == null) {
        emit(ProfileError('Failed to fetch profile: ${e.toString()}'));
      }
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? phoneNumber,
    XFile? avatar,
    String? existingAvatarUrl,
    int? loyaltyPoints,
    String? preferredContact,
    bool? notificationsEnabled,
    bool? isLightMode,
  }) async {
    emit(ProfileLoading());
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      String? avatarUrl = existingAvatarUrl;

      if (avatar != null) {
        final fileName =
            'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final bytes = await _compressImage(avatar);
        await supabase.storage.from('avatars').uploadBinary(fileName, bytes);
        avatarUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      final updates = {
        if (displayName != null) 'display_name': displayName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (loyaltyPoints != null) 'loyalty_points': loyaltyPoints,
        if (preferredContact != null) 'preferred_contact': preferredContact,
        if (notificationsEnabled != null)
          'notifications_enabled': notificationsEnabled,
        if (isLightMode != null) 'is_light_mode': isLightMode,
      };

      await supabase.from('profiles').update(updates).eq('id', userId);

      emit(ProfileActionSuccess());
      await fetchProfile();
    } catch (e) {
      emit(ProfileError('Failed to update profile: ${e.toString()}'));
    }
  }

  void clear() {
    emit(ProfileInitial());
  }
}
