import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// States
abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentProcessing extends PaymentState {}

class PaymentSuccess extends PaymentState {
  final String transactionId;
  PaymentSuccess(this.transactionId);
}

class PaymentFailure extends PaymentState {
  final String error;
  PaymentFailure(this.error);
}

// Cubit
class PaymentCubit extends Cubit<PaymentState> {
  final SupabaseClient supabase;

  PaymentCubit() : supabase = Supabase.instance.client, super(PaymentInitial());

  Future<void> processPayment({
    required double amount,
    required String orderId,
    required String method,
  }) async {
    emit(PaymentProcessing());

    try {
      // Mock network delay
      await Future.delayed(const Duration(seconds: 3));

      // 5% chance of mock failure
      // if (DateTime.now().second % 20 == 0) {
      //   emit(PaymentFailure('Mock payment failed. Please try again.'));
      //   return;
      // }

      // Update order payment status in Supabase (optional, but good for demo)
      try {
        await supabase
            .from('orders')
            .update({'status': 'paid'})
            .eq('id', orderId);
      } catch (_) {
        // If 'paid' status doesn't exist or table update fails, ignore for mock
      }

      final transactionId = 'TXN-${DateTime.now().millisecondsSinceEpoch}';
      emit(PaymentSuccess(transactionId));
    } catch (e) {
      emit(PaymentFailure('An error occurred during payment: ${e.toString()}'));
    }
  }

  void reset() {
    emit(PaymentInitial());
  }
}
