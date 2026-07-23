import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstitch/ai/models/ai_conversation.dart';
import 'ai_repository.dart';

/// Firestore implementation.
/// Collection: ai_conversations/{userId}/sessions/{conversationId}
class AiRepositoryImpl implements AiRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _sessions(String userId) =>
      _db.collection('ai_conversations').doc(userId).collection('sessions');

  @override
  Future<List<AiConversation>> getConversations(String userId) async {
    try {
      final snap = await _sessions(userId)
          .orderBy('updatedAt', descending: true)
          .limit(50)
          .get();
      return snap.docs
          .map((d) => AiConversation.fromJson({...d.data(), 'id': d.id}))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<AiConversation?> getConversation(
      String userId, String conversationId) async {
    try {
      final doc = await _sessions(userId).doc(conversationId).get();
      if (!doc.exists) return null;
      return AiConversation.fromJson({...doc.data()!, 'id': doc.id});
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> saveConversation(AiConversation conversation) async {
    final ref = conversation.id.isEmpty
        ? _sessions(conversation.userId).doc()
        : _sessions(conversation.userId).doc(conversation.id);

    final json = conversation.toJson();
    json['updatedAt'] = FieldValue.serverTimestamp();
    await ref.set(json);
    return ref.id;
  }

  @override
  Future<void> updateConversation(AiConversation conversation) async {
    final json = conversation.toJson();
    json['updatedAt'] = FieldValue.serverTimestamp();
    await _sessions(conversation.userId).doc(conversation.id).update(json);
  }

  @override
  Future<void> deleteConversation(String userId, String conversationId) async {
    await _sessions(userId).doc(conversationId).delete();
  }
}
