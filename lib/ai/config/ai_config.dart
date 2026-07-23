import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Central AI configuration.
class AiConfig {
  AiConfig._();

  // =========================
  // Gemini (Backward Compatibility)
  // =========================

  static String get apiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? '';

  static const String modelName = 'gemini-1.5-flash';

  // =========================
  // Groq
  // =========================

  static String get groqApiKey =>
      dotenv.env['GROQ_API_KEY'] ?? '';

  static const String groqModelName = 'llama-3.3-70b-versatile';

  // =========================
  // AI Parameters
  // =========================

  static const double temperature = 0.7;
  static const double topP = 0.95;
  static const int maxOutputTokens = 1024;
  static const int historySize = 20;

  // =========================
  // Retry / Timeout
  // =========================

  static const int retryCount = 2;
  static const Duration timeout = Duration(seconds: 30);

  // =========================
  // Cache
  // =========================

  // TEMP DEBUG: shortened from 30 minutes so a stale empty context
  // (from a failed first fetch) doesn't hide the fix while testing.
  // Put this back to 30 minutes once context is confirmed working.
  static const Duration cacheExpiry = Duration(seconds: 15);

  // =========================
  // Gemini Safety
  // =========================

  static List<SafetySetting> get safetySettings => [
        SafetySetting(
          HarmCategory.harassment,
          HarmBlockThreshold.medium,
        ),
        SafetySetting(
          HarmCategory.hateSpeech,
          HarmBlockThreshold.medium,
        ),
        SafetySetting(
          HarmCategory.sexuallyExplicit,
          HarmBlockThreshold.medium,
        ),
        SafetySetting(
          HarmCategory.dangerousContent,
          HarmBlockThreshold.medium,
        ),
      ];

  static GenerationConfig get generationConfig => GenerationConfig(
        temperature: temperature,
        topP: topP,
        maxOutputTokens: maxOutputTokens,
      );
}