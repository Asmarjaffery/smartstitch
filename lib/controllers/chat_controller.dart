import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartstitch/services/chat_service.dart';

import '../models/chat_message_model.dart';
import '../models/chat_room_model.dart';
import '../models/enums.dart';
import '../core/utils/helpers.dart';
import 'auth_controller.dart';

class ChatController extends GetxController {
  static ChatController get to => Get.find();

  final ChatService _chatService = ChatService.instance;
  final AudioRecorder _recorder = AudioRecorder();

  // ─── STREAM SUBSCRIPTIONS ────────────────────────────────────────────────
  StreamSubscription? _roomsSub;
  StreamSubscription? _messagesSub;
  StreamSubscription? _typingSub;

  // ─────────────────────────────────────────────────────────────
  // STATE
  // ─────────────────────────────────────────────────────────────

  final RxList<ChatRoomModel> rooms = <ChatRoomModel>[].obs;
  final RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;
  final RxBool isRecording = false.obs;
  final RxBool isTyping = false.obs;

  final RxString currentRoomId = ''.obs;
  final RxInt recordingSeconds = 0.obs;

  // ✅ TOTAL UNREAD COUNT
  final RxInt totalUnread = 0.obs;

  String get myId => AuthController.to.currentUserId ?? '';
// ─── MY PROFILE INFO ─────────────────────────────────────────────────────────
  String? get myProfileImage {
    return AuthController.to.currentUser.value?.profileImageUrl;
  }

  String get myName {
    return AuthController.to.currentUser.value?.name ?? 'Me';
  }
  // ─────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();

    if (myId.isNotEmpty) {
      _listenToRooms();
      _chatService.setOnline(myId);
    } else {
      ever(AuthController.to.currentUser, (user) {
        if (user != null && myId.isNotEmpty && _roomsSub == null) {
          _listenToRooms();
          _chatService.setOnline(myId);
        }
      });
    }
  }

  @override
  void onClose() {
    // FIX: cancel all stream subscriptions to avoid memory leaks
    _roomsSub?.cancel();
    _messagesSub?.cancel();
    _typingSub?.cancel();

    // FIX: clear typing status before closing
    _clearTypingStatus();

    if (myId.isNotEmpty) {
      _chatService.setOffline(myId);
    }

    _chatService.dispose();
    _recorder.dispose();

    super.onClose();
  }

  // ─────────────────────────────────────────────────────────────
  // ROOMS
  // ─────────────────────────────────────────────────────────────

  void _listenToRooms() {
    if (myId.isEmpty) return;

    _roomsSub?.cancel();
    _roomsSub = _chatService.watchRooms(myId).listen(
      (data) {
        rooms.value = data;
        totalUnread.value = data.fold(0, (sum, room) => sum + room.unreadCount);
      },
      onError: (_) {
        AppHelpers.showError('Failed to load chats');
      },
    );
  }

  // FIX: call this when leaving the chat screen
  Future<void> closeChat() async {
    await _clearTypingStatus();
    _messagesSub?.cancel();
    _typingSub?.cancel();
    messages.clear();
    isTyping.value = false;
  }

  // ─────────────────────────────────────────────────────────────
  // MESSAGES
  // ─────────────────────────────────────────────────────────────

  void _listenToMessages(String chatRoomId) {
    // FIX: cancel previous subscription before re-subscribing
    _messagesSub?.cancel();

    _messagesSub = _chatService.watchMessages(chatRoomId).listen(
      (data) {
        messages.value = data;
      },
      onError: (_) {
        AppHelpers.showError('Failed to load messages');
      },
    );
  }

  void _listenToTyping(String chatRoomId, String otherUserId) {
    // FIX: cancel previous subscription before re-subscribing
    _typingSub?.cancel();

    _typingSub = _chatService.watchTypingStatus(chatRoomId, otherUserId).listen(
      (typing) {
        isTyping.value = typing;
      },
      onError: (_) {
        isTyping.value = false;
      },
    );
  }

