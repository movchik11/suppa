import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  final GenerativeModel _model;

  GeminiService()
    : _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
      );

  Future<String> getResponse(String prompt, {List<Content>? history}) async {
    final chat = _model.startChat(history: history);
    final content = Content.text(prompt);
    final response = await chat.sendMessage(content);
    return response.text ?? 'No response from AI';
  }

  // Pre-configured prompt for car diagnostics
  String getDiagnosticPrompt(String problem) =>
      "You are a professional car mechanic assistant. A user reports the following problem: '$problem'. "
      "Please provide 3-4 possible causes and suggest which professional service might be needed. "
      "Keep it concise and helpful.";
}
