import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/models/order_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supa/services/notification_service.dart';
import 'package:supa/services/cache_service.dart';

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
  final String? tenantId;

  OrderCubit({this.tenantId})
    : supabase = Supabase.instance.client,
      super(OrderInitial());

  // Fetch user's own orders
  Future<void> fetchMyOrders() async {
    // 1. Load from cache first
    final cachedOrders = CacheService.getCachedData<Order>(
      CacheService.ordersBox,
    );
    if (cachedOrders.isNotEmpty) {
      emit(OrdersLoaded(cachedOrders));
    } else {
      emit(OrderLoading());
    }

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (cachedOrders.isEmpty) emit(OrderError('User not authenticated'));
        return;
      }

      final data = await supabase
          .from('orders')
          .select('*, vehicle:vehicles(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<Order> orders = (data as List)
          .map((item) => Order.fromMap(item))
          .toList();

      // 2. Update cache
      await CacheService.cacheData<Order>(CacheService.ordersBox, orders);

      emit(OrdersLoaded(orders));
    } catch (e) {
      // 3. Fallback to cache
      if (CacheService.getCachedData<Order>(CacheService.ordersBox).isEmpty) {
        emit(OrderError('Failed to load orders: ${e.toString()}'));
      }
    }
  }

  // Fetch all orders (for admin)
  Future<void> fetchAllOrders() async {
    emit(OrderLoading());
    try {
      var query = supabase
          .from('orders')
          .select('*, user:profiles(*), vehicle:vehicles(*)');

      if (tenantId != null) {
        query = query.eq('tenant_id', tenantId!);
      }

      final data = await query.order('created_at', ascending: false);

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
    String orderTitle,
    String issueDescription, {
    String? vehicleId,
    DateTime? scheduledAt,
    String? branchName,
    String urgencyLevel = 'Normal',
    String? serviceId,
    String? tenantId,
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
        'car_model': orderTitle,
        'issue_description': issueDescription,
        'status': 'pending',
        'vehicle_id': vehicleId,
        'scheduled_at': scheduledAt?.toIso8601String(),
        'branch_name': branchName,
        'urgency_level': urgencyLevel,
        'service_id': serviceId,
        'tenant_id': tenantId,
      }).select();

      emit(OrderCreated());
      await fetchMyOrders();
    } catch (e) {
      emit(OrderError('Error: ${e.toString()}'));
    }
  }

  // Update order status (admin only)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      if (newStatus == 'completed') {
        final orderData = await supabase
            .from('orders')
            .select('user_id, status')
            .eq('id', orderId)
            .single();
        final userId = orderData['user_id'];
        final currentStatus = orderData['status'];

        if (currentStatus != 'completed') {
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
          .eq('user_id', userId)
          .select();

      if ((response as List).isEmpty) {
        throw Exception(
          'Cannot cancel order. Check permissions or order status.',
        );
      }

      await fetchMyOrders();
    } catch (e) {
      emit(OrderError('Failed to cancel order: ${e.toString()}'));
    }
  }

  // Delete order (user or admin)
  Future<void> deleteOrder(String orderId, {bool isAdmin = false}) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(OrderError('User not authenticated'));
        return;
      }

      // 1. Delete associated reviews first (FK constraint) - ignore if table not available
      try {
        await supabase.from('reviews').delete().eq('order_id', orderId);
      } catch (_) {
        // reviews table may not exist or have no rows - safe to continue
      }

      // 2. Delete the order
      final response = await supabase
          .from('orders')
          .delete()
          .eq('id', orderId)
          .eq(
            isAdmin ? 'id' : 'user_id',
            isAdmin ? orderId : userId,
          ) // Safety for RLS
          .select();

      if ((response as List).isEmpty) {
        throw Exception(
          'В базе данных Supabase не настроена политика RLS для удаления заказов (DELETE). '
          'Пожалуйста, примените SQL скрипт.',
        );
      }

      // 3. Clear cache to force refresh
      await CacheService.clearCache<Order>(CacheService.ordersBox);

      if (isAdmin) {
        await fetchAllOrders();
      } else {
        await fetchMyOrders();
      }
    } catch (e) {
      emit(OrderError('Failed to delete order: ${e.toString()}'));
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
            final newStatus = payload.newRecord['status'];
            final oldStatus = payload.oldRecord['status'];

            if (newStatus != oldStatus) {
              NotificationService().showNotification(
                title: 'Order Update',
                body:
                    'Your order is now: ${newStatus.toString().toUpperCase()}',
              );
            }
            fetchMyOrders();
          },
        )
        .subscribe();
  }

  // Subscribe to all updates (for admin)
  void subscribeToAllOrders() {
    _orderSubscription = supabase
        .channel('admin:orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            if (payload.eventType == PostgresChangeEvent.insert) {
              NotificationService().showNotification(
                title: 'New Order!',
                body:
                    'A new order has been placed for ${payload.newRecord['car_model']}',
              );
            }
            fetchAllOrders();
          },
        )
        .subscribe();
  }

  void clear() {
    emit(OrderInitial());
  }

  @override
  Future<void> close() {
    _orderSubscription?.unsubscribe();
    return super.close();
  }
}
