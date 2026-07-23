import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:smartstitch/core/utils/helpers.dart';
import 'package:smartstitch/services/chat_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../controllers/chat_controller.dart';
import '../../models/chat_message_model.dart';
import '../../models/enums.dart';
import '../../core/theme/app.theme.dart';

// ─── Chat Room Screen ─────────────────────────────────────────────────────────

class ChatRoomScreen extends StatefulWidget {
  final String otherUserId;
  final String roomName;
  final String? phoneNumber;
  final String? profileImageUrl;

  const ChatRoomScreen({
    super.key,
    required this.otherUserId,
    required this.roomName,
    this.phoneNumber,
    this.profileImageUrl,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late final ChatController _controller;
  late final AnimationController _appBarAnim;
  late final AnimationController _inputAnim;

  final RxBool _isTypingLocal = false.obs;

  // My profile image — from AuthController current user
  String? get _myImage {
    try {
      return _controller.myProfileImage;
    } catch (_) {
      return null;
    }
  }

  String get _myName {
    try {
      return _controller.myName;
    } catch (_) {
      return 'Me';
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ChatController>();
    WidgetsBinding.instance.addObserver(this);

    _appBarAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _inputAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _inputAnim.forward();
    });

    _textController.addListener(() {
      _isTypingLocal.value = _textController.text.trim().isNotEmpty;
      _controller.onTypingChanged(_textController.text);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _controller.onTypingChanged('');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _controller.sendText(text, widget.otherUserId);
    _textController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;

    // Preview + confirm dialog
    final bytes = await picked.readAsBytes();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    final confirmed = await Get.dialog<bool>(
      Dialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.memory(bytes,
                  height: 280, width: double.infinity, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.medium),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.medium),
                      ),
                      child: const Text('Send',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      _controller.isSending.value = true;
      final roomId = _controller.currentRoomId.value;
      if (roomId.isEmpty) {
        AppHelpers.showError('Chat not ready');
        return;
      }
      final url = await ChatService.instance.uploadImageBytes(bytes, roomId);
      await _controller.sendImageFromBytes(bytes, widget.otherUserId, url);
    } catch (e) {
      AppHelpers.showError('Image send nahi hui');
    } finally {
      _controller.isSending.value = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _startRecording() => _controller.startRecording();

  void _stopAndSendVoice() {
    _controller.stopAndSendVoice(widget.otherUserId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _cancelRecording() => _controller.cancelRecording();

  void _shareLocation() {
    _controller.sendLocation(widget.otherUserId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _makeCall() async {
    final phone = widget.phoneNumber ?? '';
    if (phone.isEmpty) {
      _showCallDialog(null);
      return;
    }
    final uri = Uri.parse('tel:$phone');
    bool launched = false;
    try {
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    if (!launched) _showCallDialog(phone);
  }

  void _showCallDialog(String? phone) {
    final hasNumber = phone != null && phone.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textHint = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;

    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration:
                  BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)),
            ),
            _ChatAvatar(
                imageUrl: widget.profileImageUrl,
                name: widget.roomName,
                radius: 36),
            const SizedBox(height: 14),
            Text(widget.roomName,
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: textPrimary)),
            const SizedBox(height: 6),
            if (hasNumber) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(phone,
                      style: TextStyle(fontSize: 15, color: textSecondary)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: phone));
                      Get.back();
                      Get.snackbar('Copied!', 'Phone number copied',
                          backgroundColor: AppColors.primary,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM);
                    },
                    child: const Icon(Icons.copy_rounded,
                        size: 18, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: phone));
                      Get.back();
                    },
                    icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
                    label: const Text('Copy',
                        style: TextStyle(color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.medium)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Get.back();
                      await launchUrl(Uri.parse('tel:$phone'),
                          mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.call_rounded, color: Colors.white),
                    label: const Text('Call Now',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.medium)),
                  ),
                ),
              ]),
            ] else ...[
              const SizedBox(height: 8),
              Icon(Icons.phone_disabled_rounded, size: 44, color: textHint),
              const SizedBox(height: 12),
              Text('Phone number not available',
                  style: TextStyle(fontSize: 14, color: textSecondary)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.medium)),
                  child:
                      const Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Overflow Menu (only Delete chat now) ────────────────────────────────
  void _showMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration:
                  BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)),
            ),
            _MenuItem(
              icon: Icons.delete_outline_rounded,
              label: 'Delete chat',
              color: AppColors.error,
              onTap: () {
                Get.back();
                _deleteChat();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Delete Chat (full delete, backend + local) ──────────────────────────
  void _deleteChat() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    Get.dialog(AlertDialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
      title: Text('Delete Chat', style: TextStyle(color: textPrimary)),
      content: Text(
          'This chat with ${widget.roomName} will be permanently deleted for both users. Continue?',
          style: TextStyle(color: textSecondary)),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () async {
            Get.back(); // close confirmation dialog
            final ok = await _controller.deleteChat();
            if (ok) {
              Get.back(); // leave the chat room screen
              Get.snackbar('Deleted', 'Chat deleted successfully',
                  backgroundColor: AppColors.error, colorText: Colors.white);
            } else {
              AppHelpers.showError('Failed to delete chat');
            }
          },
          child: const Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.onTypingChanged('');
    _controller.closeChat();
    _appBarAnim.dispose();
    _inputAnim.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // ── Messages ────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary));
              }

              if (_controller.messages.isEmpty) {
                return _EmptyChat(
                    name: widget.roomName, imageUrl: widget.profileImageUrl);
              }

              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _scrollToBottom());

              return ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                itemCount: _controller.messages.length,
                itemBuilder: (context, index) {
                  final msg = _controller.messages[index];
                  final isMe = msg.senderId == _controller.myId;
                  final isLast = index == _controller.messages.length - 1;

                  // Check if next message is from same sender (for avatar grouping)
                  final isLastInGroup = index ==
                          _controller.messages.length - 1 ||
                      _controller.messages[index + 1].senderId != msg.senderId;

                  // Check if first in group (show date chip)
                  final showDate = index == 0;

                  return Column(
                    children: [
                      if (showDate) const _DateChip(label: 'Today'),
                      _MessageRow(
                        message: msg,
                        isMe: isMe,
                        isLastInGroup: isLastInGroup,
                        isLastMessage: isLast,
                        myImage: _myImage,
                        myName: _myName,
                        otherImage: widget.profileImageUrl,
                        otherName: widget.roomName,
                        index: index,
                      ),
                    ],
                  );
                },
              );
            }),
          ),

          // ── Typing Indicator ─────────────────────────────────────────────
          Obx(() => AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _controller.isTyping.value
                    ? _TypingIndicator(
                        name: widget.roomName,
                        imageUrl: widget.profileImageUrl,
                      )
                    : const SizedBox.shrink(),
              )),

          // ── Recording Bar ────────────────────────────────────────────────
          Obx(() => AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _controller.isRecording.value
                    ? _RecordingBar(
                        seconds: _controller.recordingSeconds.value,
                        onSend: _stopAndSendVoice,
                        onCancel: _cancelRecording,
                      )
                    : const SizedBox.shrink(),
              )),

          // ── Input Bar ────────────────────────────────────────────────────
          Obx(() => !_controller.isRecording.value
              ? SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: _inputAnim, curve: Curves.easeOutCubic)),
                  child: _InputBar(
                    textController: _textController,
                    isTypingLocal: _isTypingLocal,
                    onSendText: _sendText,
                    onPickImage: _pickAndSendImage,
                    onStartRecording: _startRecording,
                    onShareLocation: _shareLocation,
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textHint = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;

    return AppBar(
      backgroundColor: surface,
      titleSpacing: 0,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: border,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            size: 20, color: textPrimary),
        onPressed: () => Get.back(),
      ),
      title: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _appBarAnim, curve: Curves.easeOutCubic)),
        child: FadeTransition(
          opacity: _appBarAnim,
          child: GestureDetector(
            onTap: () {}, // Could open profile
            child: Row(
              children: [
                // Profile avatar with online ring
                _OnlineRingAvatar(
                  imageUrl: widget.profileImageUrl,
                  name: widget.roomName,
                  radius: 20,
                  otherUserId: widget.otherUserId,
                  controller: _controller,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.roomName,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      StreamBuilder<bool>(
                        stream: _controller
                            .watchOtherUserOnline(widget.otherUserId),
                        builder: (context, snapshot) {
                          final isOnline = snapshot.data ?? false;
                          return Obx(() => AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  _controller.isTyping.value
                                      ? 'typing...'
                                      : isOnline
                                          ? 'Online'
                                          : 'Offline',
                                  key: ValueKey(_controller.isTyping.value
                                      ? 'typing'
                                      : isOnline
                                          ? 'online'
                                          : 'offline'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _controller.isTyping.value
                                        ? AppColors.primary
                                        : isOnline
                                            ? AppColors.success
                                            : textHint,
                                    fontWeight: _controller.isTyping.value
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    fontStyle: _controller.isTyping.value
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                ),
                              ));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.call_outlined, color: textPrimary),
          onPressed: _makeCall,
        ),
        IconButton(
          icon: Icon(Icons.more_vert_rounded, color: textPrimary),
          onPressed: () => _showMenu(context),
        ),
      ],
    );
  }
}

