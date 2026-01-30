import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/models/chat_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  ChatLoaded(this.messages);
}

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
}

class ChatCubit extends Cubit<ChatState> {
  final supabase = Supabase.instance.client;
  final String orderId;
  StreamSubscription? _messagesSubscription;

  ChatCubit(this.orderId) : super(ChatInitial());

  void subscribeToMessages() {
    emit(ChatLoading());
    try {
      // Fetch initial messages
      _messagesSubscription = supabase
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('order_id', orderId)
          .order('created_at', ascending: true)
          .listen((data) {
            final messages = (data as List)
                .map((map) => ChatMessage.fromMap(map))
                .toList();
            emit(ChatLoaded(messages));
          });
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> sendMessage({String? text, XFile? image}) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      String? imageUrl;
      if (image != null) {
        final fileName =
            'chat_${orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final bytes = await image.readAsBytes();
        await supabase.storage
            .from('chat-images')
            .uploadBinary(fileName, bytes);
        imageUrl = supabase.storage.from('chat-images').getPublicUrl(fileName);
      }

      await supabase.from('messages').insert({
        'order_id': orderId,
        'sender_id': userId,
        'text': text,
        'image_url': imageUrl,
      });
    } catch (e) {
      // In a real app, you might want a specific error state for sending
      print('Error sending message: $e');
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
