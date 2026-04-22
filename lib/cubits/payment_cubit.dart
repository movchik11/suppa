import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// States
abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentProcessing extends PaymentState {}

class SavedCardsLoaded extends PaymentState {
  final List<Map<String, dynamic>> cards;
  SavedCardsLoaded(this.cards);
}

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

  PaymentCubit()
    : supabase = Supabase.instance.client,
      super(PaymentInitial());

  Future<void> fetchSavedCards() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await supabase
          .from('saved_cards')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      emit(SavedCardsLoaded(List<Map<String, dynamic>>.from(data as List)));
    } catch (e) {
      // Silently fail or emit error if needed
    }
  }

  Future<void> saveCard({
    required String cardNumber,
    required String cardHolder,
    required String expiryDate,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final lastFour = cardNumber.replaceAll(' ', '').substring(12);
      final masked = '**** **** **** $lastFour';

      await supabase.from('saved_cards').insert({
        'user_id': userId,
        'card_number_masked': masked,
        'card_holder': cardHolder,
        'expiry_date': expiryDate,
        'last_four': lastFour,
        'brand': _determineBrand(cardNumber),
      });

      await fetchSavedCards();
    } catch (e) {
      emit(PaymentFailure('Failed to save card: ${e.toString()}'));
    }
  }

  Future<void> deleteCard(String cardId) async {
    try {
      await supabase.from('saved_cards').delete().eq('id', cardId);
      await fetchSavedCards();
    } catch (e) {
      emit(PaymentFailure('Failed to delete card: ${e.toString()}'));
    }
  }

  String _determineBrand(String number) {
    if (number.startsWith('4')) return 'Visa';
    if (number.startsWith('5')) return 'MasterCard';
    return 'Card';
  }

  Future<void> processPayment({
    required double amount,
    required String orderId,
    required String method,
    bool shouldSaveCard = false,
    Map<String, String>? cardData,
  }) async {
    emit(PaymentProcessing());

    try {
      if (shouldSaveCard && cardData != null) {
        await saveCard(
          cardNumber: cardData['number']!,
          cardHolder: cardData['holder']!,
          expiryDate: cardData['expiry']!,
        );
      }

      // Mock network delay
      await Future.delayed(const Duration(seconds: 2));

      // Update order status
      try {
        await supabase
            .from('orders')
            .update({'status': 'pending'}) // Keeping it pending as per request
            .eq('id', orderId);
      } catch (_) {}

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