// ─── Online Ring Avatar (AppBar) ──────────────────────────────────────────────

class _OnlineRingAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final String otherUserId;
  final ChatController controller;

  const _OnlineRingAvatar({
    required this.imageUrl,
    required this.name,
    required this.radius,
    required this.otherUserId,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: controller.watchOtherUserOnline(otherUserId),
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? false;
        return Container(
          width: radius * 2 + 4,
          height: radius * 2 + 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isOnline ? AppColors.success : Colors.transparent,
              width: 2,
            ),
          ),
          child: _ChatAvatar(imageUrl: imageUrl, name: name, radius: radius),
        );
      },
    );
  }
}

// ─── Empty Chat ───────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  final String name;
  final String? imageUrl;

  const _EmptyChat({required this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ChatAvatar(imageUrl: imageUrl, name: name, radius: 40),
          const SizedBox(height: 16),
          Text(name,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary)),
          const SizedBox(height: 8),
          Text('Say hi to ${name.split(' ')[0]}! 👋',
              style: TextStyle(fontSize: 14, color: textSecondary)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: AppRadius.large,
            ),
            child: const Text('Start a conversation',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ─── Message Row (with avatars) ───────────────────────────────────────────────

class _MessageRow extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final bool isLastInGroup;
  final bool isLastMessage;
  final String? myImage;
  final String myName;
  final String? otherImage;
  final String otherName;
  final int index;

  const _MessageRow({
    required this.message,
    required this.isMe,
    required this.isLastInGroup,
    required this.isLastMessage,
    required this.myImage,
    required this.myName,
    required this.otherImage,
    required this.otherName,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 250 + (index < 8 ? index * 25 : 0)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(isMe ? 20 * (1 - value) : -20 * (1 - value), 0),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: isMe ? _buildMyRow(context) : _buildOtherRow(context),
        ),
      ),
    );
  }

  List<Widget> _buildMyRow(BuildContext context) {
    return [
      // Bubble
      Flexible(
        child: _MessageBubble(
            message: message, isMe: true, isLastMessage: isLastMessage),
      ),
      const SizedBox(width: 8),
      // My avatar — show only for last message in group
      SizedBox(
        width: 32,
        child: isLastInGroup
            ? _ChatAvatar(imageUrl: myImage, name: myName, radius: 16)
            : const SizedBox(),
      ),
    ];
  }

  List<Widget> _buildOtherRow(BuildContext context) {
    return [
      // Other avatar — show only for last message in group
      SizedBox(
        width: 32,
        child: isLastInGroup
            ? _ChatAvatar(imageUrl: otherImage, name: otherName, radius: 16)
            : const SizedBox(),
      ),
      const SizedBox(width: 8),
      // Bubble
      Flexible(
        child:
            _MessageBubble(message: message, isMe: false, isLastMessage: false),
      ),
    ];
  }
}

