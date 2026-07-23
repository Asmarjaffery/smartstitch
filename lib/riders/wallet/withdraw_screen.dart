import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/riders/wallet/wallet_controller.dart';
import 'package:smartstitch/riders/wallet/withdraw_success_screen.dart';
import 'package:smartstitch/core/widgets/wallet_widgets.dart';
import 'package:smartstitch/core/widgets/card_input_widgets.dart';
import '../../models/wallet_models.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
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
    final ctrl = Get.find<WalletController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Withdraw Earnings',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: ctrl.withdrawFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── BALANCE CARD ──────────────────────────────
              Obx(() => _BalanceCard(balance: ctrl.availableBalance)),
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
                  ctrl.accountTitleController,
                  ctrl.expiryController,
                  ctrl.cvvController,
                ]),
                builder: (context, _) => AnimatedCardPreview(
                  number: ctrl.cardNumberController.text,
                  holder: ctrl.accountTitleController.text,
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
                decoration: cardFieldDecoration(context,
                    hint: 'Card Number', icon: Icons.credit_card_rounded),
                validator: (v) => ctrl.validateCardNumber(v),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Card Holder Name
              TextFormField(
                controller: ctrl.accountTitleController,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.colorScheme.onSurface),
                decoration: cardFieldDecoration(context,
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
                      decoration: cardFieldDecoration(context,
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
                      decoration: cardFieldDecoration(context,
                          hint: 'CVV', icon: Icons.lock_outline_rounded),
                      validator: ctrl.validateCvv,
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
                decoration: cardFieldDecoration(context,
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

  void _showConfirmSheet(BuildContext context, WalletController ctrl) {
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
        holder: ctrl.accountTitleController.text.trim(),
        maskedNumber: '**** **** **** $last4',
        onConfirm: () async {
          Get.back();
          final result = await ctrl.submitWithdrawal();
          if (result != null) Get.off(() => WithdrawSuccessScreen(request: result));
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// BALANCE CARD
// ══════════════════════════════════════════════════════════════

class _BalanceCard extends StatelessWidget {
  final double balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [WalletColors.teal900, WalletColors.teal700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: WalletColors.teal700.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available Balance',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white.withValues(alpha: 0.75), letterSpacing: 0.4)),
              const SizedBox(height: 6),
              Text('Rs. ${_fmt(balance)}',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)),
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
  final WalletController ctrl;
  const _AmountField({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: ctrl.amountController,
      keyboardType: TextInputType.number,
      style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        prefixText: 'Rs. ',
        prefixStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: WalletColors.teal700),
        hintText: '0',
        hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
        suffixText: 'Min: Rs. 500',
        suffixStyle: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: WalletColors.teal700, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: WalletColors.red, width: 1.5)),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WalletColors.amberBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WalletColors.amber.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: WalletColors.amber, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text('Withdrawals process within 1–2 business days. Minimum amount Rs. 500. Your card details are securely encrypted.',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: WalletColors.amberText, height: 1.5)),
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
    return Container(
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
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
              gradient: const LinearGradient(colors: [WalletColors.teal900, WalletColors.teal700], begin: Alignment.topLeft, end: Alignment.bottomRight),
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
              color: theme.cardColor,
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
                    backgroundColor: WalletColors.teal900,
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