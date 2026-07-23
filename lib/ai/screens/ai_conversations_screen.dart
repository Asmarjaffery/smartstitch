import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smartstitch/ai/controller/ai_chat_controller.dart';
import 'package:smartstitch/ai/models/ai_conversation.dart';
import 'package:smartstitch/core/theme/app.theme.dart';

class AiConversationsScreen extends StatelessWidget {
  const AiConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AiChatController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: AppColors.primary),
            tooltip: 'New conversation',
            onPressed: () {
              controller.startNewConversation();
              Get.back();
            },
          ),
        ],
      ),
      body: SafeArea(
        // Keeps content clear of notches / rounded corners / gesture bars
        // on any device (iPhone Dynamic Island, Samsung punch-hole, etc.)
        child: MediaQuery(
          // Clamp system font-scale so a user's large "Accessibility text
          // size" setting can never push our fixed-height rows into
          // overflow again, while still allowing modest scaling.
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context)
                .textScaler
                .clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15),
          ),
          child: Obx(() {
            if (controller.isLoadingConversations.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.conversations.isEmpty) {
              return _EmptyConversations(
                onNew: () {
                  controller.startNewConversation();
                  Get.back();
                },
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: controller.conversations.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 64),
              itemBuilder: (_, i) {
                final conv = controller.conversations[i];
                return _ConversationTile(
                  conversation: conv,
                  isActive:
                      controller.activeConversation.value?.id == conv.id,
                  onTap: () {
                    controller.openConversation(conv);
                    Get.back();
                  },
                  onDelete: () =>
                      _confirmDelete(context, controller, conv),
                  onRename: () =>
                      _showRenameDialog(context, controller, conv),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AiChatController c,
      AiConversation conv) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: Text('"${conv.title}"'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              c.deleteConversation(conv);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, AiChatController c,
      AiConversation conv) {
    final ctrl = TextEditingController(text: conv.title);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename conversation'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new title'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (ctrl.text.trim().isNotEmpty) {
                c.renameConversation(conv, ctrl.text.trim());
              }
            },
            child: Text('Save',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final AiConversation conversation;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _ConversationTile({
    required this.conversation,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final lastMsg = conversation.lastMessage;
    final date = conversation.updatedAt;
    final dateStr = _formatDate(date);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isActive
            ? AppColors.primary
            : AppColors.primary.withOpacity(0.12),
        child: Icon(Icons.chat_bubble_rounded,
            color: isActive ? Colors.white : AppColors.primary, size: 18),
      ),
      title: Text(
        conversation.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            fontWeight:
                isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14),
      ),
      subtitle: lastMsg != null
          ? Text(
              lastMsg.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            )
          : null,
      trailing: SizedBox(
        // Fixed height container so the popup button's default 48px tap
        // target can never push the ListTile past its allowed height on
        // any device (small phones were the ones overflowing).
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(dateStr,
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            SizedBox(
              height: 28,
              width: 28,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                splashRadius: 18,
                icon: Icon(Icons.more_vert_rounded,
                    size: 18, color: Colors.grey[400]),
                onSelected: (val) {
                  if (val == 'rename') onRename();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('Rename')),
                  PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            ),
          ],
        ),
      ),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return DateFormat.jm().format(date);
    }
    return DateFormat.MMMd().format(date);
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyConversations extends StatelessWidget {
  final VoidCallback onNew;
  const _EmptyConversations({required this.onNew});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No conversations yet',
              style:
                  TextStyle(color: Colors.grey[500], fontSize: 15)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onNew,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Start a new conversation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}