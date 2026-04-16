import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/models/profile_model.dart';
import 'package:supa/models/tenant_model.dart';
import 'package:supa/models/service_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// States
abstract class AdminState {}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminLoaded extends AdminState {
  final List<Profile> profiles;
  final List<Tenant> tenants;
  AdminLoaded(this.profiles, this.tenants);
}

class AdminError extends AdminState {
  final String message;
  AdminError(this.message);
}

// Cubit
class AdminCubit extends Cubit<AdminState> {
  final SupabaseClient supabase;
  final String? tenantId;

  AdminCubit({this.tenantId})
    : supabase = Supabase.instance.client,
      super(AdminInitial()) {
    fetchProfiles();
  }

  Future<void> fetchProfiles() async {
    emit(AdminLoading());
    try {
      var query = supabase.from('profiles').select();

      if (tenantId != null) {
        query = query.eq('tenant_id', tenantId!);
      }

      final profilesData = await query.order('created_at', ascending: false);
      final List<Profile> profiles = (profilesData as List)
          .map((item) => Profile.fromMap(item))
          .toList();

      final List<Tenant> tenants = await fetchTenants();

      emit(AdminLoaded(profiles, tenants));
    } catch (e) {
      emit(AdminError('Failed to load data: ${e.toString()}'));
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .delete()
          .eq('id', userId)
          .select();

      if ((response as List).isEmpty) {
        emit(
          AdminError(
            'Failed to delete user: No matching user found or permission denied',
          ),
        );
        return;
      }

      // Refresh the list after deletion
      await fetchProfiles();
    } catch (e) {
      emit(AdminError('Failed to delete user: ${e.toString()}'));
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      final response = await supabase
          .from('profiles')
          .update({'role': newRole})
          .eq('id', userId)
          .select();

      if ((response as List).isEmpty) {
        emit(
          AdminError(
            'Failed to update role: No matching user found or permission denied',
          ),
        );
        return;
      }

      await fetchProfiles();
    } catch (e) {
      emit(AdminError('Failed to update role: ${e.toString()}'));
    }
  }

  Future<void> updateUserTenant(String userId, String? newTenantId) async {
    try {
      final response = await supabase
          .from('profiles')
          .update({'tenant_id': newTenantId})
          .eq('id', userId)
          .select();

      if ((response as List).isEmpty) {
        emit(
          AdminError(
            'Failed to update tenant: No matching user found or permission denied',
          ),
        );
        return;
      }

      await fetchProfiles();
    } catch (e) {
      emit(AdminError('Failed to update tenant: ${e.toString()}'));
    }
  }

  Future<void> createTenant({
    required String name,
    String? address,
    String? phone,
  }) async {
    try {
      await supabase.from('tenants').insert({
        'name': name,
        'address': address,
        'phone': phone,
      });
      await fetchProfiles();
    } catch (e) {
      emit(AdminError('Failed to create tenant: ${e.toString()}'));
    }
  }

  Future<void> updateTenant({
    required String id,
    required String name,
    String? address,
    String? phone,
  }) async {
    try {
      await supabase
          .from('tenants')
          .update({'name': name, 'address': address, 'phone': phone})
          .eq('id', id);
      await fetchProfiles();
    } catch (e) {
      emit(AdminError('Failed to update tenant: ${e.toString()}'));
    }
  }

  Future<void> deleteTenant(String id) async {
    try {
      await supabase.from('tenants').delete().eq('id', id);
      await fetchProfiles();
    } catch (e) {
      emit(AdminError('Failed to delete tenant: ${e.toString()}'));
    }
  }

  // --- Service Management Per Tenant ---

  Future<List<Service>> fetchServicesForTenant(String tenantId) async {
    try {
      final data = await supabase
          .from('services')
          .select('*, tenants(name)')
          .eq('tenant_id', tenantId);
      return (data as List).map((e) => Service.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addService(Service service) async {
    try {
      await supabase.from('services').insert(service.toMap());
      await fetchProfiles(); // Refresh everything
    } catch (e) {
      emit(AdminError('Failed to add service: ${e.toString()}'));
    }
  }

  Future<void> updateService(Service service) async {
    try {
      await supabase
          .from('services')
          .update(service.toMap())
          .eq('id', service.id);
      await fetchProfiles();
    } catch (e) {
      emit(AdminError('Failed to update service: ${e.toString()}'));
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      await supabase.from('services').delete().eq('id', serviceId);
      await fetchProfiles();
    } catch (e) {
      emit(AdminError('Failed to delete service: ${e.toString()}'));
    }
  }

  Future<List<Tenant>> fetchTenants() async {
    try {
      var query = supabase.from('tenants').select();

      if (tenantId != null) {
        query = query.eq('id', tenantId!);
      }

      final data = await query;
      return (data as List).map((e) => Tenant.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }
}
