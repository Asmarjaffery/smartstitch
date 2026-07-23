import 'package:speech_to_text/speech_to_text.dart';
import 'package:get/get.dart';

class VoiceService {
  static final VoiceService instance = VoiceService._internal();
  factory VoiceService() => instance;
  VoiceService._internal();

  final SpeechToText _speech = SpeechToText();

  final RxBool isListening = false.obs;
  final RxBool isAvailable = false.obs;
  final RxString recognizedText = ''.obs;
  final RxDouble confidence = 0.0.obs;

  // ─── INIT ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    isAvailable.value = await _speech.initialize(
      onError: (error) {
        isListening.value = false;
        print('[Voice] Error: $error');
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          isListening.value = false;
        }
      },
    );
  }

  // ─── START LISTENING ───────────────────────────────────────────────────────

  Future<void> startListening({
    required void Function(String text) onResult,
    String language = 'en-US', // English by default
  }) async {
    if (!isAvailable.value) await init();
    if (!isAvailable.value) {
      Get.snackbar('Error', 'Voice search not available on this device',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    recognizedText.value = '';
    isListening.value = true;

    await _speech.listen(
      onResult: (result) {
        recognizedText.value = result.recognizedWords;
        confidence.value = result.confidence;
        if (result.finalResult) {
          isListening.value = false;
          onResult(result.recognizedWords);
        }
      },
      localeId: language,
      listenMode: ListenMode.search,
      cancelOnError: true,
      partialResults: true,
    );
  }

  // ─── START ENGLISH ─────────────────────────────────────────────────────────

  Future<void> startListeningEnglish({
    required void Function(String text) onResult,
  }) async {
    await startListening(onResult: onResult, language: 'en-US');
  }

  // ─── STOP ──────────────────────────────────────────────────────────────────

  Future<void> stopListening() async {
    await _speech.stop();
    isListening.value = false;
  }

  // ─── CANCEL ────────────────────────────────────────────────────────────────

  Future<void> cancel() async {
    await _speech.cancel();
    isListening.value = false;
    recognizedText.value = '';
  }

  // ─── AVAILABLE LANGUAGES ───────────────────────────────────────────────────

  Future<List<LocaleName>> getAvailableLanguages() async {
    return await _speech.locales();
  }
}
