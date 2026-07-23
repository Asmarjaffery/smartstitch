import 'dart:convert';
import 'package:http/http.dart' as http;

class BrevoService {
  static const String _apiKey =
      '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';
  static const String _apiUrl = 'https://api.brevo.com/v3/smtp/email';
  static const String _checkIconSvg = '''
    <svg width="40" height="40" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <circle cx="12" cy="12" r="10" fill="#6C3FE8"/>
      <path d="M8 12.5L10.5 15L16 9" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>
  ''';

  static Future<void> sendBookingConfirmation({
    required String toEmail,
    required String bookingId,
    required String serviceName,
    required String date,
    required String time,
    required String visitType,
    required String amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'api-key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "sender": {"name": "SmartStitch", "email": "asmarjaffery@gmail.com"},
          "to": [
            {"email": toEmail}
          ],
          "subject": "SmartStitch - Booking Confirmed",
          "htmlContent": """
            <div style="font-family:Arial;max-width:600px;margin:auto;padding:20px;
                        border:1px solid #eee;border-radius:10px;">
              <div style="text-align:center;margin-bottom:12px;">
                $_checkIconSvg
              </div>
              <h2 style="color:#6C3FE8;text-align:center;">Booking Confirmed</h2>
              <p>Thank you for your booking with SmartStitch.</p>
              <hr/>
              <p><b>Booking ID:</b> $bookingId</p>
              <p><b>Service:</b> $serviceName</p>
              <p><b>Date:</b> $date</p>
              <p><b>Time:</b> $time</p>
              <p><b>Visit Type:</b> $visitType</p>
              <p><b>Amount:</b> $amount</p>
              <hr/>
              <p style="color:#777;">Your artist will contact you soon.</p>
              <p style="color:#6C3FE8;font-weight:bold;">SmartStitch Team</p>
            </div>
          """,
        }),
      );

      if (response.statusCode == 201) {
        print('Brevo email sent successfully');
      } else {
        print('Brevo error: ${response.statusCode} — ${response.body}');
      }
    } catch (e) {
      print('BrevoService exception: $e');
    }
  }
}