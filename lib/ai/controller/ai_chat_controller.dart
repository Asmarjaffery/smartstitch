import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:smartstitch/ai/models/ai_conversation.dart';
import 'package:smartstitch/ai/models/ai_message.dart';
import 'package:smartstitch/ai/prompt/prompt_builder.dart';
import 'package:smartstitch/ai/service/ai_service.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/models/enums.dart';

class AiChatController extends GetxController {
  static AiChatController get to => Get.find();

  final _service = AiService.instance;
  final _uuid = const Uuid();

  // ── Observables ───────────────────────────────────────────────────────────
  final RxList<AiConversation> conversations = <AiConversation>[].obs;
  final Rx<AiConversation?> activeConversation = Rx<AiConversation?>(null);
  final RxBool isTyping = false.obs;
  final RxBool isLoadingConversations = false.obs;
  final RxString errorMessage = ''.obs;

  // ── Text controller + scroll ──────────────────────────────────────────────
  final TextEditingController inputController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // ── Rewrite panel ─────────────────────────────────────────────────────────
  final RxBool showRewritePanel = false.obs;
  final RxString rewriteTargetText = ''.obs;

  // ── State helpers ─────────────────────────────────────────────────────────
  UserRole get role => AuthController.to.userRole.value;
  String get userId => AuthController.to.currentUserId ?? '';
  List<AiMessage> get messages => activeConversation.value?.messages ?? [];
  List<String> get suggestedQuestions => PromptBuilder.suggestedQuestions(role);

  @override
  void onInit() {
    super.onInit();
    loadConversations();
  }

