import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/models/review_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// States
abstract class ReviewState {}

class ReviewInitial extends ReviewState {}

class ReviewLoading extends ReviewState {}

class ReviewsLoaded extends ReviewState {
  final List<Review> reviews;
  ReviewsLoaded(this.reviews);
}

class ReviewSuccess extends ReviewState {}

class ReviewError extends ReviewState {
  final String message;
  ReviewError(this.message);
}

// Cubit
class ReviewCubit extends Cubit<ReviewState> {
  final SupabaseClient supabase;

  ReviewCubit() : supabase = Supabase.instance.client, super(ReviewInitial());

  Future<void> submitReview({
    String? orderId,
    required String? serviceId,
    required double rating,
    required String comment,
  }) async {
    emit(ReviewLoading());
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(ReviewError('User not authenticated'));
        return;
      }

      final reviewData = {
        'user_id': userId,
        'service_id': serviceId,
        'rating': rating,
        'comment': comment,
      };

      if (orderId != null) {
        reviewData['order_id'] = orderId;
      }

      await supabase.from('reviews').insert(reviewData);

      emit(ReviewSuccess());
    } catch (e) {
      emit(ReviewError('Failed to submit review: ${e.toString()}'));
    }
  }

  Future<void> addReview({
    required String serviceId,
    required String tenantId,
    required int rating,
    required String comment,
  }) async {
    emit(ReviewLoading());
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(ReviewError('User not authenticated'));
        return;
      }

      await supabase.from('reviews').insert({
        'user_id': userId,
        'service_id': serviceId,
        'rating': rating,
        'comment': comment,
      });

      // Automatically refresh the reviews after successful addition
      await fetchReviewsByService(serviceId);
    } catch (e) {
      emit(ReviewError('Failed to add review: ${e.toString()}'));
    }
  }

  Future<void> fetchReviewsByTenant(String tenantId) async {
    emit(ReviewLoading());
    try {
      final servicesData = await supabase
          .from('services')
          .select('id')
          .eq('tenant_id', tenantId);
      
      final serviceIds = (servicesData as List).map((s) => s['id'] as String).toList();
      
      if (serviceIds.isEmpty) {
        emit(ReviewsLoaded([]));
        return;
      }

      final data = await supabase
          .from('reviews')
          .select()
          .inFilter('service_id', serviceIds)
          .order('created_at', ascending: false);

      final List<Review> reviews = (data as List)
          .map((item) => Review.fromMap(item))
          .toList();

      emit(ReviewsLoaded(reviews));
    } catch (e) {
      emit(ReviewError('Failed to load reviews: ${e.toString()}'));
    }
  }

  Future<void> fetchReviewsByService(String serviceId) async {
    emit(ReviewLoading());
    try {
      final data = await supabase
          .from('reviews')
          .select()
          .eq('service_id', serviceId)
          .order('created_at', ascending: false);

      final List<Review> reviews = (data as List)
          .map((item) => Review.fromMap(item))
          .toList();

      emit(ReviewsLoaded(reviews));
    } catch (e) {
      emit(ReviewError('Failed to load reviews: ${e.toString()}'));
    }
  }

  Future<Review?> fetchReviewByOrder(String orderId) async {
    try {
      final data = await supabase
          .from('reviews')
          .select()
          .eq('order_id', orderId)
          .maybeSingle();

      if (data != null) {
        return Review.fromMap(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching review: $e');
      return null;
    }
  }
}