// ─── Typing Indicator ─────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  final String name;
  final String? imageUrl;

  const _TypingIndicator({required this.name, this.imageUrl});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _dots;
  late final List<Animation<double>> _dotAnims;

  @override
  void initState() {
    super.initState();
    _dots = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _dotAnims = _dots
        .map((c) => Tween<double>(begin: 0, end: -6).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    // Stagger the dots
    for (int i = 0; i < _dots.length; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) _dots[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _dots) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceAlt =
        isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;

    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, right: 60),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _ChatAvatar(imageUrl: widget.imageUrl, name: widget.name, radius: 14),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: surfaceAlt,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _dotAnims[i],
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _dotAnims[i].value),
                    child: Container(
                      width: 7,
                      height: 7,
                      margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chat Avatar ──────────────────────────────────────────────────────────────

class _ChatAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;

  const _ChatAvatar({
    required this.imageUrl,
    required this.name,
    required this.radius,
  });

  String get _initial => name.isNotEmpty ? name.trim()[0].toUpperCase() : 'U';
  bool get _hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_hasImage) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (_, __) => _AvatarFallback(initial: _initial, radius: radius),
          errorWidget: (_, __, ___) =>
              _AvatarFallback(initial: _initial, radius: radius),
        ),
      );
    }
    return _AvatarFallback(initial: _initial, radius: radius);
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initial;
  final double radius;

  const _AvatarFallback({required this.initial, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: radius * 0.75,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final bool isLastMessage;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isLastMessage,
  });

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Sent bubble: soft mint in light mode, deep teal in dark mode.
    final sentBubble = isDark ? AppColors.primaryDark : AppColors.primarySoft;
    final receivedBubble =
        isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textHint = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;

    final bubble = Container(
      margin: EdgeInsets.only(
        top: 2,
        bottom: 2,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      padding: (message.type == MessageType.image ||
              message.type == MessageType.location)
          ? const EdgeInsets.all(3)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? sentBubble : receivedBubble,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildContent(context, textPrimary),
          if (message.type != MessageType.image &&
              message.type != MessageType.location) ...[
            const SizedBox(height: 4),
            _buildTimeSeen(context, textSecondary, textHint),
          ],
        ],
      ),
    );

    // Forward icon shown floating next to image messages (matches reference)
    if (message.type == MessageType.image) {
      final forwardBtn = _ForwardButton(background: receivedBubble, iconColor: textSecondary);
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isMe
            ? [forwardBtn, const SizedBox(width: 6), bubble]
            : [bubble, const SizedBox(width: 6), forwardBtn],
      );
    }

    return bubble;
  }

  Widget _buildTimeSeen(
      BuildContext context, Color textSecondary, Color textHint) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.sentAt),
          style: TextStyle(
            fontSize: 11,
            color: isMe ? textSecondary : textHint,
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.done_all_rounded,
            size: 14,
            color: message.isRead ? AppColors.primary : textHint,
          ),
        ],
      ],
    );
  }

  Widget _buildContent(BuildContext context, Color textPrimary) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.text ?? '',
          style: TextStyle(color: textPrimary, fontSize: 15, height: 1.4),
        );

      case MessageType.image:
        return Stack(
          children: [
            ClipRRect(
              borderRadius: AppRadius.medium,
              child: message.mediaUrl != null
                  ? CachedNetworkImage(
                      imageUrl: message.mediaUrl!,
                      width: 220,
                      height: 180,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 220,
                        height: 180,
                        color: AppColors.primarySoft,
                        child: const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 220,
                        height: 180,
                        color: AppColors.primarySoft,
                        child: const Icon(Icons.broken_image_rounded,
                            size: 40, color: AppColors.primary),
                      ),
                    )
                  : Container(
                      width: 220,
                      height: 180,
                      color: AppColors.primarySoft,
                      child: const Icon(Icons.image_rounded,
                          size: 48, color: AppColors.primary),
                    ),
            ),
            // Time overlay on image
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.sentAt),
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 3),
                      Icon(
                        Icons.done_all_rounded,
                        size: 13,
                        color: message.isRead
                            ? Colors.lightBlue.shade300
                            : Colors.white70,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );

      case MessageType.voice:
        return _VoicePlayer(
          durationSeconds: message.durationSeconds ?? 0,
          isMe: isMe,
          mediaUrl: message.mediaUrl,
        );

      case MessageType.location:
        if (message.latitude == null || message.longitude == null) {
          return Text('Location unavailable',
              style: TextStyle(color: textPrimary, fontSize: 14));
        }
        final point = LatLng(message.latitude!, message.longitude!);
        return GestureDetector(
          onTap: () async {
            final uri = Uri.parse(
                'https://www.google.com/maps/search/?api=1&query=${message.latitude},${message.longitude}');
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: AppRadius.medium,
                child: SizedBox(
                  width: 220,
                  height: 140,
                  child: IgnorePointer(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: point,
                        initialZoom: 15,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.smartstitch.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: point,
                              width: 36,
                              height: 36,
                              child: const Icon(Icons.location_on_rounded,
                                  color: Colors.red, size: 36),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('📍 Tap to open in Maps',
                      style: TextStyle(fontSize: 10, color: Colors.white)),
                ),
              ),
            ],
          ),
        );

      default:
        return Text(
          message.text ?? '',
          style: TextStyle(color: textPrimary, fontSize: 15),
        );
    }
  }
}