// chat_controller.dart mein yeh method add karo
  Future<void> openChat(String otherUserId) async {
    if (otherUserId.isEmpty) {
      AppHelpers.showError('Invalid user');
      return;
    }
    if (myId.isEmpty) {
      AppHelpers.showError('Not logged in');
      return;
    }

    try {
      isLoading.value = true;
      await _clearTypingStatus();

      final room = await _chatService.getOrCreateRoom(myId, otherUserId);
      final roomId = room.id;
      currentRoomId.value = roomId;

      _listenToMessages(roomId);
      _listenToTyping(roomId, otherUserId);
      _chatService.markAsRead(roomId, myId);
    } catch (e) {
      AppHelpers.showError('Could not open chat: $e');
    } finally {
      isLoading.value = false;
    }
  }
  // ─────────────────────────────────────────────────────────────
  // SEND TEXT MESSAGE
  // ─────────────────────────────────────────────────────────────

  Future<void> sendText(String text, String receiverId) async {
    if (text.trim().isEmpty) return;

    // FIX: capture roomId before any await — prevents race condition
    final roomId = currentRoomId.value;
    if (roomId.isEmpty) {
      AppHelpers.showError('Chat not ready, please wait');
      return;
    }

    try {
      isSending.value = true;

      await _chatService.sendMessage(
        ChatMessageModel(
          id: '',
          chatRoomId: roomId,
          senderId: myId,
          receiverId: receiverId,
          type: MessageType.text,
          text: text.trim(),
          sentAt: DateTime.now(),
        ),
      );
    } catch (e) {
      AppHelpers.showError('Failed to send message');
    } finally {
      isSending.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SEND IMAGE
  // ─────────────────────────────────────────────────────────────

  Future<void> sendImage(String receiverId) async {
    final roomId = currentRoomId.value;
    if (roomId.isEmpty) {
      AppHelpers.showError('Chat not ready, please wait');
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;

    try {
      isSending.value = true;
      // Web + Mobile dono ke liye bytes use karo
      final bytes = await picked.readAsBytes();
      final url = await _chatService.uploadImageBytes(bytes, roomId);

      await _chatService.sendMessage(ChatMessageModel(
        id: '',
        chatRoomId: roomId,
        senderId: myId,
        receiverId: receiverId,
        type: MessageType.image,
        mediaUrl: url,
        sentAt: DateTime.now(),
      ));
    } catch (e) {
      AppHelpers.showError('Failed to send image: $e');
    } finally {
      isSending.value = false;
    }
  }

  Future<void> sendImageFromBytes(
      Uint8List bytes, String receiverId, String url) async {
    final roomId = currentRoomId.value;
    if (roomId.isEmpty) return;
    await _chatService.sendMessage(ChatMessageModel(
      id: '',
      chatRoomId: roomId,
      senderId: myId,
      receiverId: receiverId,
      type: MessageType.image,
      mediaUrl: url,
      sentAt: DateTime.now(),
    ));
  }
  // ─────────────────────────────────────────────────────────────
  // RECORD VOICE
  // ─────────────────────────────────────────────────────────────

  Future<void> startRecording() async {
    // Web pe record package kaam nahi karta
    if (kIsWeb) {
      AppHelpers.showError('Voice notes are available in the mobile app');

      return;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      AppHelpers.showError('Microphone permission required');
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    isRecording.value = true;
    recordingSeconds.value = 0;
    _startRecordingTimer();
  }

  Future<void> stopAndSendVoice(String receiverId) async {
    // FIX: capture roomId before any await
    final roomId = currentRoomId.value;

    final path = await _recorder.stop();
    isRecording.value = false;

    if (path == null) return;

    if (roomId.isEmpty) {
      AppHelpers.showError('Chat not ready, please wait');
      return;
    }

    try {
      isSending.value = true;

      final url = await _chatService.uploadVoiceNote(File(path), roomId);

      await _chatService.sendMessage(
        ChatMessageModel(
          id: '',
          chatRoomId: roomId,
          senderId: myId,
          receiverId: receiverId,
          type: MessageType.voice,
          mediaUrl: url,
          durationSeconds: recordingSeconds.value,
          sentAt: DateTime.now(),
        ),
      );
    } catch (e) {
      AppHelpers.showError('Failed to send voice note');
    } finally {
      isSending.value = false;
    }
  }
// ─────────────────────────────────────────────────────────────
  // DELETE CHAT
  // ─────────────────────────────────────────────────────────────

 Future<bool> deleteChat() async {
    final roomId = currentRoomId.value;
    if (roomId.isEmpty) return false;

    try {
      _messagesSub?.cancel();      
      _typingSub?.cancel();       
      isTyping.value = false;     

      await _chatService.deleteChatRoom(roomId);

      messages.clear();
      rooms.removeWhere((r) => r.id == roomId);
      currentRoomId.value = '';
      return true;
    } catch (e) {
      return false;
    }
  }
  // ─────────────────────────────────────────────────────────────
  // SEND LOCATION
  // ─────────────────────────────────────────────────────────────

  Future<void> sendLocation(String receiverId) async {
    final roomId = currentRoomId.value;
    if (roomId.isEmpty) {
      AppHelpers.showError('Chat not ready, please wait');
      return;
    }

    try {
      // Location service on hai ya nahi check karo
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppHelpers.showError('Please enable location services');
        return;
      }

      // Permission check
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppHelpers.showError('Location permission denied');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        AppHelpers.showError(
            'Location permission permanently denied. Enable it from settings.');
        return;
      }

      isSending.value = true;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _chatService.sendMessage(
        ChatMessageModel(
          id: '',
          chatRoomId: roomId,
          senderId: myId,
          receiverId: receiverId,
          type: MessageType.location,
          latitude: position.latitude,
          longitude: position.longitude,
          sentAt: DateTime.now(),
        ),
      );
    } catch (e) {
      AppHelpers.showError('Failed to share location');
    } finally {
      isSending.value = false;
    }
  }

  Future<void> cancelRecording() async {
    await _recorder.cancel();
    isRecording.value = false;
    recordingSeconds.value = 0;
  }

  void _startRecordingTimer() async {
    while (isRecording.value) {
      await Future.delayed(const Duration(seconds: 1));
      if (isRecording.value) {
        recordingSeconds.value++;
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // TYPING STATUS
  // ─────────────────────────────────────────────────────────────

  void onTypingChanged(String text) {
    final roomId = currentRoomId.value;
    if (roomId.isEmpty) return;

    _chatService.updateTypingStatus(roomId, myId, text.isNotEmpty);
  }

  // FIX: clear typing status — call on dispose and on chat switch
  Future<void> _clearTypingStatus() async {
    final roomId = currentRoomId.value;
    if (roomId.isEmpty || myId.isEmpty) return;
    await _chatService.updateTypingStatus(roomId, myId, false);
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────

  String getOtherUserId(ChatRoomModel room) {
    return room.participantIds.firstWhere(
      (id) => id != myId,
      orElse: () => '',
    );
  }

  Stream<bool> watchOtherUserOnline(String otherUserId) {
    return _chatService.watchOnlineStatus(otherUserId);
  }

  String getOtherUserName(ChatRoomModel room) {
    final otherId = getOtherUserId(room);
    if (room.participantNames.containsKey(otherId)) {
      return room.participantNames[otherId] ?? 'User';
    }
    return room.otherUserName ?? 'User';
  }

  String? getOtherUserImage(ChatRoomModel room) {
    final otherId = getOtherUserId(room);
    if (room.participantImages.containsKey(otherId)) {
      final img = room.participantImages[otherId];
      return (img != null && img.isNotEmpty) ? img : null;
    }
    final img = room.otherUserImage;
    return (img != null && img.isNotEmpty) ? img : null;
  }
}
