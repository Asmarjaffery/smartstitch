import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smartstitch/controllers/chat_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../models/chat_room_model.dart';
import '../../core/theme/app.theme.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceAlt =
        isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: Text(
          'Chats',
          style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 24, color: textPrimary),
        ),
        actions: [
          _RoundIconButton(
            icon: Icons.search_rounded,
            background: surfaceAlt,
            iconColor: textPrimary,
            onTap: () {},
          ),
          const SizedBox(width: 10),
          _RoundIconButton(
            icon: Icons.add_rounded,
            background: AppColors.primary,
            iconColor: Colors.white,
            onTap: () => Get.toNamed('/user-discovery'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (controller.rooms.isEmpty) {
          return const _EmptyState();
        }

        final onlineRooms =
            controller.rooms.where((r) => r.isOtherOnline).toList();

        return Column(
          children: [
            // ─── Online Users Strip ───────────────────────────────────────
            if (onlineRooms.isNotEmpty)
              _OnlineStrip(
                onlineRooms: onlineRooms,
                controller: controller,
              ),

            // ─── Chat List ────────────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 4),
                itemCount: controller.rooms.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 82,
                  endIndent: 16,
                  color: border,
                ),
                itemBuilder: (context, index) {
                  final room = controller.rooms[index];
                  return _AnimatedChatTile(
                    room: room,
                    controller: controller,
                    index: index,
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─── Round Icon Button (AppBar) ────────────────────────────────────────────

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color iconColor;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: AppRadius.medium,
      child: InkWell(
        borderRadius: AppRadius.medium,
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        builder: (context, value, child) => Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(scale: value.clamp(0.5, 1.0), child: child),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text('No conversations yet',
                style: AppTextStyles.h4.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary)),
            const SizedBox(height: 8),
            Text('Start messaging to begin',
                style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextHint
                        : AppColors.lightTextHint)),
          ],
        ),
      ),
    );
  }
}

// ─── Online Strip ─────────────────────────────────────────────────────────────

class _OnlineStrip extends StatelessWidget {
  final List<ChatRoomModel> onlineRooms;
  final ChatController controller;

  const _OnlineStrip({
    required this.onlineRooms,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stripColor = isDark
        ? AppColors.primaryDark.withValues(alpha: 0.35)
        : AppColors.primarySoft;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        color: stripColor,
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Online now',
                  style: AppTextStyles.labelLarge.copyWith(color: textPrimary),
                ),
                const Spacer(),
                InkWell(
                  borderRadius: AppRadius.xs,
                  onTap: () {},
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      'See all',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 92,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              itemCount: onlineRooms.length,
              itemBuilder: (context, index) {
                final room = onlineRooms[index];
                return _OnlineAvatar(
                  room: room,
                  controller: controller,
                  index: index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Online Avatar ────────────────────────────────────────────────────────────

class _OnlineAvatar extends StatelessWidget {
  final ChatRoomModel room;
  final ChatController controller;
  final int index;

  const _OnlineAvatar({
    required this.room,
    required this.controller,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final otherUserId = controller.getOtherUserId(room);
    final name = controller.getOtherUserName(room);
    final imageUrl = controller.getOtherUserImage(room);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ringBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 80)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value.clamp(0.0, 1.0))),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () async {
          if (otherUserId.isEmpty) return;
          await controller.openChat(otherUserId);
          Get.to(
            () => ChatRoomScreen(
              otherUserId: otherUserId,
              roomName: name,
              profileImageUrl: imageUrl,
            ),
            transition: Transition.rightToLeft,
            duration: const Duration(milliseconds: 300),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(right: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  _UserAvatar(
                    imageUrl: imageUrl,
                    name: name,
                    radius: 27,
                    fontSize: 18,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: ringBg, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              SizedBox(
                width: 60,
                child: Text(
                  name.split(' ')[0],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Animated Chat Tile ───────────────────────────────────────────────────────

class _AnimatedChatTile extends StatelessWidget {
  final ChatRoomModel room;
  final ChatController controller;
  final int index;

  const _AnimatedChatTile({
    required this.room,
    required this.controller,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + (index * 60)),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(30 * (1 - value.clamp(0.0, 1.0)), 0),
          child: child,
        ),
      ),
      child: _ChatTile(room: room, controller: controller),
    );
  }
}

// ─── Chat Tile ────────────────────────────────────────────────────────────────

class _ChatTile extends StatelessWidget {
  final ChatRoomModel room;
  final ChatController controller;

  const _ChatTile({required this.room, required this.controller});

  @override
  Widget build(BuildContext context) {
    final unreadCount = room.unreadCount;
    final hasUnread = unreadCount > 0;
    final otherUserId = controller.getOtherUserId(room);
    final name = controller.getOtherUserName(room);
    final imageUrl = controller.getOtherUserImage(room);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ringBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textHint = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;

    return InkWell(
      onTap: () async {
        if (otherUserId.isEmpty) return;
        await controller.openChat(otherUserId);
        Get.to(
          () => ChatRoomScreen(
            otherUserId: otherUserId,
            roomName: name,
            profileImageUrl: imageUrl,
          ),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 300),
        );
      },
      splashColor: AppColors.primarySoft,
      highlightColor: AppColors.primarySoft.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // ── Avatar ──────────────────────────────────────────────────
            Stack(
              children: [
                _UserAvatar(
                  imageUrl: imageUrl,
                  name: name,
                  radius: 26,
                  fontSize: 17,
                ),
                if (room.isOtherOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: ringBg, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // ── Info ─────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight:
                          hasUnread ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 15.5,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (!hasUnread)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(Icons.done_all_rounded,
                              size: 14, color: textHint),
                        ),
                      Expanded(
                        child: Text(
                          room.lastMessageText ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasUnread ? textPrimary : textSecondary,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Meta ──────────────────────────────────────────────────────
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(room.lastMessageAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: hasUnread ? AppColors.primary : textHint,
                    fontWeight:
                        hasUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 6),
                if (hasUnread)
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}';
    }
  }
}

// ─── Shared User Avatar Widget ────────────────────────────────────────────────
// Image hai toh image, nahi toh first letter — dono jagah use hoga

class _UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final double fontSize;

  const _UserAvatar({
    required this.imageUrl,
    required this.name,
    required this.radius,
    required this.fontSize,
  });

  String get _initial =>
      name.isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

  bool get _hasImage =>
      imageUrl != null && imageUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_hasImage) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (_, __) => _FallbackAvatar(
            initial: _initial,
            radius: radius,
            fontSize: fontSize,
          ),
          errorWidget: (_, __, ___) => _FallbackAvatar(
            initial: _initial,
            radius: radius,
            fontSize: fontSize,
          ),
        ),
      );
    }
    return _FallbackAvatar(
      initial: _initial,
      radius: radius,
      fontSize: fontSize,
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  final String initial;
  final double radius;
  final double fontSize;

  const _FallbackAvatar({
    required this.initial,
    required this.radius,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}