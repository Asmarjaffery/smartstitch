import 'ai_intent.dart';

/// Detects user intent from message text using keyword matching.
/// Pattern matching is fast and free — Gemini is only called for reasoning/generation.
class IntentDetector {
  IntentDetector._();

  static AiIntent detect(String message) {
    final text = message.toLowerCase().trim();

    // ── Booking ───────────────────────────────────────────────────────────
    if (_matches(text, [
      'book', 'booking', 'appointment', 'schedule', 'reserve',
      'بکنگ', 'اپوائنٹمنٹ', 'buk', 'buking',
    ])) return AiIntent.booking;

    // ── Wallet / Balance ──────────────────────────────────────────────────
    if (_matches(text, [
      'wallet', 'balance', 'credit', 'debit', 'transaction', 'history',
      'بیلنس', 'والیٹ', 'walat', 'balanc',
    ])) return AiIntent.wallet;

    // ── Withdraw ──────────────────────────────────────────────────────────
    if (_matches(text, [
      'withdraw', 'withdrawal', 'payout', 'cash out', 'نکلوانا',
      'nikalna', 'withdr',
    ])) return AiIntent.withdraw;

    // ── Measurements ──────────────────────────────────────────────────────
    if (_matches(text, [
      'measurement', 'size', 'chest', 'waist', 'shoulder', 'height',
      'قد', 'سائز', 'ناپ', 'naap', 'size',
    ])) return AiIntent.measurements;

    // ── Payment ───────────────────────────────────────────────────────────
    if (_matches(text, [
      'pay', 'payment', 'paid', 'invoice', 'receipt', 'safepay',
      'ادائیگی', 'paisa', 'bhugtan',
    ])) return AiIntent.payment;

    // ── Refund ────────────────────────────────────────────────────────────
    if (_matches(text, [
      'refund', 'return', 'money back', 'cancel', 'واپسی', 'wapsi',
    ])) return AiIntent.refund;

    // ── Call Rider ───────────────────────────────────────────────────────
    if (_matches(text, [
      'call rider', 'rider ko call', 'phone rider', 'rider ka number',
      'call the rider', 'rider se baat', 'رائیڈر کو کال', 'rider ko phone',
      'rider ko contact', 'contact rider',
    ])) return AiIntent.callRider;

    // ── Delivery ─────────────────────────────────────────────────────────
    if (_matches(text, [
      'deliver', 'delivery', 'rider', 'dispatch', 'ڈلیوری', 'diliv',
    ])) return AiIntent.delivery;

    // ── Tracking ─────────────────────────────────────────────────────────
    if (_matches(text, [
      'track', 'status', 'where is', 'kahan', 'کہاں', 'order status',
    ])) return AiIntent.tracking;

    // ── Fabric recommendation ─────────────────────────────────────────────
    if (_matches(text, [
      'fabric', 'cloth', 'material', 'cotton', 'silk', 'linen', 'lawn',
      'کپڑا', 'kapra', 'fabric suggest',
    ])) return AiIntent.fabricRecommendation;

    // ── Design recommendation ─────────────────────────────────────────────
    if (_matches(text, [
      'design', 'style', 'pattern', 'embroidery', 'outfit', 'dress',
      'ڈیزائن', 'dizain', 'look',
    ])) return AiIntent.designRecommendation;

    // ── Translation ───────────────────────────────────────────────────────
    if (_matches(text, [
      'translate', 'ترجمہ', 'tarjuma', 'urdu mein', 'english mein',
      'in urdu', 'in english',
    ])) return AiIntent.translation;

    // ── Message / reply suggestion ────────────────────────────────────────
    if (_matches(text, [
      'reply', 'message', 'respond', 'write for me', 'suggest reply',
      'جواب', 'jawab', 'likhna',
    ])) return AiIntent.messageSuggestion;

    // ── Professional rewrite ──────────────────────────────────────────────
    if (_matches(text, [
      'professional', 'formal', 'rewrite', 'improve', 'grammar',
      'polite', 'پیشہ ورانہ', 'behtar',
    ])) return AiIntent.professionalReply;

    // ── Price estimate ────────────────────────────────────────────────────
    if (_matches(text, [
      'price', 'cost', 'fee', 'charge', 'estimate', 'how much',
      'قیمت', 'qeemat', 'kitna',
    ])) return AiIntent.priceEstimate;

    return AiIntent.generalConversation;
  }

  static bool _matches(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));
}
