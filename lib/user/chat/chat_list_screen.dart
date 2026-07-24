import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smartstitch/controllers/chat_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../models/chat_room_model.dart';
import '../../core/theme/app.theme.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late final ChatController controller;
  final TextEditingController _searchCtrl = TextEditingController();
  final RxBool _isSearching = false.obs;
  final RxString _query = ''.obs;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ChatController>();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    if (_isSearching.value) {
      _isSearching.value = false;
      _searchCtrl.clear();
      _query.value = '';
      FocusScope.of(context).unfocus();
    } else {
      _isSearching.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceAlt =
        isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textHint = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: Obx(() => _isSearching.value
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: TextStyle(color: textPrimary, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search artists...',
                  hintStyle: TextStyle(color: textHint),
                  border: InputBorder.none,
                ),
                onChanged: (v) => _query.value = v.trim(),
              )
            : Text(
                'Chats',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    color: textPrimary),
              )),
        actions: [
          Obx(() => _RoundIconButton(
                icon: _isSearching.value
                    ? Icons.close_rounded
                    : Icons.search_rounded,
                background: surfaceAlt,
                iconColor: textPrimary,
                onTap: _toggleSearch,
              )),
          Obx(() => _isSearching.value
              ? const SizedBox.shrink()
              : Row(
                  children: [
                    const SizedBox(width: 10),
                    _RoundIconButton(
                      icon: Icons.add_rounded,
                      background: AppColors.primary,
                      iconColor: Colors.white,
                      onTap: () => Get.toNamed('/user-discovery'),
                    ),
                  ],
                )),
          const SizedBox(width: 12),
        ],
      ),
      body: Obx(() {
        // ── SEARCH MODE: show matching artists only ─────────────────────
        if (_isSearching.value) {
          return _ArtistSearchResults(
            query: _query.value,
            controller: controller,
          );
        }

        // ── DEFAULT MODE: all artists strip + existing chats ────────────
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final onlineRooms =
            controller.rooms.where((r) => r.isOtherOnline).toList();

        return Column(
          children: [
            // ─── All Artists Strip (start a chat with anyone) ──────────
            _AllArtistsStrip(controller: controller),

            // ─── Online Users Strip ─────────────────────────────────────
            if (onlineRooms.isNotEmpty)
              _OnlineStrip(
                onlineRooms: onlineRooms,
                controller: controller,
              ),

            // ─── Chat List ───────────────────────────────────────────────
            Expanded(
              child: controller.rooms.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
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

// ─── All Artists Strip ─────────────────────────────────────────────────────
// Har artist top pe dikhta hai taake user kisi se bhi seedha chat shuru kar sake.

class _AllArtistsStrip extends StatelessWidget {
  final ChatController controller;
  const _AllArtistsStrip({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('artists').snapshots(),
      builder: (context, snapshot) {
        // 🔎 DEBUG: agar artists nahi dikh rahe to yeh line console mein
        // asal wajah bata degi (permission-denied, wrong collection, etc.)
        if (snapshot.hasError) {
          debugPrint('❌ Artists strip error: ${snapshot.error}');
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Artists load nahi ho rahe: ${snapshot.error}',
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            ),
          );
        }

        final allDocs = snapshot.data?.docs ?? [];
        debugPrint('✅ Artists fetched: ${allDocs.length}');

        if (allDocs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Text(
              'Koi artist available nahi hai abhi',
              style: TextStyle(color: textPrimary.withValues(alpha: 0.6), fontSize: 13),
            ),
          );
        }

        // Apna khud ka artist doc (agar current user khud artist hai) exclude karo
        final docs =
            allDocs.where((d) => d.id != controller.myId).toList();

        if (docs.isEmpty) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: border, width: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Text(
                  'Artists',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: textPrimary,
                  ),
                ),
              ),
              SizedBox(
                height: 92,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final name = (data['businessName'] ??
                            data['name'] ??
                            data['displayName'] ??
                            'Artist')
                        .toString();
                    final image = (data['profileImageUrl'] ?? '').toString();

                    return _ArtistQuickAvatar(
                      artistId: doc.id,
                      name: name,
                      imageUrl: image,
                      controller: controller,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ArtistQuickAvatar extends StatelessWidget {
  final String artistId;
  final String name;
  final String imageUrl;
  final ChatController controller;

  const _ArtistQuickAvatar({
    required this.artistId,
    required this.name,
    required this.imageUrl,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return GestureDetector(
      onTap: () async {
        await controller.openChat(artistId);
        Get.to(
          () => ChatRoomScreen(
            otherUserId: artistId,
            roomName: name,
            profileImageUrl: imageUrl.isNotEmpty ? imageUrl : null,
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
            _UserAvatar(
              imageUrl: imageUrl,
              name: name,
              radius: 27,
              fontSize: 18,
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
    );
  }
}

// ─── Artist Search Results ─────────────────────────────────────────────────

class _ArtistSearchResults extends StatelessWidget {
  final String query;
  final ChatController controller;

  const _ArtistSearchResults({required this.query, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textHint = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('artists').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('❌ Artist search error: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Artists load nahi ho rahe: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final allDocs = (snapshot.data?.docs ?? [])
            .where((d) => d.id != controller.myId)
            .toList();

        final q = query.toLowerCase();
        final results = q.isEmpty
            ? allDocs
            : allDocs.where((d) {
                final data = d.data() as Map<String, dynamic>? ?? {};
                final name = (data['businessName'] ??
                        data['name'] ??
                        data['displayName'] ??
                        '')
                    .toString();
                return name.toLowerCase().contains(q);
              }).toList();

        if (results.isEmpty) {
          return Center(
            child: Text(
              q.isEmpty ? 'Start typing to search artists' : 'No artist found',
              style: TextStyle(color: textHint, fontSize: 14),
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final doc = results[index];
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final name = (data['businessName'] ??
                    data['name'] ??
                    data['displayName'] ??
                    'Artist')
                .toString();
            final image = (data['profileImageUrl'] ?? '').toString();
            final specializations =
                (data['specializations'] as List?)?.cast<String>() ?? [];
            final subtitle = specializations.isNotEmpty
                ? specializations.join(', ')
                : (data['bio'] ?? '').toString();

            return ListTile(
              leading: _UserAvatar(
                imageUrl: image,
                name: name,
                radius: 24,
                fontSize: 16,
              ),
              title: Text(
                name,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: textPrimary),
              ),
  subtitle: subtitle.isNotEmpty
    ? Text(subtitle, style: TextStyle(color: textHint))
    : null,
              onTap: () async {
                await controller.openChat(doc.id);
                Get.to(
                  () => ChatRoomScreen(
                    otherUserId: doc.id,
                    roomName: name,
                    profileImageUrl: image.isNotEmpty ? image : null,
                  ),
                  transition: Transition.rightToLeft,
                  duration: const Duration(milliseconds: 300),
                );
              },
            );
          },
        );
      },
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



