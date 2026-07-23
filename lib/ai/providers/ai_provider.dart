/// Abstract AI provider interface.
/// Swap Gemini for OpenAI/Claude/DeepSeek without changing any UI or service code.
abstract class AiProvider {
  /// Send a message with optional conversation history.
  /// [history] is a list of alternating {role, text} maps: 'user' / 'model'.
  Future<String> sendMessage({
    required String systemPrompt,
    required String userMessage,
    required List<Map<String, String>> history,
  });

  /// Dispose any underlying resources.
  void dispose();
}
