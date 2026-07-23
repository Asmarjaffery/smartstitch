/// Tracks a single AI assistant session in memory.
class AiSession {
  final String sessionId;
  final String userId;
  final String role;
  final DateTime startedAt;

  String language;
  DateTime lastActivity;
  String? conversationId;
  String? currentContext; // summary of last Firestore context fetch

  AiSession({
    required this.sessionId,
    required this.userId,
    required this.role,
    required this.startedAt,
    this.language = 'en',
    this.conversationId,
    this.currentContext,
  }) : lastActivity = startedAt;

  void touch() => lastActivity = DateTime.now();

  Duration get duration => DateTime.now().difference(startedAt);
}
