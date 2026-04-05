import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  final GenerativeModel _model;

  GeminiService()
    : _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
        systemInstruction: Content.system(
          "You are a professional automotive mechanic assistant. "
          "You speak Turkmen, Russian, and English. Always respond in the SAME language the user uses. "
          "If the user speaks Turkmen, respond in professional Turkmen. "
          "If the user speaks Russian, respond in professional Russian. "
          "Provide empathetic, concise, and technically accurate car repair advice. "
          "Suggest visiting a professional mechanic if the issue seems safety-critical.",
        ),
      );

  Future<String> getResponse(String prompt, {List<Content>? history}) async {
    try {
      print('DEBUG: Sending prompt to Gemini: $prompt');
      print('DEBUG: History count: ${history?.length ?? 0}');

      if (dotenv.env['GEMINI_API_KEY'] == null ||
          dotenv.env['GEMINI_API_KEY']!.isEmpty) {
        throw Exception('GEMINI_API_KEY is missing in .env file');
      }

      final chat = _model.startChat(history: history);
      final content = Content.text(prompt);
      final response = await chat.sendMessage(content);

      print(
        'DEBUG: Received response from Gemini: ${response.text?.substring(0, 20)}...',
      );
      return response.text ?? 'No response from AI';
    } catch (e) {
      print('DEBUG: GeminiService Error: $e');
      rethrow;
    }
  }

  // Pre-configured prompt for car diagnostics
  String getDiagnosticPrompt(String problem) =>
      "User reports: '$problem'. Analyze this and suggest 3-4 possible causes in a structured way. "
      "Identify if this is an urgent safety issue. Suggest relevant services.";
}
