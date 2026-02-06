import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/models/order_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// States
abstract class OrderState {}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrdersLoaded extends OrderState {
  final List<Order> orders;
  OrdersLoaded(this.orders);
}

class OrderCreated extends OrderState {}

class OrderError extends OrderState {
  final String message;
  OrderError(this.message);
}

// Cubit
class OrderCubit extends Cubit<OrderState> {
  final SupabaseClient supabase;

  OrderCubit() : supabase = Supabase.instance.client, super(OrderInitial());

  // Fetch user's own orders
  Future<void> fetchMyOrders() async {
    emit(OrderLoading());
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(OrderError('User not authenticated'));
        return;
      }

      final data = await supabase
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<Order> orders = (data as List)
          .map((item) => Order.fromMap(item))
          .toList();

      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(OrderError('Failed to load orders: ${e.toString()}'));
    }
  }

  // Fetch all orders (for admin)
  Future<void> fetchAllOrders() async {
    emit(OrderLoading());
    try {
      final data = await supabase
          .from('orders')
          .select()
          .order('created_at', ascending: false);

      final List<Order> orders = (data as List)
          .map((item) => Order.fromMap(item))
          .toList();

      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(OrderError('Failed to load orders: ${e.toString()}'));
    }
  }

  // Create new order
  Future<void> createOrder(
    String carModel,
    String issueDescription, {
    String? vehicleId,
    DateTime? scheduledAt,
    String? branchName,
    String urgencyLevel = 'Normal',
  }) async {
    emit(OrderLoading());
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(OrderError('User not authenticated'));
        return;
      }

      await supabase.from('orders').insert({
        'user_id': userId,
        'car_model': carModel,
        'issue_description': issueDescription,
        'status': 'pending',
        'vehicle_id': vehicleId,
        'scheduled_at': scheduledAt?.toIso8601String(),
        'branch_name': branchName,
        'urgency_level': urgencyLevel,
      });

      emit(OrderCreated());
    } on PostgrestException catch (e) {
      emit(OrderError('Database error: ${e.message} (${e.code})'));
    } catch (e) {
      if (e.toString().contains('Failed to fetch')) {
        emit(
          OrderError(
            'Network error: Failed to connect to server. Please check your connection or CORS settings.',
          ),
        );
      } else {
        emit(OrderError('Unexpected error: ${e.toString()}'));
      }
    }
  }

  // Update order status (admin only)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      // Get the order to find the user_id if we are completing it
      if (newStatus == 'completed') {
        final orderData = await supabase
            .from('orders')
            .select('user_id, status')
            .eq('id', orderId)
            .single();

        final userId = orderData['user_id'];
        final currentStatus = orderData['status'];

        // Only award points if move from non-completed to completed
        if (currentStatus != 'completed') {
          // Increment loyalty points in profiles table
          // Note: In a production app, this should be a transaction or RPC
          final profileData = await supabase
              .from('profiles')
              .select('loyalty_points')
              .eq('id', userId)
              .single();

          int currentPoints = profileData['loyalty_points'] ?? 0;
          await supabase
              .from('profiles')
              .update({'loyalty_points': currentPoints + 100})
              .eq('id', userId);
        }
      }

      await supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);

      // Refresh the list
      await fetchAllOrders();
      await fetchAllOrders();
    } catch (e) {
      emit(OrderError('Failed to update status: ${e.toString()}'));
    }
  }

  // Cancel order (user)
  Future<void> cancelOrder(String orderId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(OrderError('User not authenticated'));
        return;
      }

      final response = await supabase
          .from('orders')
          .update({'status': 'cancelled'})
          .eq('id', orderId)
          .eq('user_id', userId) // Enforce ownership for RLS
          .select();

      if ((response as List).isEmpty) {
        throw Exception(
          'Cannot cancel order. Check permissions or order status.',
        );
      }

      // Refresh to show updated status
      await fetchMyOrders();
    } catch (e) {
      emit(OrderError('Failed to cancel order: ${e.toString()}'));
    }
  }

  RealtimeChannel? _orderSubscription;

  // Subscribe to realtime updates for own orders
  void subscribeToOrders() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    _orderSubscription = supabase
        .channel('public:orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            fetchMyOrders();
          },
        )
        .subscribe();
  }

  @override
  Future<void> close() {
    _orderSubscription?.unsubscribe();
    return super.close();
  }
}
