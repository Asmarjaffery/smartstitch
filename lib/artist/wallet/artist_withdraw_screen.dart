import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/artist/wallet/artist_wallet_controller.dart';
import 'package:smartstitch/artist/wallet/artist_withdraw_success_screen.dart';
import 'package:smartstitch/core/widgets/wallet_widgets.dart';
import 'package:smartstitch/core/widgets/card_input_widgets.dart';
import '../../models/artist_wallet_models.dart';

class ArtistWithdrawScreen extends StatefulWidget {
  const ArtistWithdrawScreen({super.key});

  @override
  State<ArtistWithdrawScreen> createState() => _ArtistWithdrawScreenState();
}

class _ArtistWithdrawScreenState extends State<ArtistWithdrawScreen> {
  final _cvvFocusNode = FocusNode();
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _cvvFocusNode.addListener(() {
      setState(() => _showBack = _cvvFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _cvvFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ArtistWalletController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? WalletColors.darkBg : WalletColors.lightBg,
      appBar: AppBar(
        title: const Text('Withdraw Earnings',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: isDark ? WalletColors.darkBg : WalletColors.lightBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: ctrl.withdrawFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── BALANCE CARD ──────────────────────────────
              Obx(() => _BalanceCard(
                    available: ctrl.availableBalance,
                    pending: ctrl.pendingWithdrawal,
                  )),
              const SizedBox(height: 28),

              // ─── WITHDRAWAL AMOUNT ─────────────────────────
              _SectionLabel(label: 'Withdrawal Amount'),
              const SizedBox(height: 10),
              _AmountField(ctrl: ctrl),
              const SizedBox(height: 32),

              // ─── CARD DETAILS SECTION ──────────────────────
              _SectionLabel(label: 'Card Details'),
              const SizedBox(height: 14),

              // Live animated card preview
              AnimatedBuilder(
                animation: Listenable.merge([
                  ctrl.cardNumberController,
                  ctrl.cardHolderController,
                  ctrl.expiryController,
                  ctrl.cvvController,
                ]),
                builder: (context, _) => AnimatedCardPreview(
                  number: ctrl.cardNumberController.text,
                  holder: ctrl.cardHolderController.text,
                  expiry: ctrl.expiryController.text,
                  cvv: ctrl.cvvController.text,
                  showBack: _showBack,
                ),
              ),
              const SizedBox(height: 20),

              // Card Number
              TextFormField(
                controller: ctrl.cardNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [CardNumberFormatter()],
                style: TextStyle(fontFamily: 'Poppins', fontSize: 15, color: theme.colorScheme.onSurface),
                decoration: _cardFieldDecoration(context,
                    hint: 'Card Number', icon: Icons.credit_card_rounded),
                validator: (v) => ctrl.validateCardNumber(v),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Cardholder Name
              TextFormField(
                controller: ctrl.cardHolderController,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.colorScheme.onSurface),
                decoration: _cardFieldDecoration(context,
                    hint: 'Cardholder Name', icon: Icons.person_outline_rounded),
                validator: ctrl.validateCardHolder,
              ),
              const SizedBox(height: 12),

              // Expiry & CVV
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: ctrl.expiryController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [ExpiryFormatter()],
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.colorScheme.onSurface),
                      decoration: _cardFieldDecoration(context,
                          hint: 'MM/YY', icon: Icons.calendar_today_rounded),
                      validator: ctrl.validateExpiry,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: ctrl.cvvController,
                      focusNode: _cvvFocusNode,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.colorScheme.onSurface),
                      decoration: _cardFieldDecoration(context,
                          hint: 'CVV', icon: Icons.lock_outline_rounded),
                      validator: ctrl.validateCardCvv,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Notes (optional)
              TextFormField(
                controller: ctrl.notesController,
                maxLines: 2,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.colorScheme.onSurface),
                decoration: _cardFieldDecoration(context,
                    hint: 'Notes (optional)', icon: Icons.notes_rounded),
              ),
              const SizedBox(height: 28),

              // Info Box
              _InfoBox(),
              const SizedBox(height: 28),

              // Submit Button
              Obx(() => PremiumButton(
                    label: 'Review & Submit',
                    icon: Icons.send_rounded,
                    isLoading: ctrl.isSubmittingWithdrawal.value,
                    onTap: () => _showConfirmSheet(context, ctrl),
                  )),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _cardFieldDecoration(
    BuildContext context, {
    required String hint,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
      ),
      prefixIcon: icon != null
          ? Icon(icon, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))
          : null,
      filled: true,
      fillColor: isDark ? WalletColors.cardDark : WalletColors.cardLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: WalletColors.primary.withValues(alpha: isDark ? 0.2 : 0.15),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: WalletColors.primary.withValues(alpha: isDark ? 0.2 : 0.15),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: WalletColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: WalletColors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _showConfirmSheet(BuildContext context, ArtistWalletController ctrl) {
    if (!(ctrl.withdrawFormKey.currentState?.validate() ?? false)) return;
    final amount = double.tryParse(ctrl.amountController.text.trim()) ?? 0;
    final brand = ctrl.detectedBrand;
    final digits = ctrl.cardNumberController.text.replaceAll(' ', '');
    final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : digits;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmBottomSheet(
        amount: amount,
        cardBrand: brand,
        holder: ctrl.cardHolderController.text.trim(),
        maskedNumber: '**** **** **** $last4',
        onConfirm: () async {
          Get.back();
          final result = await ctrl.submitWithdrawal();
          if (result != null) Get.off(() => ArtistWithdrawSuccessScreen(request: result));
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// BALANCE CARD
// ══════════════════════════════════════════════════════════════

class _BalanceCard extends StatelessWidget {
  final double available;
  final double pending;
  const _BalanceCard({required this.available, required this.pending});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [WalletColors.primaryDark, WalletColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: WalletColors.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available Balance',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white.withValues(alpha: 0.75), letterSpacing: 0.4)),
              const SizedBox(height: 6),
              Text('Rs. ${_fmt(available)}',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_top, size: 13, color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 6),
                    Text('Pending: Rs. ${_fmt(pending)}',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ══════════════════════════════════════════════════════════════
// SECTION LABEL
// ══════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(label,
      style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface));
}

// ══════════════════════════════════════════════════════════════
// AMOUNT FIELD
// ══════════════════════════════════════════════════════════════

class _AmountField extends StatelessWidget {
  final ArtistWalletController ctrl;
  const _AmountField({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return TextFormField(
      controller: ctrl.amountController,
      keyboardType: TextInputType.number,
      style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        prefixText: 'Rs. ',
        prefixStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: WalletColors.primary),
        hintText: '0',
        hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
        suffixText: 'Min: Rs. 500',
        suffixStyle: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
        filled: true,
        fillColor: isDark ? WalletColors.cardDark : WalletColors.cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: WalletColors.primary.withValues(alpha: isDark ? 0.2 : 0.15),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: WalletColors.primary.withValues(alpha: isDark ? 0.2 : 0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: WalletColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: WalletColors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      ),
      validator: ctrl.validateAmount,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// INFO BOX
// ══════════════════════════════════════════════════════════════

class _InfoBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WalletColors.primary.withValues(alpha: isDark ? 0.10 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: WalletColors.primary.withValues(alpha: isDark ? 0.25 : 0.15),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: WalletColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Withdrawals process within 1–2 business days. Minimum amount Rs. 500. Your card details are securely encrypted.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CONFIRM BOTTOM SHEET
// ══════════════════════════════════════════════════════════════

class _ConfirmBottomSheet extends StatelessWidget {
  final double amount;
  final CardBrand cardBrand;
  final String holder;
  final String maskedNumber;
  final VoidCallback onConfirm;

  const _ConfirmBottomSheet({
    required this.amount,
    required this.cardBrand,
    required this.holder,
    required this.maskedNumber,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? WalletColors.cardDark : WalletColors.lightBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.colorScheme.onSurface.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Text('Confirm Withdrawal', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text('Review your withdrawal details', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 24),

          // Amount Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [WalletColors.primaryDark, WalletColors.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('Withdrawal Amount', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 6),
                Text('Rs. ${amount.toStringAsFixed(0)}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Card Details Box
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? WalletColors.cardDark : theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                WalletDetailRow(icon: Icons.credit_card_rounded, label: 'Card Type', value: cardBrand.label),
                Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.12)),
                WalletDetailRow(icon: Icons.person_outline_rounded, label: 'Cardholder', value: holder),
                Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.12)),
                WalletDetailRow(icon: Icons.tag_rounded, label: 'Card Number', value: maskedNumber),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WalletColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Confirm', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}