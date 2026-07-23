import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:smartstitch/core/utils/helpers.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:universal_html/html.dart' as html;

class PdfService {
  static final PdfService instance = PdfService();
  PdfService();

  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<void> _loadFonts() async {
    if (_regular != null) return;
    final regularData = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Poppins-Bold.ttf');
    _regular = pw.Font.ttf(regularData);
    _bold = pw.Font.ttf(boldData);
  }

  Future<({File? file, Uint8List bytes, String fileName})> generateBookingPdf({
    required String bookingId,
    required String serviceTitle,
    required DateTime appointmentDate,
    required String timeSlot,
    required bool isHomeVisit,
    required PaymentMethod paymentMethod,
    required double servicePrice,
  }) async {
    try {
      await _loadFonts();

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: _regular!,
          bold: _bold!,
        ),
      );

      final shortId = bookingId.length >= 8
          ? bookingId.substring(0, 8).toUpperCase()
          : bookingId.toUpperCase();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'BOOKING CONFIRMATION',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'SmartStitch Services',
                          style: const pw.TextStyle(
                            fontSize: 16,
                            color: PdfColors.blue700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      'Booking ID: $shortId',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Booking Details',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      _row('Service', serviceTitle),
                      _row('Date', _formatDate(appointmentDate)),
                      _row('Time', timeSlot),
                      _row('Visit Type', isHomeVisit ? 'Home Visit' : 'Drop Off'),
                      _row('Payment Method', _paymentLabel(paymentMethod)),
                      _row('Price', 'Rs ${servicePrice.toInt()}'),
                    ],
                  ),
                  pw.SizedBox(height: 30),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      'Thank you for booking with SmartStitch!\nUse this Booking ID for future reference.',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      final bytes = await pdf.save();
      final fileName =
          'Booking_${shortId}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // ─── Web: trigger browser download ───────────────────────
      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        return (file: null, bytes: bytes, fileName: fileName);
      }

      // ─── Mobile: save to documents ───────────────────────────
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      return (file: file, bytes: bytes, fileName: fileName);
    } catch (e) {
      debugPrint('❌ PDF Error: $e');
      rethrow;
    }
  }

  Future<void> sharePdf({
    File? file,
    Uint8List? bytes,
    String? fileName,
  }) async {
    try {
      if (kIsWeb) {
        if (bytes == null) {
          AppHelpers.showError('No PDF data available.');
          return;
        }
        // Web pe share = download trigger
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName ?? 'booking_confirmation.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
        return;
      }

      if (file == null) {
        AppHelpers.showError('No PDF file found.');
        return;
      }

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Booking Confirmation - SmartStitch',
        subject: 'Booking Confirmation',
      );
    } catch (e) {
      debugPrint('❌ Share Error: $e');
      AppHelpers.showError('Failed to share PDF: $e');
    }
  }

  pw.TableRow _row(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _paymentLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.wallet:
        return 'Cash on Delivery';
      case PaymentMethod.jazzCash:
        return 'JazzCash';
      case PaymentMethod.easyPaisa:
        return 'EasyPaisa';
      case PaymentMethod.stripe:
        return 'Safepay';
      default:
        return '-';
    }
  }
}