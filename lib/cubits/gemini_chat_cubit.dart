import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive/hive.dart';
import 'package:supa/services/cache_service.dart';
import 'package:supa/services/gemini_service.dart';

part 'gemini_chat_cubit.g.dart';

abstract class GeminiState {}

class GeminiInitial extends GeminiState {}

class GeminiLoading extends GeminiState {}

class GeminiSuccess extends GeminiState {
  final List<ChatMessage> messages;
  GeminiSuccess(this.messages);
}

class GeminiError extends GeminiState {
  final String message;
  final List<ChatMessage> messages;
  GeminiError(this.message, this.messages);
}

@HiveType(typeId: 4)
class ChatMessage {
  @HiveField(0)
  final String text;
  @HiveField(1)
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class GeminiChatCubit extends Cubit<GeminiState> {
  final GeminiService _geminiService;
  final List<ChatMessage> _messages = [];
  final List<Content> _history = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  GeminiChatCubit(this._geminiService) : super(GeminiInitial()) {
    _loadChatHistory();
  }

  void _loadChatHistory() {
    final cached = CacheService.getCachedData<ChatMessage>(
      CacheService.chatBox,
    );
    if (cached.isNotEmpty) {
      _messages.addAll(cached);
      for (var msg in cached) {
        if (msg.isUser) {
          _history.add(Content.text(msg.text));
        } else {
          _history.add(Content.model([TextPart(msg.text)]));
        }
      }
      emit(GeminiSuccess(List.from(_messages)));
    }
  }

  Future<void> _saveChatHistory() async {
    await CacheService.cacheData<ChatMessage>(CacheService.chatBox, _messages);
  }

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

      await _saveChatHistory();
      emit(GeminiSuccess(List.from(_messages)));
    } catch (e) {
      print('DEBUG: GeminiChatCubit Error: $e');
      emit(
        GeminiError(
          'Failed to get AI response: ${e.toString()}',
          List.from(_messages),
        ),
      );
    }
  }

  void clearChat() {
    _messages.clear();
    _history.clear();
    CacheService.clearCache<ChatMessage>(CacheService.chatBox);
    emit(GeminiInitial());
  }
}
