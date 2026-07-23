import 'package:smartstitch/ai/models/ai_conversation.dart';

/// Abstract repository for AI conversation persistence.
abstract class AiRepository {
  Future<List<AiConversation>> getConversations(String userId);
  Future<AiConversation?> getConversation(String userId, String conversationId);
  Future<String> saveConversation(AiConversation conversation);
  Future<void> updateConversation(AiConversation conversation);
  Future<void> deleteConversation(String userId, String conversationId);
}
