import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:smartstitch/ai/config/ai_config.dart';
import 'ai_provider.dart';

/// Google Gemini implementation of [AiProvider].
class GeminiProvider implements AiProvider {
  GenerativeModel? _model;

  GenerativeModel get _gemini {
    _model ??= GenerativeModel(
      model: AiConfig.modelName,
      apiKey: AiConfig.apiKey,
      generationConfig: AiConfig.generationConfig,
      safetySettings: AiConfig.safetySettings,
    );
    return _model!;
  }

  @override
  Future<String> sendMessage({
    required String systemPrompt,
    required String userMessage,
    required List<Map<String, String>> history,
  }) async {
    // Guard: key not present in .env (see AiConfig.apiKey)
    if (AiConfig.apiKey.isEmpty) {
      return 'Gemini API key is missing. Add GEMINI_API_KEY=your_key to '
          'the .env file at your project root, then fully stop and '
          're-run the app (a hot reload/restart is not enough — .env is '
          'bundled at build time).';
    }

    // Build history as Content objects
    final contents = <Content>[];

    // System prompt injected as first user turn + model ack (Gemini 1.5 pattern)
    contents.add(Content.text('[SYSTEM]\n$systemPrompt'));
    contents.add(Content('model', [TextPart('Understood. I am ready to help.')]));

    // Previous conversation history
    for (final msg in history) {
      final role = msg['role'] ?? 'user';
      final text = msg['text'] ?? '';
      contents.add(Content(role, [TextPart(text)]));
    }

    // Current user message
    contents.add(Content.text(userMessage));

    int attempts = 0;
    while (attempts <= AiConfig.retryCount) {
      try {
        final response = await _gemini
            .generateContent(contents)
            .timeout(AiConfig.timeout);

        final text = response.text;
        if (text != null && text.isNotEmpty) return text.trim();
        return 'I could not generate a response. Please try again.';
      } catch (e) {
        attempts++;
        if (attempts > AiConfig.retryCount) {
          return _errorMessage(e);
        }
        await Future.delayed(Duration(seconds: attempts));
      }
    }
    return 'Service unavailable. Please try again later.';
  }

  String _errorMessage(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (msg.contains('api_key') || msg.contains('api key') ||
        msg.contains('invalid key') || msg.contains('invalid_argument') ||
        msg.contains('api_key_invalid') || msg.contains('permission') ||
        msg.contains('403') || msg.contains('401')) {
      return 'AI API key is invalid or missing. Check GEMINI_API_KEY in '
          'your .env file.';
    }
    if (msg.contains('quota') || msg.contains('rate') ||
        msg.contains('429') || msg.contains('resource_exhausted') ||
        msg.contains('too many')) {
      return 'Gemini free tier limit reached. Wait 1 minute and try again.';
    }
    if (msg.contains('network') || msg.contains('socket') ||
        msg.contains('connection') || msg.contains('host lookup')) {
      return 'No internet connection. Please check your network.';
    }
    if (msg.contains('safety') || msg.contains('blocked') ||
        msg.contains('harm')) {
      return 'Your message was blocked by safety filters. Please rephrase.';
    }
    // Log the raw error in debug for easier diagnosis
    assert(() {
      // ignore: avoid_print
      print('[GeminiProvider] Unhandled error: $e');
      return true;
    }());
    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _model = null;
  }
}