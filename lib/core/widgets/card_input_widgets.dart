import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartstitch/core/widgets/wallet_widgets.dart';

// ═══════════════════════════════════════════════════════════
// CARD BRAND DETECTION
// ═══════════════════════════════════════════════════════════

enum CardBrand { visa, mastercard, amex, discover, unknown }

CardBrand detectCardBrand(String number) {
  final n = number.replaceAll(' ', '');
  if (n.isEmpty) return CardBrand.unknown;
  if (RegExp(r'^4').hasMatch(n)) return CardBrand.visa;
  if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(n)) return CardBrand.mastercard;
  if (RegExp(r'^3[47]').hasMatch(n)) return CardBrand.amex;
  if (RegExp(r'^(6011|65)').hasMatch(n)) return CardBrand.discover;
  return CardBrand.unknown;
}

extension CardBrandX on CardBrand {
  String get label {
    switch (this) {
      case CardBrand.visa:
        return 'Visa';
      case CardBrand.mastercard:
        return 'Mastercard';
      case CardBrand.amex:
        return 'American Express';
      case CardBrand.discover:
        return 'Discover';
      case CardBrand.unknown:
        return 'Card';
    }
  }

  int get cvvLength => this == CardBrand.amex ? 4 : 3;

  List<Color> get gradient {
    switch (this) {
      case CardBrand.visa:
        return const [Color(0xFF1A1F71), Color(0xFF3B4CC0)];
      case CardBrand.mastercard:
        return const [Color(0xFF6B2C0E), Color(0xFFEB5C1F)];
      case CardBrand.amex:
        return const [Color(0xFF0B3B60), Color(0xFF1F6FA6)];
      case CardBrand.discover:
        return const [Color(0xFF7A3B00), Color(0xFFFF8C1A)];
      case CardBrand.unknown:
        return const [Color(0xFF064E52), Color(0xFF0E8F95)];
    }
  }
}

// ═══════════════════════════════════════════════════════════
// REAL VALIDATION LOGIC (Luhn algorithm + expiry + CVV)
// ═══════════════════════════════════════════════════════════

class CardValidators {
  CardValidators._();

  /// Standard Luhn (mod-10) algorithm — same check real card networks use.
  static bool luhnCheck(String number) {
    int sum = 0;
    bool alternate = false;
    for (int i = number.length - 1; i >= 0; i--) {
      int n = int.parse(number[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  static String? cardNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Card number required karein';
    }
    final digits = value.replaceAll(' ', '');
    if (!RegExp(r'^[0-9]+$').hasMatch(digits)) return 'Sirf digits allowed hain';
    if (digits.length < 13 || digits.length > 19) return 'Invalid card number length';
    if (!luhnCheck(digits)) return 'Card number invalid hai';
    return null;
  }

  static String? cardHolderName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Card holder name required';
    if (value.trim().length < 3) return 'Naam bohot chota hai';
    if (!RegExp(r'^[a-zA-Z\s.]+$').hasMatch(value.trim())) {
      return 'Sirf letters allowed hain';
    }
    return null;
  }

  static String? expiry(String? value) {
    if (value == null || value.trim().isEmpty) return 'Expiry required hai';
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(value.trim());
    if (match == null) return 'Format MM/YY hona chahiye';
    final month = int.parse(match.group(1)!);
    final year = int.parse('20${match.group(2)!}');
    if (month < 1 || month > 12) return 'Invalid month';
    final now = DateTime.now();
    final expiryEnd = DateTime(year, month + 1, 0);
    if (expiryEnd.isBefore(DateTime(now.year, now.month, now.day))) {
      return 'Card expire ho chuka hai';
    }
    return null;
  }

  static String? cvv(String? value, CardBrand brand) {
    if (value == null || value.trim().isEmpty) return 'CVV required hai';
    final expected = brand.cvvLength;
    if (value.trim().length != expected) return '$expected digits CVV chahiye';
    if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) return 'Sirf digits allowed hain';
    return null;
  }
}

// ═══════════════════════════════════════════════════════════
// INPUT FORMATTERS
// ═══════════════════════════════════════════════════════════

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    if (digits.length > 19) return oldValue;
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i + 1) % 4 == 0 && i != digits.length - 1) buffer.write(' ');
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length > 4) return oldValue;
    String text = digits;
    if (digits.length >= 3) {
      text = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ANIMATED CARD PREVIEW (flips to show CVV on back)
// ═══════════════════════════════════════════════════════════

class AnimatedCardPreview extends StatelessWidget {
  final String number;
  final String holder;
  final String expiry;
  final String cvv;
  final bool showBack;

  const AnimatedCardPreview({
    super.key,
    required this.number,
    required this.holder,
    required this.expiry,
    required this.cvv,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    final brand = detectCardBrand(number);
    final displayNumber = number.isEmpty
        ? '•••• •••• •••• ••••'
        : number.padRight(19, '•');

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) {
        // ✅ FIX: the child that is ENTERING must always finish the
        // animation at rotation 0 (fully readable / not mirrored).
        // Previously the front card animated 0 → π, so it settled
        // fully flipped (mirrored) as soon as the animation finished —
        // including on first build, which is what caused the card to
        // always render backwards.
        final rotate = Tween(begin: 3.1416, end: 0.0).animate(anim);
        return AnimatedBuilder(
          animation: rotate,
          child: child,
          builder: (context, c) => Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(rotate.value),
            alignment: Alignment.center,
            child: c,
          ),
        );
      },
      child: showBack
          ? _CardBack(key: const ValueKey('back'), brand: brand, cvv: cvv)
          : _CardFront(
              key: const ValueKey('front'),
              brand: brand,
              number: displayNumber,
              holder: holder.isEmpty ? 'CARD HOLDER NAME' : holder.toUpperCase(),
              expiry: expiry.isEmpty ? 'MM/YY' : expiry,
            ),
    );
  }
}

class _CardFront extends StatelessWidget {
  final CardBrand brand;
  final String number;
  final String holder;
  final String expiry;
  const _CardFront({
    super.key,
    required this.brand,
    required this.number,
    required this.holder,
    required this.expiry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: brand.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: brand.gradient.last.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFE8D48A), Color(0xFFC9A94E)]),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Text(brand.label,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ],
          ),
          const Spacer(),
          Text(number,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2)),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CARD HOLDER',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 9)),
                    const SizedBox(height: 3),
                    Text(holder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('EXPIRES',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 9)),
                  const SizedBox(height: 3),
                  Text(expiry,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  final CardBrand brand;
  final String cvv;
  const _CardBack({super.key, required this.brand, required this.cvv});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: brand.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: brand.gradient.last.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 22),
          Container(height: 42, color: Colors.black.withValues(alpha: 0.75)),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 46,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(cvv.isEmpty ? '•••' : cvv,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SHARED FIELD DECORATION
// ═══════════════════════════════════════════════════════════

InputDecoration cardFieldDecoration(
  BuildContext context, {
  required String hint,
  IconData? icon,
  String? suffixText,
}) {
  final theme = Theme.of(context);
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
    prefixIcon: icon != null
        ? Icon(icon, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))
        : null,
    suffixText: suffixText,
    filled: true,
    fillColor: theme.cardColor,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2))),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2))),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: WalletColors.teal700, width: 1.5)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: WalletColors.red, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}