// ============================================================
// SmartStitch — Brevo Email Service (Wallet + Registration Emails)
//
// Shared by TWO different withdrawal flows:
//   • Artists — Stripe Connect only. Never pass accountTitle/accountNumber;
//     payout details live on Stripe, not in this app.
//   • Riders  — still manual bank/card details collected in-app, so they
//     DO pass accountTitle/accountNumber.
//
// accountTitle/accountNumber are therefore OPTIONAL (default ''), and the
// email body only renders those rows when a non-empty value is supplied.
//
// Registration emails (OTP + welcome) below are shared by BOTH Artists
// and Riders — pass role: 'Artist' or role: 'Rider' to personalize.
// ============================================================

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class WalletBrevoService {
  static const String _apiKey =
      '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';
  static const String _apiUrl = 'https://api.brevo.com/v3/smtp/email';
  static const String _senderEmail = 'asmarjaffery@gmail.com';
  static const String _senderName = 'SmartStitch';

  static Future<void> _sendEmail({
    required String toEmail,
    required String subject,
    required String htmlContent,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'api-key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'sender': {'name': _senderName, 'email': _senderEmail},
          'to': [
            {'email': toEmail}
          ],
          'subject': subject,
          'htmlContent': htmlContent,
        }),
      );

      if (response.statusCode == 201) {
        print('[Brevo] Email sent: $subject');
      } else {
        print('[Brevo] Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('[Brevo] Exception: $e');
    }
  }

  // ─── INLINE SVG ICONS ────────────────────────────────────
  // Email clients cannot render Flutter's Icons.* — these SVGs are the
  // equivalent for HTML email content, rendered inside a colored circle
  // badge to match the header banner style below.

  static String _iconBadge(String pathSvg) => '''
    <svg width="40" height="40" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      $pathSvg
    </svg>
  ''';

  static final String _lockIcon = _iconBadge('''
    <rect x="5" y="11" width="14" height="9" rx="2" fill="white"/>
    <path d="M8 11V7a4 4 0 018 0v4" stroke="white" stroke-width="2" fill="none"/>
    <circle cx="12" cy="15.5" r="1.5" fill="#0E8F95"/>
  ''');

  static final String _partyIcon = _iconBadge('''
    <circle cx="12" cy="12" r="10" fill="white"/>
    <path d="M8 12.5l2.5 2.5L16 9" stroke="#0E8F95" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  ''');

  static final String _mailIcon = _iconBadge('''
    <rect x="3" y="6" width="18" height="13" rx="2" fill="white"/>
    <path d="M3 7l9 6 9-6" stroke="#0E8F95" stroke-width="1.6" fill="none"/>
  ''');

  static final String _checkIcon = _iconBadge('''
    <circle cx="12" cy="12" r="10" fill="white"/>
    <path d="M7 12.5l3.2 3.2L17 9" stroke="#22C55E" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
  ''');

  static final String _moneyIcon = _iconBadge('''
    <circle cx="12" cy="12" r="10" fill="white"/>
    <path d="M12 6v12M9 9.5c0-1.5 1.3-2 3-2s3 .8 3 2-1.3 2-3 2-3 .8-3 2 1.3 2 3 2 3-.5 3-2" stroke="#0E8F95" stroke-width="1.5" fill="none" stroke-linecap="round"/>
  ''');

  static final String _xIcon = _iconBadge('''
    <circle cx="12" cy="12" r="10" fill="white"/>
    <path d="M8.5 8.5l7 7M15.5 8.5l-7 7" stroke="#EF4444" stroke-width="2.2" stroke-linecap="round"/>
  ''');

  static const String _clockGlyph = '''
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" style="vertical-align:middle;margin-right:6px;" xmlns="http://www.w3.org/2000/svg">
      <circle cx="12" cy="12" r="9" stroke="#92400E" stroke-width="2"/>
      <path d="M12 7v5l3 3" stroke="#92400E" stroke-width="2" stroke-linecap="round"/>
    </svg>
  ''';

  static const String _checkGlyphSmall = '''
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" style="vertical-align:middle;margin-right:6px;" xmlns="http://www.w3.org/2000/svg">
      <circle cx="12" cy="12" r="9" stroke="#15803D" stroke-width="2"/>
      <path d="M8 12.5l2.5 2.5L16 9.5" stroke="#15803D" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>
  ''';

  static const String _moneyGlyphSmall = '''
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" style="vertical-align:middle;margin-right:6px;" xmlns="http://www.w3.org/2000/svg">
      <circle cx="12" cy="12" r="9" stroke="#0369A1" stroke-width="2"/>
      <path d="M12 7v10M9.5 10c0-1 1-1.5 2.5-1.5s2.5.6 2.5 1.5-1 1.5-2.5 1.5-2.5.6-2.5 1.5 1 1.5 2.5 1.5" stroke="#0369A1" stroke-width="1.3" fill="none" stroke-linecap="round"/>
    </svg>
  ''';

  static const String _bulbGlyphSmall = '''
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" style="vertical-align:middle;margin-right:6px;" xmlns="http://www.w3.org/2000/svg">
      <path d="M9 18h6M10 21h4M12 3a6 6 0 00-3 11.2c.5.4.8 1 .8 1.8h4.4c0-.8.3-1.4.8-1.8A6 6 0 0012 3z" stroke="#92400E" stroke-width="1.6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>
  ''';

  // ─── EMAIL TEMPLATES ────────────────────────────────────

  static String _baseTemplate({
    required String iconBadge,
    required String headline,
    required String subheadline,
    required String bodyContent,
    required String footerNote,
  }) =>
      '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <title>SmartStitch</title>
      </head>
      <body style="margin:0;padding:0;background:#F0F4F8;font-family:'Segoe UI',Arial,sans-serif;">
        <table width="100%" cellpadding="0" cellspacing="0" style="background:#F0F4F8;padding:32px 16px;">
          <tr>
            <td align="center">
              <table width="100%" style="max-width:580px;background:#FFFFFF;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">
                <!-- Header -->
                <tr>
                  <td style="background:linear-gradient(135deg,#0E8F95,#35BFC4);padding:32px 40px;text-align:center;">
                    <div>$iconBadge</div>
                    <h1 style="color:#FFFFFF;font-size:22px;font-weight:700;margin:12px 0 4px;">$headline</h1>
                    <p style="color:rgba(255,255,255,0.85);font-size:14px;margin:0;">$subheadline</p>
                  </td>
                </tr>
                <!-- Body -->
                <tr>
                  <td style="padding:32px 40px;">
                    $bodyContent
                  </td>
                </tr>
                <!-- Footer -->
                <tr>
                  <td style="background:#F8FEFE;padding:20px 40px;border-top:1px solid #E6F8F8;text-align:center;">
                    <p style="color:#8DAFB1;font-size:12px;margin:0;">$footerNote</p>
                    <p style="color:#0E8F95;font-size:13px;font-weight:600;margin:8px 0 0;">SmartStitch Team</p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </body>
      </html>
      ''';

  static String _infoRow(String label, String value) => '''
    <tr>
      <td style="padding:8px 0;border-bottom:1px solid #F0FBFB;">
        <table width="100%">
          <tr>
            <td style="color:#4F7E80;font-size:13px;width:40%;">$label</td>
            <td style="color:#083C3F;font-size:13px;font-weight:600;text-align:right;">$value</td>
          </tr>
        </table>
      </td>
    </tr>
  ''';

  // ─── GENERATE A RANDOM 6-DIGIT OTP ───────────────────────
  //
  // Used for both Artist and Rider registration verification.

  static String generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // ─── REGISTRATION — EMAIL VERIFICATION (OTP) ────────────
  //
  // Shared by both Artists and Riders. Pass role: 'Artist' or
  // role: 'Rider' so the email is personalized correctly.
  // Sent right after the registration form is submitted; user
  // enters this code in-app to verify their email.

  static Future<void> sendRegistrationOtp({
    required String toEmail,
    required String fullName,
    required String otpCode,
    required String role, // 'Artist' or 'Rider'
    String validityMinutes = '10',
  }) async {
    final body = '''
      <p style="color:#4F7E80;font-size:14px;margin:0 0 20px;">Hi <strong style="color:#083C3F;">$fullName</strong>,</p>
      <p style="color:#4F7E80;font-size:14px;margin:0 0 24px;">Welcome to SmartStitch! Please use the verification code below to confirm your email address and finish setting up your $role account.</p>
      <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:24px;">
        <tr>
          <td align="center" style="padding:20px 0;">
            <div style="display:inline-block;background:#E6F8F8;border:2px dashed #0E8F95;border-radius:12px;padding:16px 32px;">
              <span style="color:#0E8F95;font-size:32px;font-weight:700;letter-spacing:8px;">$otpCode</span>
            </div>
          </td>
        </tr>
      </table>
      <div style="background:#FFF4D6;border-radius:12px;padding:16px;margin-bottom:8px;">
        <p style="color:#92400E;font-size:13px;margin:0;">
          $_clockGlyph This code is valid for $validityMinutes minutes. If you didn't request this, you can safely ignore this email.
        </p>
      </div>
    ''';

    await _sendEmail(
      toEmail: toEmail,
      subject: 'SmartStitch — Verify Your Email',
      htmlContent: _baseTemplate(
        iconBadge: _lockIcon,
        headline: 'Verify Your Email',
        subheadline: 'One quick step to activate your $role account',
        bodyContent: body,
        footerNote: 'Never share this code with anyone, including SmartStitch staff.',
      ),
    );
  }

  // ─── REGISTRATION — WELCOME (after successful verification) ─
  //
  // Shared by both Artists and Riders. Send once the OTP is
  // confirmed and the account is fully active.

  static Future<void> sendRegistrationWelcome({
    required String toEmail,
    required String fullName,
    required String role, // 'Artist' or 'Rider'
  }) async {
    final isArtist = role.toLowerCase() == 'artist';

    final body = '''
      <p style="color:#4F7E80;font-size:14px;margin:0 0 20px;">Hi <strong style="color:#083C3F;">$fullName</strong>,</p>
      <p style="color:#4F7E80;font-size:14px;margin:0 0 24px;">Your email has been verified and your <strong style="color:#0E8F95;">$role</strong> account is now active. Welcome to the SmartStitch community!</p>
      <div style="background:#E6F8F8;border-radius:12px;padding:16px;margin-bottom:8px;">
        <p style="color:#065F63;font-size:13px;margin:0;">
          ${isArtist ? 'You can now log in and start setting up your shop profile, business details, and specializations.' : 'You can now log in and start accepting delivery/pickup requests right away.'}
        </p>
      </div>
    ''';

    await _sendEmail(
      toEmail: toEmail,
      subject: 'SmartStitch — Welcome Aboard!',
      htmlContent: _baseTemplate(
        iconBadge: _partyIcon,
        headline: 'Welcome to SmartStitch!',
        subheadline: 'Your $role account is ready to go',
        bodyContent: body,
        footerNote: 'Excited to have you with us.',
      ),
    );
  }

  // ─── WITHDRAWAL REQUEST RECEIVED ────────────────────────
  //
  // accountTitle/accountNumber are optional: artists (Stripe-only) omit
  // them entirely, riders (manual bank details) still pass them. The
  // corresponding info rows only render when a value is actually given.

  static Future<void> sendWithdrawalRequested({
    required String toEmail,
    required String riderName,
    required String withdrawalId,
    required String amount,
    required String paymentMethod,
    required String requestedDate,
    String accountTitle = '',
    String accountNumber = '',
  }) async {
    final accountRows = (accountTitle.isNotEmpty || accountNumber.isNotEmpty)
        ? '''
          ${accountTitle.isNotEmpty ? _infoRow('Account Name', accountTitle) : ''}
          ${accountNumber.isNotEmpty ? _infoRow('Account Number', accountNumber) : ''}
        '''
        : '';

    final body = '''
      <p style="color:#4F7E80;font-size:14px;margin:0 0 20px;">Hi <strong style="color:#083C3F;">$riderName</strong>,</p>
      <p style="color:#4F7E80;font-size:14px;margin:0 0 24px;">Your withdrawal request has been received and is under review. Here are the details:</p>
      <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:24px;">
        ${_infoRow('Request ID', '#$withdrawalId')}
        ${_infoRow('Amount', 'Rs. $amount')}
        ${_infoRow('Payment Method', paymentMethod)}
        $accountRows
        ${_infoRow('Requested On', requestedDate)}
        ${_infoRow('Estimated Time', '1-2 Business Days')}
      </table>
      <div style="background:#E6F8F8;border-radius:12px;padding:16px;margin-bottom:8px;">
        <p style="color:#065F63;font-size:13px;margin:0;">
          $_clockGlyph Our team will review your request within 1-2 business days. You'll receive an email once your withdrawal is processed.
        </p>
      </div>
    ''';

    await _sendEmail(
      toEmail: toEmail,
      subject: 'SmartStitch — Withdrawal Request Received',
      htmlContent: _baseTemplate(
        iconBadge: _mailIcon,
        headline: 'Withdrawal Request Received',
        subheadline: 'We\'ve got your request and it\'s under review',
        bodyContent: body,
        footerNote:
            'If you didn\'t make this request, please contact support immediately.',
      ),
    );
  }

  // ─── WITHDRAWAL APPROVED ────────────────────────────────

  static Future<void> sendWithdrawalApproved({
    required String toEmail,
    required String riderName,
    required String withdrawalId,
    required String amount,
    required String paymentMethod,
    required String approvedDate,
  }) async {
    final body = '''
      <p style="color:#4F7E80;font-size:14px;margin:0 0 20px;">Hi <strong style="color:#083C3F;">$riderName</strong>,</p>
      <p style="color:#4F7E80;font-size:14px;margin:0 0 24px;">Great news! Your withdrawal request has been <strong style="color:#22C55E;">approved</strong> and is being processed.</p>
      <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:24px;">
        ${_infoRow('Request ID', '#$withdrawalId')}
        ${_infoRow('Amount', 'Rs. $amount')}
        ${_infoRow('Payment Method', paymentMethod)}
        ${_infoRow('Approved On', approvedDate)}
        ${_infoRow('Status', 'Approved')}
      </table>
      <div style="background:#DCFCE7;border-radius:12px;padding:16px;margin-bottom:8px;">
        <p style="color:#15803D;font-size:13px;margin:0;">
          $_checkGlyphSmall Your funds will be transferred to your account shortly. Transaction may take a few hours to reflect.
        </p>
      </div>
    ''';

    await _sendEmail(
      toEmail: toEmail,
      subject: 'SmartStitch — Withdrawal Approved',
      htmlContent: _baseTemplate(
        iconBadge: _checkIcon,
        headline: 'Withdrawal Approved!',
        subheadline: 'Your funds are on their way',
        bodyContent: body,
        footerNote: 'Thank you for riding with SmartStitch.',
      ),
    );
  }

  // ─── WITHDRAWAL PAID ────────────────────────────────────
  //
  // accountNumber is optional: artists (Stripe-only) omit it, riders
  // (manual bank details) still pass it. Row only renders when given.

  static Future<void> sendWithdrawalPaid({
    required String toEmail,
    required String riderName,
    required String withdrawalId,
    required String amount,
    required String paymentMethod,
    required String paidDate,
    String accountNumber = '',
  }) async {
    final body = '''
      <p style="color:#4F7E80;font-size:14px;margin:0 0 20px;">Hi <strong style="color:#083C3F;">$riderName</strong>,</p>
      <p style="color:#4F7E80;font-size:14px;margin:0 0 24px;">Your withdrawal has been <strong style="color:#0E8F95;">successfully paid</strong>. The funds have been transferred to your account.</p>
      <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:24px;">
        ${_infoRow('Transaction ID', '#$withdrawalId')}
        ${_infoRow('Amount Paid', 'Rs. $amount')}
        ${_infoRow('Payment Method', paymentMethod)}
        ${accountNumber.isNotEmpty ? _infoRow('Account Number', accountNumber) : ''}
        ${_infoRow('Paid On', paidDate)}
        ${_infoRow('Status', 'Paid')}
      </table>
      <div style="background:#E0F2FE;border-radius:12px;padding:16px;margin-bottom:8px;">
        <p style="color:#0369A1;font-size:13px;margin:0;">
          $_moneyGlyphSmall Please check your $paymentMethod account for the transaction. If you haven't received the funds, contact support.
        </p>
      </div>
    ''';

    await _sendEmail(
      toEmail: toEmail,
      subject: 'SmartStitch — Payment Successful',
      htmlContent: _baseTemplate(
        iconBadge: _moneyIcon,
        headline: 'Payment Successful!',
        subheadline: 'Rs. $amount has been transferred to your account',
        bodyContent: body,
        footerNote: 'Keep up the great work!',
      ),
    );
  }

  // ─── WITHDRAWAL REJECTED ────────────────────────────────

  static Future<void> sendWithdrawalRejected({
    required String toEmail,
    required String riderName,
    required String withdrawalId,
    required String amount,
    required String reason,
    required String rejectedDate,
  }) async {
    final body = '''
      <p style="color:#4F7E80;font-size:14px;margin:0 0 20px;">Hi <strong style="color:#083C3F;">$riderName</strong>,</p>
      <p style="color:#4F7E80;font-size:14px;margin:0 0 24px;">Unfortunately, your withdrawal request has been <strong style="color:#EF4444;">rejected</strong>. Don't worry — the amount has been refunded to your wallet balance.</p>
      <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:24px;">
        ${_infoRow('Request ID', '#$withdrawalId')}
        ${_infoRow('Amount', 'Rs. $amount')}
        ${_infoRow('Rejected On', rejectedDate)}
        ${_infoRow('Status', 'Rejected')}
      </table>
      <div style="background:#FEE2E2;border-radius:12px;padding:16px;margin-bottom:16px;">
        <p style="color:#B91C1C;font-size:13px;margin:0 0 6px;font-weight:600;">Reason:</p>
        <p style="color:#B91C1C;font-size:13px;margin:0;">$reason</p>
      </div>
      <div style="background:#FFF4D6;border-radius:12px;padding:16px;">
        <p style="color:#92400E;font-size:13px;margin:0;">
          $_bulbGlyphSmall The amount of Rs. $amount has been refunded to your available wallet balance. You can submit a new withdrawal request after resolving the issue.
        </p>
      </div>
    ''';

    await _sendEmail(
      toEmail: toEmail,
      subject: 'SmartStitch — Withdrawal Request Rejected',
      htmlContent: _baseTemplate(
        iconBadge: _xIcon,
        headline: 'Withdrawal Rejected',
        subheadline: 'Your balance has been refunded',
        bodyContent: body,
        footerNote:
            'Need help? Contact us at support@smartstitch.com',
      ),
    );
  }
}