// ─── Forward Button (image messages) ──────────────────────────────────────────

class _ForwardButton extends StatelessWidget {
  final Color background;
  final Color iconColor;
  const _ForwardButton({required this.background, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(Icons.reply_rounded, size: 16, color: iconColor),
    );
  }
}

// ─── Voice Player ─────────────────────────────────────────────────────────────

class _VoicePlayer extends StatefulWidget {
  final int durationSeconds;
  final bool isMe;
  final String? mediaUrl;

  const _VoicePlayer({
    required this.durationSeconds,
    required this.isMe,
    this.mediaUrl,
  });

  @override
  State<_VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<_VoicePlayer>
    with SingleTickerProviderStateMixin {
  late final AudioPlayer _player;
  late final AnimationController _waveCtrl;
  final _isPlaying = false.obs;
  final _currentSecs = 0.obs;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _isPlaying.value = false;
        _waveCtrl.stop();
        _waveCtrl.reset();
        _currentSecs.value = 0;
        _player.seek(Duration.zero);
      }
    });

    _player.positionStream.listen((pos) {
      _currentSecs.value = pos.inSeconds;
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (widget.mediaUrl == null || widget.mediaUrl!.isEmpty) {
      Get.snackbar(
        'Error',
        'Audio file not available',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_isPlaying.value) {
      await _player.pause();
      _isPlaying.value = false;
      _waveCtrl.stop();
    } else {
      try {
        if (_player.processingState == ProcessingState.idle) {
          await _player.setUrl(widget.mediaUrl!);
        }
        await _player.play();
        _isPlaying.value = true;
        _waveCtrl.repeat(reverse: true);
      } catch (e) {
        Get.snackbar(
          'Error',
          'Could not play audio',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  String _fmt(int secs) {
    final m = secs ~/ 60;
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    const color = AppColors.primary;
    final barColor = AppColors.primary.withValues(alpha: 0.3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() => GestureDetector(
              onTap: _togglePlay,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _isPlaying.value
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_filled_rounded,
                  key: ValueKey(_isPlaying.value),
                  color: color,
                  size: 38,
                ),
              ),
            )),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: _waveCtrl,
              builder: (_, __) => Row(
                children: List.generate(14, (i) {
                  final h = _isPlaying.value
                      ? 4.0 +
                          9.0 *
                              (0.4 +
                                  0.6 *
                                      (i % 3 == 0
                                          ? _waveCtrl.value
                                          : i % 3 == 1
                                              ? (1 - _waveCtrl.value)
                                              : 0.6))
                      : 3.0 + (i % 4) * 2.5;
                  return Container(
                    width: 3,
                    height: h,
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 4),
            Obx(() {
              final elapsed = _currentSecs.value;
              final total = widget.durationSeconds;
              final remaining = (total - elapsed).clamp(0, total);
              return Text(
                _isPlaying.value ? _fmt(remaining) : _fmt(total),
                style: TextStyle(color: textSecondary, fontSize: 11),
              );
            }),
          ],
        ),
      ],
    );
  }
}

// ─── Input Bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatefulWidget {
  final TextEditingController textController;
  final RxBool isTypingLocal;
  final VoidCallback onSendText;
  final VoidCallback onPickImage;
  final VoidCallback onStartRecording;
  final VoidCallback? onShareLocation;

  const _InputBar({
    required this.textController,
    required this.isTypingLocal,
    required this.onSendText,
    required this.onPickImage,
    required this.onStartRecording,
    this.onShareLocation,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _showEmoji = false;
  final FocusNode _focusNode = FocusNode();

  void _toggleEmoji() {
    if (_showEmoji) {
      setState(() => _showEmoji = false);
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
      setState(() => _showEmoji = true);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceAlt =
        isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textHint = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 10,
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 10,
          ),
          decoration: BoxDecoration(
            color: surface,
            border: Border(top: BorderSide(color: border, width: 0.5)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, -2)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: surfaceAlt,
                    borderRadius: AppRadius.full,
                  ),
                  child: TextField(
                    controller: widget.textController,
                    focusNode: _focusNode,
                    maxLines: null,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(color: textPrimary),
                    onTap: () {
                      if (_showEmoji) setState(() => _showEmoji = false);
                    },
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: textHint),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: InputBorder.none,
                      prefixIcon: GestureDetector(
                        onTap: _toggleEmoji,
                        child: Icon(
                          _showEmoji
                              ? Icons.keyboard_alt_outlined
                              : Icons.emoji_emotions_outlined,
                          color: textHint,
                          size: 20,
                        ),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onShareLocation != null)
                            IconButton(
                              icon: Icon(Icons.location_on_outlined,
                                  color: textHint, size: 20),
                              onPressed: widget.onShareLocation,
                            ),
                          IconButton(
                            icon: Icon(Icons.camera_alt_outlined,
                                color: textHint, size: 20),
                            onPressed: widget.onPickImage,
                          ),
                        ],
                      ),
                    ),
                    onSubmitted: (_) => widget.onSendText(),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send / Mic button
              Obx(() => GestureDetector(
                    onTap: widget.isTypingLocal.value
                        ? widget.onSendText
                        : widget.onStartRecording,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.primary,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          widget.isTypingLocal.value
                              ? Icons.send_rounded
                              : Icons.mic_rounded,
                          key: ValueKey(widget.isTypingLocal.value),
                          color: Colors.white,
                          size: widget.isTypingLocal.value ? 20 : 22,
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),

        // Emoji panel
        Offstage(
          offstage: !_showEmoji,
          child: SizedBox(
            height: 260,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                final controller = widget.textController;
                final text = controller.text;
                final selection = controller.selection;
                final cursor = selection.start < 0 ? text.length : selection.start;
                final newText = text.replaceRange(cursor, cursor, emoji.emoji);
                controller.text = newText;
                controller.selection = TextSelection.collapsed(
                    offset: cursor + emoji.emoji.length);
              },
              config: Config(
                height: 260,
                emojiViewConfig: EmojiViewConfig(
                  columns: 8,
                  emojiSizeMax: 28,
                  backgroundColor:
                      isDark ? AppColors.darkSurface : AppColors.lightSurface,
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  backgroundColor:
                      isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Recording Bar ────────────────────────────────────────────────────────────

class _RecordingBar extends StatelessWidget {
  final int seconds;
  final VoidCallback onSend;
  final VoidCallback onCancel;

  const _RecordingBar(
      {required this.seconds, required this.onSend, required this.onCancel});

  String get _time {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: border, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
              onPressed: onCancel,
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.error),
          const SizedBox(width: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (_, v, __) => Opacity(
              opacity: v,
              child: const Icon(Icons.fiber_manual_record,
                  color: AppColors.error, size: 14),
            ),
          ),
          const SizedBox(width: 8),
          Text(_time,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
          const SizedBox(width: 8),
          Expanded(
              child: Text('Recording...',
                  style: TextStyle(fontSize: 13, color: textSecondary))),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: AppShadows.primary,
              ),
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Date Chip ────────────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final String label;
  const _DateChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadius.large,
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ─── Menu Item ────────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ??
        (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    return ListTile(
        leading: Icon(icon, color: c),
        title: Text(label, style: TextStyle(color: c)),
        onTap: onTap);
  }
}