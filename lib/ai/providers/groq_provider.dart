import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartstitch/ai/config/ai_config.dart';
import 'ai_provider.dart';

/// Groq (Llama) implementation of [AiProvider].

class GroqProvider implements AiProvider {
  static const _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  @override
  Future<String> sendMessage({
    required String systemPrompt,
    required String userMessage,
    required List<Map<String, String>> history,
  }) async {
    if (AiConfig.groqApiKey.isEmpty) {
      return 'Groq API key is missing. Add GROQ_API_KEY=your_key to '
          'the .env file at your project root, then fully stop and '
          're-run the app (a hot reload/restart is not enough — .env is '
          'bundled at build time).';
    }

    // Build OpenAI-style messages array
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    for (final msg in history) {
      final role = msg['role'] == 'model' ? 'assistant' : 'user';
      final text = msg['text'] ?? '';
      if (text.isEmpty) continue;
      messages.add({'role': role, 'content': text});
    }

    messages.add({'role': 'user', 'content': userMessage});

    int attempts = 0;
    while (attempts <= AiConfig.retryCount) {
      try {
        final response = await http
            .post(
              Uri.parse(_endpoint),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${AiConfig.groqApiKey}',
              },
              body: jsonEncode({
                'model': AiConfig.groqModelName,
                'messages': messages,
                'temperature': AiConfig.temperature,
                'top_p': AiConfig.topP,
                'max_tokens': AiConfig.maxOutputTokens,
              }),
            )
            .timeout(AiConfig.timeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final choices = data['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final content = choices[0]['message']?['content'] as String?;
            if (content != null && content.isNotEmpty) {
              return content.trim();
            }
          }
          return 'I could not generate a response. Please try again.';
        }

        // Non-200: decide whether to retry or return error
        final errMsg = _errorFromStatus(response.statusCode, response.body);
        if (_isRetryable(response.statusCode) && attempts < AiConfig.retryCount) {
          attempts++;
          await Future.delayed(Duration(seconds: attempts));
          continue;
        }
        return errMsg;
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

  bool _isRetryable(int statusCode) {
    return statusCode == 429 || statusCode >= 500;
  }

  String _errorFromStatus(int statusCode, String body) {
    if (statusCode == 401 || statusCode == 403) {
      return 'AI API key is invalid or missing. Check GROQ_API_KEY in '
          'your .env file.';
    }
    if (statusCode == 429) {
      return 'Groq free tier limit reached. Wait a moment and try again.';
    }
    if (statusCode >= 500) {
      return 'Groq service is temporarily unavailable. Please try again.';
    }
    assert(() {
      // ignore: avoid_print
      print('[GroqProvider] HTTP $statusCode: $body');
      return true;
    }());
    return 'Something went wrong. Please try again.';
  }

  String _errorMessage(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('host lookup')) {
      return 'No internet connection. Please check your network.';
    }
    assert(() {
      // ignore: avoid_print
      print('[GroqProvider] Unhandled error: $e');
      return true;
    }());
    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {}
}
