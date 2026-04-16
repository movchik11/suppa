import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supa/models/tenant_model.dart';
import 'package:supa/services/cache_service.dart';

abstract class TenantState {}

class TenantInitial extends TenantState {}

class TenantLoading extends TenantState {}

class TenantLoaded extends TenantState {
  final List<Tenant> tenants;
  TenantLoaded(this.tenants);
}

class TenantError extends TenantState {
  final String message;
  TenantError(this.message);
}

class TenantCubit extends Cubit<TenantState> {
  final SupabaseClient supabase;

  TenantCubit() : supabase = Supabase.instance.client, super(TenantInitial());

  Future<void> fetchTenants() async {
    emit(TenantLoading());
    try {
      final data = await supabase.from('tenants').select().order('name');
      final List<Tenant> tenants = (data as List)
          .map((item) => Tenant.fromMap(item))
          .toList();
      emit(TenantLoaded(tenants));
    } catch (e) {
      emit(TenantError('Failed to load centers: ${e.toString()}'));
    }
  }
}
