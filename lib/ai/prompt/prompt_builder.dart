import 'package:smartstitch/models/enums.dart';

/// Builds role-specific system prompts for Gemini.
/// All prompts are versioned here — never hardcoded in widgets or controllers.
class PromptBuilder {
  PromptBuilder._();

  static const _version = 'v1';

  /// Build the system prompt for a given role and Firestore context summary.
  static String build({
    required UserRole role,
    required String language,
    required String contextSummary,
  }) {
    final langInstruction = _languageInstruction(language);
    final rolePrompt = _rolePrompt(role);

    return '''
[$_version] You are an intelligent AI assistant for SmartStitch — a premium AI-powered tailoring marketplace in Pakistan.

$langInstruction

$rolePrompt

--- CURRENT USER CONTEXT ---
$contextSummary
----------------------------

IMPORTANT RULES:
- Never fabricate data. Only use facts from the context above.
- If context doesn\'t have the answer, say so honestly.
- Keep responses concise and helpful.
- Format using Markdown where appropriate (bold, lists).
- Never expose other users\' private data.
- Never bypass security or payment flows.
''';
  }

  static String _languageInstruction(String language) {
    switch (language) {
      case 'ur':
        return 'Always respond in Urdu (اردو). Use proper Urdu script.';
      case 'roman_ur':
        return 'Always respond in Roman Urdu (e.g. "Aap ka booking confirm ho gaya"). '
            'Do not use Urdu script — only English letters.';
      default:
        return 'Respond in English by default. '
            'If the user writes in Urdu or Roman Urdu, automatically match their language.';
    }
  }

  static String _rolePrompt(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return '''
You are the SmartStitch Customer Assistant. Help customers with:
- Booking status, confirmation, and cancellation
- Payment and refund queries
- Wallet balance and transactions
- Body measurements and AI scanner guidance
- Fabric and design recommendations
- Order tracking and delivery updates
- Complaint submission guidance
- Message drafting and translation
- General tailoring advice
''';
      case UserRole.artist:
        return '''
You are the SmartStitch Artist Assistant. Help tailoring artists with:
- Assigned orders and deadlines
- Measurement guidance and clarification
- Earnings and wallet questions
- Withdrawal requests and status
- Fabric and design suggestions
- Customer reply drafting (professional tone)
- Price estimation for custom orders
- Rating and review insights
- Production time planning
''';
      case UserRole.rider:
        return '''
You are the SmartStitch Rider Assistant. Help delivery riders with:
- Current assigned deliveries
- Pickup and drop-off instructions
- ETA estimation and route guidance
- Delivery status update guidance
- Customer or artist message drafting
- Earnings and wallet queries
- Complaint reporting
''';
      case UserRole.admin:
        return '''
You are the SmartStitch Admin Intelligence Assistant. Help platform administrators with:
- Revenue and financial analytics
- Booking trends and statistics
- User, artist, and rider management insights
- Withdrawal request review
- Fraud and anomaly detection
- Platform growth analysis
- Report generation guidance
- Notification and alert management
Only use data from the provided context. Never fabricate platform metrics.
''';
    }
  }

  /// Suggested starter questions per role
  static List<String> suggestedQuestions(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return [
          'What is my latest booking status?',
          'How much is in my wallet?',
          'Suggest a fabric for summer kurta',
          'Help me write a message to my tailor',
          'What are my saved measurements?',
        ];
      case UserRole.artist:
        return [
          'Show me my pending orders',
          'How much have I earned this month?',
          'Help me reply professionally to a customer',
          'What is my current wallet balance?',
        ];
      case UserRole.rider:
        return [
          'What deliveries am I assigned today?',
          'How much have I earned this week?',
          'Help me write a message to the customer',
          'What is the pickup address for my current delivery?',
        ];
      case UserRole.admin:
        return [
          'What is today\'s total revenue?',
          'How many bookings are pending?',
          'Show top earning artist this month',
          'Any pending withdrawal requests?',
          'How many new users joined today?',
        ];
    }
  }
}
