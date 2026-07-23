import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message_model.dart';
import '../models/chat_room_model.dart';

class ChatService {
  static final ChatService instance = ChatService._internal();
  factory ChatService() => instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _cloudName = 'dc58vppqz';
  static const String _uploadPreset = 'smartstitch_profile';

  Timer? _typingTimer;

  void connectSocket(String userId) {}
  void disconnectSocket() {}
  void emitMessage(Map<String, dynamic> data) {}
  void emitTyping(String chatRoomId, bool isTyping) {}
  void listenToMessages(void Function(Map<String, dynamic>) onMessage) {}
  void listenToTyping(void Function(bool) onTyping) {}

  // ─────────────────────────────────────────────────────────────
  // USER CACHE WITH TTL (sirf current session ke liye)
  // ─────────────────────────────────────────────────────────────
  static const Duration _userCacheTtl = Duration(seconds: 15);
  final Map<String, Map<String, dynamic>> _userCache = {};
  final Map<String, DateTime> _userCacheTimestamps = {};

  /// Fetch user data from `users` collection (ja chat ke liye use hota hai)
  /// Ya fallback ke taur par `artists` se le sakta hai agar artist hai
  Future<Map<String, dynamic>> _fetchUser(String userId) async {
    final cachedAt = _userCacheTimestamps[userId];
    if (cachedAt != null &&
        DateTime.now().difference(cachedAt) < _userCacheTtl &&
        _userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }
    try {
      // Pehle `users` collection se try karo (primary source for chat)
      final userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        _userCache[userId] = userDoc.data()!;
        _userCacheTimestamps[userId] = DateTime.now();
        return userDoc.data()!;
      }

      // Agar `users` mein nahi mila, to `artists` collection se fetch karo
      // (in case artist's user doc sync ho gaya ho)
      final artistDoc =
          await _firestore.collection('artists').doc(userId).get();
      if (artistDoc.exists && artistDoc.data() != null) {
        final artistData = artistDoc.data()!;
        _userCache[userId] = artistData;
        _userCacheTimestamps[userId] = DateTime.now();
        return artistData;
      }
    } catch (_) {}
    return _userCache[userId] ?? {};
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ NEW: Sync user data between `artists` and `users` collections
  // ─────────────────────────────────────────────────────────────
  /// Call yeh jab bhi artist apni koi profile field update kare
  /// (name, profileImageUrl, bio, etc.)
  /// Yeh `users` collection ko bhi updated data de dega
  Future<void> syncArtistDataToUsersCollection({
    required String userId,
    required String? name,
    required String? profileImageUrl,
    String? bio,
    String? location,
  }) async {
    if (userId.isEmpty) return;

    try {
      // Pehle `users` doc check karo — agar na ho to create karo
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();

      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name;
      if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;
      if (bio != null) updateData['bio'] = bio;
      if (location != null) updateData['location'] = location;

      if (updateData.isEmpty) return;

      if (!userDoc.exists) {
        // Agar doc nahi hai, to naya banao base fields ke saath
        await userRef.set(
          {
            'name': name ?? 'User',
            'profileImageUrl': profileImageUrl ?? '',
            'bio': bio ?? '',
            'location': location ?? '',
            'isOnline': false,
            'createdAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          },
          SetOptions(merge: true),
        );
      } else {
        // Existing doc ko update karo
        await userRef.update({
          ...updateData,
          'updatedAt': Timestamp.now(),
        });
      }

      // Cache invalidate karo taake fresh data fetch ho agle call mein
      _userCacheTimestamps.remove(userId);
      _userCache.remove(userId);
    } catch (e) {
      print('syncArtistDataToUsersCollection error: $e');
    }
  }

  Future<ChatRoomModel> getOrCreateRoom(String myId, String otherId) async {
    if (myId.isEmpty || otherId.isEmpty) {
      throw Exception('getOrCreateRoom: myId or otherId is empty');
    }

    final snap = await _firestore
        .collection('chat_rooms')
        .where('participantIds', arrayContains: myId)
        .get();

    for (final doc in snap.docs) {
      final ids = List<String>.from(doc['participantIds'] as List? ?? []);
      if (ids.contains(otherId)) {
        final room = ChatRoomModel.fromJson({'id': doc.id, ...doc.data()});
        return await _enrichRoom(room, myId);
      }
    }

    final myData = await _fetchUser(myId);
    final otherData = await _fetchUser(otherId);

    final now = Timestamp.now();
    final ref = await _firestore.collection('chat_rooms').add({
      'participantIds': [myId, otherId],
      'participantNames': {
        myId: myData['name'] ?? myData['displayName'] ?? 'User',
        otherId: otherData['name'] ?? otherData['displayName'] ?? 'User',
      },
      'participantImages': {
        myId: myData['profileImageUrl'] ?? '',
        otherId: otherData['profileImageUrl'] ?? '',
      },
      'lastMessage': null,
      'unreadCount': 0,
      'typingUsers': {},
      'createdAt': now,
      'updatedAt': now,
    });

    final room = ChatRoomModel.fromJson({
      'id': ref.id,
      'participantIds': [myId, otherId],
      'participantNames': {
        myId: myData['name'] ?? myData['displayName'] ?? 'User',
        otherId: otherData['name'] ?? otherData['displayName'] ?? 'User',
      },
      'participantImages': {
        myId: myData['profileImageUrl'] ?? '',
        otherId: otherData['profileImageUrl'] ?? '',
      },
      'lastMessage': null,
      'unreadCount': 0,
      'createdAt': now,
      'updatedAt': now,
    });
    return await _enrichRoom(room, myId);
  }

  Future<ChatRoomModel> _enrichRoom(ChatRoomModel room, String myId) async {
    final otherUserId = room.participantIds.firstWhere(
      (id) => id != myId,
      orElse: () => '',
    );
    if (otherUserId.isEmpty) return room;

    final otherData = await _fetchUser(otherUserId);
    final myData = await _fetchUser(myId);
    final isOnline = otherData['isOnline'] as bool? ?? false;

    final names = Map<String, String>.from(room.participantNames);
    final images = Map<String, String>.from(room.participantImages);

    final otherName = otherData['name'] as String? ??
        otherData['displayName'] as String? ??
        'User';
    final myName =
        myData['name'] as String? ?? myData['displayName'] as String? ?? 'User';

    names[otherUserId] = otherName;
    names[myId] = myName;
    images[otherUserId] = otherData['profileImageUrl'] as String? ?? '';
    images[myId] = myData['profileImageUrl'] as String? ?? '';

    // Backfill old rooms jo Firestore mein participantNames nahi rakhte
    if (room.participantNames.isEmpty) {
      _firestore.collection('chat_rooms').doc(room.id).update({
        'participantNames': names,
        'participantImages': images,
      }).catchError((_) {});
    }

    return room.copyWith(
      otherUserName: otherName,
      otherUserImage: (images[otherUserId]?.isNotEmpty == true)
          ? images[otherUserId]
          : null,
      isOtherOnline: isOnline,
      participantNames: names,
      participantImages: images,
    );
  }

  Stream<List<ChatRoomModel>> watchRooms(String userId) {
    if (userId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('chat_rooms')
        .where('participantIds', arrayContains: userId)
        // .orderBy('updatedAt', descending: true) // index banne ke baad uncomment karna
        .snapshots()
        .asyncMap((snap) async {
      final List<ChatRoomModel> result = [];
      for (final doc in snap.docs) {
        try {
          final room = ChatRoomModel.fromJson({'id': doc.id, ...doc.data()});
          final enriched = await _enrichRoom(room, userId);
          result.add(enriched);
        } catch (_) {}
      }
      result.sort((a, b) {
        final aTime = a.lastMessageAt ?? a.updatedAt;
        final bTime = b.lastMessageAt ?? b.updatedAt;
        return bTime.compareTo(aTime);
      });
      return result;
    });
  }

  Stream<List<ChatMessageModel>> watchMessages(String chatRoomId) {
    if (chatRoomId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('sentAt')
        .snapshots(includeMetadataChanges: false)
        .map((snap) => snap.docs
            .map((d) {
              try {
                return ChatMessageModel.fromJson({'id': d.id, ...d.data()});
              } catch (_) {
                return null;
              }
            })
            .whereType<ChatMessageModel>()
            .toList());
  }

  Future<void> sendMessage(ChatMessageModel message) async {
    if (message.chatRoomId.isEmpty) {
      throw Exception('sendMessage: chatRoomId is empty');
    }
    if (message.senderId.isEmpty) {
      throw Exception('sendMessage: senderId is empty');
    }

    final now = Timestamp.now();

    final displayText = message.type.name == 'image'
        ? '📷 Photo'
        : message.type.name == 'voice'
            ? '🎤 Voice message'
            : message.type.name == 'location'
                ? '📍 Location'
                : message.text ?? '';

    final msgData = <String, dynamic>{
      'chatRoomId': message.chatRoomId,
      'senderId': message.senderId,
      'receiverId': message.receiverId,
      'type': message.type.name,
      'text': message.text,
      'mediaUrl': message.mediaUrl,
      'durationSeconds': message.durationSeconds,
      'latitude': message.latitude,
      'longitude': message.longitude,
      'isRead': false,
      'sentAt': now,
    };

    await _firestore
        .collection('chat_rooms')
        .doc(message.chatRoomId)
        .collection('messages')
        .add(msgData);

    await _firestore.collection('chat_rooms').doc(message.chatRoomId).update({
      'lastMessage': {
        'chatRoomId': message.chatRoomId,
        'senderId': message.senderId,
        'receiverId': message.receiverId,
        'type': message.type.name,
        'text': displayText,
        'mediaUrl': message.mediaUrl,
        'durationSeconds': message.durationSeconds,
        'latitude': message.latitude,
        'longitude': message.longitude,
        'isRead': false,
        'sentAt': now,
      },
      'updatedAt': now,
      'unreadCount': FieldValue.increment(1),
    });
  }

  Future<void> markAsRead(String chatRoomId, String myId) async {
    if (chatRoomId.isEmpty || myId.isEmpty) return;
    try {
      final unread = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('receiverId', isEqualTo: myId)
          .where('isRead', isEqualTo: false)
          .get();

      if (unread.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      batch.update(
        _firestore.collection('chat_rooms').doc(chatRoomId),
        {'unreadCount': 0},
      );
      await batch.commit();
    } catch (e) {
      print('markAsRead error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE CHAT ROOM (full delete — room + saari messages)
  // ─────────────────────────────────────────────────────────────

  Future<void> deleteChatRoom(String chatRoomId) async {
    if (chatRoomId.isEmpty) throw Exception('deleteChatRoom: chatRoomId empty');

    final roomRef = _firestore.collection('chat_rooms').doc(chatRoomId);

    // Firestore batch max 500 ops leti hai, isliye messages ko chunks mein delete karo
    while (true) {
      final snap = await roomRef.collection('messages').limit(400).get();
      if (snap.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snap.docs.length < 400) break;
    }

    // Room document delete karo
    await roomRef.delete();
  }

  Future<String> uploadImage(File file, String chatRoomId) async {
    if (chatRoomId.isEmpty) throw Exception('chatRoomId empty');
    final bytes = await file.readAsBytes();
    return await _uploadToCloudinary(bytes, 'image/jpeg');
  }

  Future<String> uploadImageBytes(Uint8List bytes, String chatRoomId) async {
    if (chatRoomId.isEmpty) throw Exception('chatRoomId empty');
    return await _uploadToCloudinary(bytes, 'image/jpeg');
  }

  Future<String> uploadVoiceNote(File file, String chatRoomId) async {
    if (chatRoomId.isEmpty) throw Exception('chatRoomId empty');
    final bytes = await file.readAsBytes();
    return await _uploadToCloudinary(bytes, 'audio/m4a', resourceType: 'auto');
  }

  Future<String> _uploadToCloudinary(
    Uint8List bytes,
    String contentType, {
    String resourceType = 'image',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload'),
    );

    request.fields['upload_preset'] = _uploadPreset;
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename:
            '${DateTime.now().millisecondsSinceEpoch}.${resourceType == 'auto' ? 'm4a' : 'jpg'}',
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['secure_url'] as String;
    } else {
      throw Exception(
          'Cloudinary upload failed: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> setOnline(String userId) async {
    if (userId.isEmpty) return;
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': true,
        'lastSeen': Timestamp.now(),
      });
    } catch (_) {}
  }

  Future<void> setOffline(String userId) async {
    if (userId.isEmpty) return;
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': false,
        'lastSeen': Timestamp.now(),
      });
    } catch (_) {}
  }

  Stream<bool> watchOnlineStatus(String userId) {
    if (userId.isEmpty) return Stream.value(false);
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?['isOnline'] as bool? ?? false)
        .handleError((_) => false);
  }

  Future<void> updateTypingStatus(
      String chatRoomId, String userId, bool isTyping) async {
    if (chatRoomId.isEmpty || userId.isEmpty) return;
    _typingTimer?.cancel();
    try {
      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'typingUsers.$userId': isTyping,
      });
    } catch (_) {
      return;
    }
    if (isTyping) {
      _typingTimer = Timer(const Duration(seconds: 5), () {
        _firestore
            .collection('chat_rooms')
            .doc(chatRoomId)
            .update({'typingUsers.$userId': false}).catchError((_) {});
      });
    }
  }

  Stream<bool> watchTypingStatus(String chatRoomId, String otherUserId) {
    if (chatRoomId.isEmpty || otherUserId.isEmpty) return Stream.value(false);
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .snapshots()
        .map((doc) {
      final typingUsers =
          doc.data()?['typingUsers'] as Map<String, dynamic>? ?? {};
      return typingUsers[otherUserId] as bool? ?? false;
    }).handleError((_) => false);
  }

  void dispose() {
    _typingTimer?.cancel();
  }
}