  @override
  void onClose() {
    inputController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  // ── Load conversations ────────────────────────────────────────────────────

  Future<void> loadConversations() async {
    if (userId.isEmpty) return;
    isLoadingConversations.value = true;
    try {
      final list = await _service.getConversations(userId);
      conversations.assignAll(list);
    } catch (e) {
      errorMessage.value = 'Failed to load conversations.';
    } finally {
      isLoadingConversations.value = false;
    }
  }

  // ── Start new conversation ────────────────────────────────────────────────

  void startNewConversation() {
    final conv = _service.createConversation(userId: userId, role: role);
    activeConversation.value = conv;
    errorMessage.value = '';
  }

  // ── Open existing conversation ────────────────────────────────────────────

  void openConversation(AiConversation conversation) {
    activeConversation.value = conversation;
    errorMessage.value = '';
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  // ── Send message ──────────────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isTyping.value) return;

    inputController.clear();
    errorMessage.value = '';

    // Ensure active conversation exists
    if (activeConversation.value == null) startNewConversation();

    // Add user message
    final userMsg = AiMessage(
      id: _uuid.v4(),
      role: AiMessageRole.user,
      text: trimmed,
      timestamp: DateTime.now(),
    );
    _appendMessage(userMsg);
    _scrollToBottom();

    // Set title on first message
    if (messages.length == 1) {
      _updateTitle(_service.generateTitle(trimmed));
    }

    isTyping.value = true;

    try {
      final aiMsg = await _service.sendMessage(
        userId: userId,
        role: role,
        conversation: activeConversation.value!,
        userMessage: trimmed,
      );
      _appendMessage(aiMsg);
    } catch (e) {
      _appendMessage(AiMessage(
        id: _uuid.v4(),
        role: AiMessageRole.assistant,
        text: 'Something went wrong. Please try again.',
        timestamp: DateTime.now(),
        isError: true,
      ));
    } finally {
      isTyping.value = false;
      _scrollToBottom();
      await _persistConversation();
    }
  }

  // ── Suggested question shortcut ───────────────────────────────────────────

  Future<void> sendSuggestion(String question) => sendMessage(question);

  // ── Call Rider (direct, no Firestore lookup) ─────────────────────────────
  // Used by the "Ask AI to Call Rider" button on the Order Detail screen,
  // which already has the rider's phone loaded on screen. Passing it
  // straight in avoids re-querying Firestore (and any field/collection
  // name mismatches).
  //
  // NOTE: no fake user bubble is created anymore, and the assistant
  // message has no intro text — only the rider card shows.
  Future<void> sendCallRiderAction(String phone) async {
    if (activeConversation.value == null) startNewConversation();

    if (messages.isEmpty) {
      _updateTitle('Call Rider');
    }

    final assistantMsg = AiMessage(
      id: _uuid.v4(),
      role: AiMessageRole.assistant,
      text: phone.isEmpty
          ? 'No rider has been assigned to your order yet.'
          : '',
      timestamp: DateTime.now(),
      actionType: phone.isEmpty ? null : 'call',
      actionValue: phone.isEmpty ? null : phone,
    );
    _appendMessage(assistantMsg);

    _scrollToBottom();
    await _persistConversation();
  }

  // ── Call Customer (rider side, mirrors sendCallRiderAction) ──────────────
  // Used when a customer taps "Ask AI to Call Rider" and the rider needs
  // to see it as an InDrive-style chat card — NOT a popup — inside the
  // rider's own AI Assistant chat. RiderOrderController's Firestore
  // listener calls this the moment a call request comes in.
  Future<void> sendCallCustomerAction({
    required String phone,
    required String name,
    double? lat,
    double? lng,
    String statusLabel = 'Wants to talk to you',
  }) async {
    if (activeConversation.value == null) startNewConversation();

    if (messages.isEmpty) {
      _updateTitle('Customer Call');
    }

    final assistantMsg = AiMessage(
      id: _uuid.v4(),
      role: AiMessageRole.assistant,
      text: phone.isEmpty
          ? "Customer's phone number isn't available yet."
          : '',
      timestamp: DateTime.now(),
      actionType: phone.isEmpty ? null : 'call_customer',
      actionValue: phone.isEmpty ? null : phone,
      actionMeta: phone.isEmpty
          ? null
          : {
              'customerName': name,
              'customerStatus': statusLabel,
              if (lat != null) 'lat': lat.toString(),
              if (lng != null) 'lng': lng.toString(),
            },
    );
    _appendMessage(assistantMsg);

    _scrollToBottom();
    await _persistConversation();
  }

  // ── Rewrite panel ─────────────────────────────────────────────────────────

  void openRewritePanel(String text) {
    rewriteTargetText.value = text;
    showRewritePanel.value = true;
  }

  void closeRewritePanel() => showRewritePanel.value = false;

  Future<void> rewriteMessage(String style) async {
    final original = rewriteTargetText.value;
    if (original.isEmpty) return;
    closeRewritePanel();
    final prompt =
        'Rewrite the following message in a $style tone (do not add any explanation, '
        'just return the rewritten message):\n\n"$original"';
    await sendMessage(prompt);
  }

  // ── Delete conversation ───────────────────────────────────────────────────

  Future<void> deleteConversation(AiConversation conv) async {
    if (conv.id.isEmpty) return;
    try {
      await _service.deleteConversation(userId, conv.id);
      conversations.remove(conv);
      if (activeConversation.value?.id == conv.id) {
        activeConversation.value = null;
      }
    } catch (_) {}
  }

  // ── Rename conversation ───────────────────────────────────────────────────

  Future<void> renameConversation(AiConversation conv, String newTitle) async {
    final updated = conv.copyWith(title: newTitle);
    try {
      if (updated.id.isNotEmpty) await _service.updateConversation(updated);
      final idx = conversations.indexOf(conv);
      if (idx >= 0) conversations[idx] = updated;
      if (activeConversation.value?.id == conv.id) {
        activeConversation.value = updated;
      }
    } catch (_) {}
  }

  // ── Clear current chat ────────────────────────────────────────────────────

  void clearChat() {
    if (activeConversation.value == null) return;
    activeConversation.value = activeConversation.value!.copyWith(messages: []);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _appendMessage(AiMessage msg) {
    if (activeConversation.value == null) return;
    final updated = activeConversation.value!.copyWith(
      messages: [...activeConversation.value!.messages, msg],
    );
    activeConversation.value = updated;
  }

  void _updateTitle(String title) {
    if (activeConversation.value == null) return;
    activeConversation.value = activeConversation.value!.copyWith(title: title);
  }

  Future<void> _persistConversation() async {
    final conv = activeConversation.value;
    if (conv == null || conv.messages.isEmpty) return;
    try {
      if (conv.id.isEmpty) {
        final id = await _service.saveConversation(conv);
        activeConversation.value = activeConversation.value!.copyWith();
        // Reload to pick up the new id
        final saved = AiConversation(
          id: id,
          userId: conv.userId,
          title: conv.title,
          role: conv.role,
          language: conv.language,
          messages: conv.messages,
          createdAt: conv.createdAt,
          updatedAt: DateTime.now(),
        );
        activeConversation.value = saved;
        conversations.insert(0, saved);
      } else {
        await _service.updateConversation(conv);
        final idx = conversations.indexWhere((c) => c.id == conv.id);
        if (idx >= 0) conversations[idx] = conv;
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}