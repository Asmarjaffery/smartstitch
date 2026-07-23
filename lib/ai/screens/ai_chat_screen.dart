import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/ai/controller/ai_chat_controller.dart';
import 'package:smartstitch/ai/widgets/ai_message_bubble.dart';
import 'package:smartstitch/ai/widgets/ai_rewrite_panel.dart';
import 'package:smartstitch/ai/widgets/ai_suggested_questions.dart';
import 'package:smartstitch/ai/widgets/ai_typing_indicator.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/routes/routes.dart';

class AiChatScreen extends StatelessWidget {
  const AiChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lazily put only if not already registered
    if (!Get.isRegistered<AiChatController>()) {
      Get.put(AiChatController());
    }
    final controller = AiChatController.to;

    // Start fresh conversation if none active
    if (controller.activeConversation.value == null) {
      controller.startNewConversation();
    }

    // Agar Order Detail se "Ask AI to Call Rider" button dabaya gaya hai,
    // toh rider ka phone seedha action ke taur pe bhej dein (koi Firestore
    // lookup nahi — number already screen pe available tha).
    final args = Get.arguments;
    if (args is Map && args['type'] == 'callRider') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.sendCallRiderAction(args['phone'] as String? ?? '');
      });
    } else if (args is Map && args['type'] == 'callCustomer') {
      // Rider side: customer tapped "Ask AI to Call Rider" — show the
      // same InDrive-style card, but for calling the customer back.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.sendCallCustomerAction(
          phone: args['phone'] as String? ?? '',
          name: args['name'] as String? ?? 'Customer',
          lat: args['lat'] as double?,
          lng: args['lng'] as double?,
          statusLabel: args['status'] as String? ??
              'Aap se baat karna chahte hain',
        );
      });
    } else if (args is String && args.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.sendMessage(args);
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context, controller),
      // resizeToAvoidBottomInset keeps the input bar riding just above the
      // keyboard on every device instead of being hidden behind it.
      resizeToAvoidBottomInset: true,
      body: MediaQuery(
        // Clamp system font-scale so long device/user font settings can't
        // break bubble/input layouts on smaller phones (iPhone SE etc.)
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.of(context)
              .textScaler
              .clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15),
        ),
        child: SafeArea(
          top: false, // AppBar already handles the top safe area
          child: Column(
            children: [
              Expanded(child: _MessageList(controller: controller)),
              Obx(() => controller.showRewritePanel.value
                  ? AiRewritePanel(
                      originalText: controller.rewriteTargetText.value,
                      onRewrite: controller.rewriteMessage,
                      onClose: controller.closeRewritePanel,
                    )
                  : const SizedBox.shrink()),
              _InputBar(controller: controller),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, AiChatController c) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        onPressed: () => Get.back(),
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI Assistant',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(
                    c.activeConversation.value?.title ?? 'New conversation',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.forum_rounded, size: 22),
          tooltip: 'Conversations',
          onPressed: () => Get.toNamed(AppRoutes.aiConversations),
        ),
        Obx(() => c.activeConversation.value?.messages.isNotEmpty == true
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 22),
                onSelected: (val) {
                  if (val == 'clear') c.clearChat();
                  if (val == 'new') c.startNewConversation();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'new', child: Text('New chat')),
                  PopupMenuItem(value: 'clear', child: Text('Clear chat')),
                ],
              )
            : const SizedBox.shrink()),
      ],
    );
  }
}

// ── Message list ──────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final AiChatController controller;
  const _MessageList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final messages = controller.messages;
      final isTyping = controller.isTyping.value;
      final isEmpty = messages.isEmpty && !isTyping;

      if (isEmpty) {
        return _EmptyState(controller: controller);
      }

      return ListView.builder(
        controller: controller.scrollController,
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        itemCount: messages.length + (isTyping ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == messages.length && isTyping) {
            return const AiTypingIndicator();
          }
          final msg = messages[i];
          return AiMessageBubble(
            message: msg,
            onRewrite: controller.openRewritePanel,
          );
        },
      );
    });
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AiChatController controller;
  const _EmptyState({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 48),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'SmartStitch AI',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How can I help you today?',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 24),
          AiSuggestedQuestions(
            questions: controller.suggestedQuestions,
            onTap: controller.sendSuggestion,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final AiChatController controller;
  const _InputBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 8 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: controller.inputController,
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Ask anything...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (t) => controller.sendMessage(t),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Obx(() => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: FloatingActionButton.small(
                  onPressed: controller.isTyping.value
                      ? null
                      : () => controller
                          .sendMessage(controller.inputController.text),
                  backgroundColor: controller.isTyping.value
                      ? Colors.grey[300]
                      : AppColors.primary,
                  elevation: 0,
                  child: controller.isTyping.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.grey),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                ),
              )),
        ],
      ),
    );
  }
}