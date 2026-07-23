import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstitch/ai/cache/ai_cache.dart';
import 'package:smartstitch/ai/config/ai_config.dart';
import 'package:smartstitch/ai/context/ai_context_provider.dart';
import 'package:smartstitch/ai/intent/ai_intent.dart';
import 'package:smartstitch/ai/intent/intent_detector.dart';
import 'package:smartstitch/ai/models/ai_conversation.dart';
import 'package:smartstitch/ai/models/ai_message.dart';
import 'package:smartstitch/ai/prompt/prompt_builder.dart';
import 'package:smartstitch/ai/repository/ai_repository_impl.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:uuid/uuid.dart';

import '../providers/groq_provider.dart';

/// The ONLY class that communicates with Gemini.
/// All other layers call this service.
class AiService {
  AiService._();
  static final AiService instance = AiService._();

  final _provider = GroqProvider();
  final _repo = AiRepositoryImpl();
  final _cache = AiCache();
  final _uuid = const Uuid();

  // ── Language detection ────────────────────────────────────────────────────

  String detectLanguage(String text) {
    // Urdu script range: \u0600–\u06FF
    final urduChars = RegExp(r'[\u0600-\u06FF]');
    if (urduChars.hasMatch(text)) return 'ur';

    // Roman Urdu common words
    final romanUrdu = RegExp(
      r'\b(aap|mera|meri|kya|hai|hain|nahi|theek|shukria|please|karo|karna|'
      r'hogaya|hogai|bhai|yaar|kal|aaj|kal|bilkul|zaroor|hoga)\b',
      caseSensitive: false,
    );
    if (romanUrdu.hasMatch(text)) return 'roman_ur';

    return 'en';
  }

  // ── Send message ──────────────────────────────────────────────────────────

  Future<AiMessage> sendMessage({
    required String userId,
    required UserRole role,
    required AiConversation conversation,
    required String userMessage,
  }) async {
    // Detect intent
    final intent = IntentDetector.detect(userMessage);

    // ── Call Rider shortcut ──────────────────────────────────────────────
    // Handled directly here (no Gemini call needed) — just look up the
    // rider's phone for the customer's active order and hand back a
    // "call" action that the UI can render as a button.
    if (intent == AiIntent.callRider && role == UserRole.customer) {
      final phone = await _getActiveRiderPhone(userId);
      if (phone == null || phone.isEmpty) {
        return AiMessage(
          id: _uuid.v4(),
          role: AiMessageRole.assistant,
          text: 'Abhi tak koi rider assign nahi hua aapke order ke liye.',
          timestamp: DateTime.now(),
        );
      }
      return AiMessage(
        id: _uuid.v4(),
        role: AiMessageRole.assistant,
        text: 'Yeh raha aapke rider ka number — neeche button dabayein call karne ke liye.',
        timestamp: DateTime.now(),
        actionType: 'call',
        actionValue: phone,
      );
    }

    // Detect language
    final lang = detectLanguage(userMessage);
    await _cache.setLanguage(lang);

    // Get or build context summary
    String contextSummary = '';
    final cached = await _cache.getContext(userId);
    if (cached != null) {
      contextSummary = cached['summary'] as String? ?? '';
    } else {
      contextSummary = await AiContextProvider.getSummary(
        userId: userId,
        role: role,
      );
      await _cache.setContext(userId, {'summary': contextSummary});
    }

    // Build system prompt
    final systemPrompt = PromptBuilder.build(
      role: role,
      language: lang,
      contextSummary: contextSummary,
    );

    // Build history (limit to last N messages, alternating user/model)
    final history = _buildHistory(conversation.messages);

    // Call Gemini
    final responseText = await _provider.sendMessage(
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      history: history,
    );

    return AiMessage(
      id: _uuid.v4(),
      role: AiMessageRole.assistant,
      text: responseText,
      timestamp: DateTime.now(),
    );
  }

  // Finds the customer's currently active order (rider assigned / in
  // progress) and returns that rider's phone number, or null if none.
  Future<String?> _getActiveRiderPhone(String userId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('customerId', isEqualTo: userId)
          .where('status', whereIn: ['riderAssigned', 'inProgress'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;

      final riderId = snap.docs.first.data()['riderId'] as String?;
      if (riderId == null || riderId.isEmpty) return null;

      final riderDoc = await FirebaseFirestore.instance
          .collection('riders')
          .doc(riderId)
          .get();
      return riderDoc.data()?['phone'] as String?;
    } catch (_) {
      return null;
    }
  }

  List<Map<String, String>> _buildHistory(List<AiMessage> messages) {
    final limit = AiConfig.historySize;
    final recent = messages.length > limit
        ? messages.sublist(messages.length - limit)
        : messages;
    return recent.map((m) => m.toHistoryMap()).toList();
  }

  // ── Conversation management ───────────────────────────────────────────────

  AiConversation createConversation({
    required String userId,
    required UserRole role,
  }) =>
      AiConversation(
        id: '',
        userId: userId,
        title: 'New Conversation',
        role: role.name,
        language: 'en',
        messages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  String generateTitle(String firstUserMessage) {
    if (firstUserMessage.length <= 40) return firstUserMessage;
    return '${firstUserMessage.substring(0, 37)}...';
  }

  Future<List<AiConversation>> getConversations(String userId) =>
      _repo.getConversations(userId);

  Future<String> saveConversation(AiConversation conversation) =>
      _repo.saveConversation(conversation);

  Future<void> updateConversation(AiConversation conversation) =>
      _repo.updateConversation(conversation);

  Future<void> deleteConversation(String userId, String conversationId) =>
      _repo.deleteConversation(userId, conversationId);

  void dispose() => _provider.dispose();
}