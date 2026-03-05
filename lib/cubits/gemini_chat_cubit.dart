import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/services/gemini_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

abstract class GeminiState {}

class GeminiInitial extends GeminiState {}

class GeminiLoading extends GeminiState {}

class GeminiSuccess extends GeminiState {
  final List<ChatMessage> messages;
  GeminiSuccess(this.messages);
}

class GeminiError extends GeminiState {
  final String message;
  GeminiError(this.message);
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class GeminiChatCubit extends Cubit<GeminiState> {
  final GeminiService _geminiService;
  final List<ChatMessage> _messages = [];
  final List<Content> _history = [];

  GeminiChatCubit(this._geminiService) : super(GeminiInitial());

  Future<void> sendMessage(String text) async {
    _messages.add(ChatMessage(text: text, isUser: true));
    emit(GeminiSuccess(List.from(_messages)));
    emit(GeminiLoading());

    try {
      final response = await _geminiService.getResponse(
        text,
        history: _history,
      );

      _messages.add(ChatMessage(text: response, isUser: false));
      _history.add(Content.text(text));
      _history.add(Content.model([TextPart(response)]));

      emit(GeminiSuccess(List.from(_messages)));
    } catch (e) {
      emit(GeminiError('Failed to get AI response: ${e.toString()}'));
      // Keep existing messages even on error
      emit(GeminiSuccess(List.from(_messages)));
    }
  }

  void clearChat() {
    _messages.clear();
    _history.clear();
    emit(GeminiInitial());
  }
}
