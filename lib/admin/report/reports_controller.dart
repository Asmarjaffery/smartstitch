import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'web_downloader_stub.dart'
    if (dart.library.html) 'web_downloader_web.dart';

/// ---------------------------------------------------------------------
/// NOTE ON SCHEMA
/// ---------------------------------------------------------------------
/// Your Firestore only has two collections confirmed so far: `users` and
/// `bookings`. There is NO `orders`, `customers`, `artists`, `riders`,
/// `services`, `payments`, `withdrawals`, `reviews`, or `complaints`
/// collection. That mismatch was the actual reason every report except
/// nothing came back empty — the queries were hitting collections that
/// don't exist, or comparing a String date field against a Timestamp.
///
/// This version only enables report types backed by collections you've
/// confirmed exist. Give me the real collection names for
/// payments/withdrawals/reviews/complaints/services and I'll wire those
/// back in the same way.
/// ---------------------------------------------------------------------

enum ReportType {
  revenue,
  bookings,
  payments,
  customers,
  artists,
  riders,
  withdrawals,
  reviews,
  services,
}

enum DateFilter { today, last7, last30, custom }

class ReportTypeData {
  final ReportType type;
  final String title;
  final String icon;
  final String description;
  final List<String> columns;

  ReportTypeData({
    required this.type,
    required this.title,
    required this.icon,
    required this.description,
    required this.columns,
  });
}

class RecentReport {
  final String id;
  final String name;
  final String generatedBy;
  final DateTime generatedDate;
  final String fileSize;
  final String filePath;
  final String fileType;

  RecentReport({
    required this.id,
    required this.name,
    required this.generatedBy,
    required this.generatedDate,
    required this.fileSize,
    required this.filePath,
    required this.fileType,
  });

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  factory RecentReport.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return RecentReport(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      generatedBy: data['generatedBy']?.toString() ?? 'Admin',
      generatedDate: RecentReport._parseDate(data['generatedDate']),
      fileSize: data['fileSize']?.toString() ?? '0 KB',
      filePath: data['fileUrl']?.toString() ?? '',
      fileType: data['fileType']?.toString() ?? 'pdf',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'generatedBy': generatedBy,
      'generatedDate': Timestamp.fromDate(generatedDate),
      'fileSize': fileSize,
      'fileUrl': filePath,
      'fileType': fileType,
    };
  }
}

class ReportsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Rx<ReportType?> selectedReportType = Rx<ReportType?>(null);
  final Rx<DateFilter> selectedDateFilter = Rx<DateFilter>(DateFilter.last7);
  final Rx<DateTimeRange?> customDateRange = Rx<DateTimeRange?>(null);
  final RxBool isGenerating = false.obs;
  final RxBool isPreviewVisible = false.obs;
  final RxBool isLoadingRecent = false.obs;
  // NOTE: plain ValueNotifier, not RxList/.obs — see recentReports comment
  // above for why. Same "[Get] improper use of GetX" crash showed up here
  // too once recentReports was fixed, so applying the identical fix.
  final ValueNotifier<List<Map<String, dynamic>>> previewData =
      ValueNotifier<List<Map<String, dynamic>>>([]);
  // NOTE: This is a plain ValueNotifier, NOT an RxList/.obs. The Obx-based
  // version kept throwing "[Get] improper use of GetX" on this specific
  // widget no matter how the list was reassigned (.value =, assignAll()).
  // ValueNotifier + ValueListenableBuilder sidesteps GetX's internal
  // subscriber tracking entirely for this one piece of UI.
  final ValueNotifier<List<RecentReport>> recentReports =
      ValueNotifier<List<RecentReport>>([]);

  // Cache of userId -> {name, phone} so we don't refetch on every row.
  final Map<String, Map<String, String>> _userInfoCache = {};

  final List<ReportTypeData> reportTypes = [
    ReportTypeData(
      type: ReportType.revenue,
      title: 'Revenue Report',
      icon: 'attach_money',
      description: 'Financial breakdown per booking',
      columns: [
        'createdAt',
        'serviceTitle',
        'servicePrice',
        'deliveryFee',
        'artistAmount',
        'platformCommission',
        'totalAmount',
      ],
    ),
    ReportTypeData(
      type: ReportType.bookings,
      title: 'Bookings Report',
      icon: 'shopping_bag',
      description: 'Booking status, volume & trends',
      columns: [
        'id',
        'customerName',
        'artistName',
        'serviceTitle',
        'status',
        'paymentMethod',
        'totalAmount',
        'createdAt',
      ],
    ),
    ReportTypeData(
      type: ReportType.customers,
      title: 'Customers Report',
      icon: 'people',
      description: 'Customer signups & status',
      columns: ['name', 'email', 'phone', 'isBlocked', 'createdAt'],
    ),
    ReportTypeData(
      type: ReportType.artists,
      title: 'Artists Report',
      icon: 'palette',
      description: 'Artist signups & status',
      columns: ['name', 'email', 'phone', 'isBlocked', 'createdAt'],
    ),
    ReportTypeData(
      type: ReportType.riders,
      title: 'Riders Report',
      icon: 'two_wheeler',
      description: 'Delivery performance & earnings',
      columns: [
        'name',
        'phone',
        'vehicleType',
        'totalDeliveries',
        'rating',
        'totalEarnings',
        'isVerified',
        'joinedAt',
      ],
    ),
    ReportTypeData(
      type: ReportType.withdrawals,
      title: 'Withdrawals Report',
      icon: 'account_balance_wallet',
      description: 'Rider withdrawal requests & status',
      columns: [
        'riderName',
        'riderEmail',
        'amount',
        'paymentMethod',
        'status',
        'requestedAt',
        'processedAt',
      ],
    ),
    ReportTypeData(
      type: ReportType.payments,
      title: 'Payments Report',
      icon: 'payment',
      description: 'Payment methods & transaction amounts',
      columns: [
        'id',
        'customerName',
        'paymentMethod',
        'totalAmount',
        'status',
        'createdAt',
      ],
    ),
    ReportTypeData(
      type: ReportType.reviews,
      title: 'Reviews Report',
      icon: 'star',
      description: 'Customer ratings & feedback',
      columns: [
        'customerName',
        'artistName',
        'rating',
        'comment',
        'isVerifiedOrder',
        'createdAt',
      ],
    ),
    ReportTypeData(
      type: ReportType.services,
      title: 'Services Report',
      icon: 'design_services',
      description: 'Service catalog & pricing',
      columns: ['name', 'categoryName', 'price', 'description', 'createdAt'],
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    fetchRecentReports();
  }

  @override
  void onClose() {
    recentReports.dispose();
    previewData.dispose();
    super.onClose();
  }

  Map<String, dynamic> _safeMap(DocumentSnapshot doc) {
    return (doc.data() as Map<String, dynamic>?) ?? {};
  }

  Future<void> fetchRecentReports() async {
    isLoadingRecent.value = true;
    try {
      final snapshot = await _firestore
          .collection('generated_reports')
          .orderBy('generatedDate', descending: true)
          .limit(20)
          .get();

      recentReports.value =
          snapshot.docs.map((d) => RecentReport.fromDoc(d)).toList();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch recent reports: $e',
        backgroundColor: const Color(0xFFFFE4E4),
      );
    } finally {
      isLoadingRecent.value = false;
    }
  }

  Future<void> _saveRecentReportToFirestore(RecentReport report) async {
    try {
      await _firestore.collection('generated_reports').add(report.toMap());
    } catch (e) {
      Get.snackbar('Error', 'Failed to save report record: $e');
    }
  }

  DateTime get _rangeStart {
    final now = DateTime.now();
    switch (selectedDateFilter.value) {
      case DateFilter.today:
        return DateTime(now.year, now.month, now.day);
      case DateFilter.last7:
        return now.subtract(const Duration(days: 7));
      case DateFilter.last30:
        return now.subtract(const Duration(days: 30));
      case DateFilter.custom:
        return customDateRange.value?.start ??
            now.subtract(const Duration(days: 7));
    }
  }

  DateTime get _rangeEnd {
    return selectedDateFilter.value == DateFilter.custom
        ? (customDateRange.value?.end ?? DateTime.now())
        : DateTime.now();
  }

  void selectReportType(ReportType type) {
    selectedReportType.value = type;
    isPreviewVisible.value = false;
    previewData.value = [];
  }

  void selectDateFilter(DateFilter filter) {
    selectedDateFilter.value = filter;
  }

  void setCustomDateRange(DateTimeRange range) {
    customDateRange.value = range;
    selectedDateFilter.value = DateFilter.custom;
  }

  String get dateRangeLabel {
    switch (selectedDateFilter.value) {
      case DateFilter.today:
        return 'Today';
      case DateFilter.last7:
        return 'Last 7 Days';
      case DateFilter.last30:
        return 'Last 30 Days';
      case DateFilter.custom:
        if (customDateRange.value != null) {
          final df = DateFormat('MMM d, yyyy');
          return '${df.format(customDateRange.value!.start)} - ${df.format(customDateRange.value!.end)}';
        }
        return 'Custom Range';
    }
  }

  ReportTypeData? get currentReportData {
    if (selectedReportType.value == null) return null;
    return reportTypes
        .firstWhereOrNull((r) => r.type == selectedReportType.value);
  }

  String _formatHeader(String key) {
    if (key.isEmpty) return key;
    final spaced = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (m) => ' ${m.group(1)}',
    );
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  String _formatCellValue(dynamic value) {
    if (value == null) return '-';
    if (value is Timestamp) {
      return DateFormat('yyyy-MM-dd').format(value.toDate());
    }
    if (value is DateTime) return DateFormat('yyyy-MM-dd').format(value);
    if (value is double) return value.toStringAsFixed(2);
    if (value is num) return value.toString();
    if (value is bool) return value ? 'Yes' : 'No';
    return value.toString();
  }

  /// Your `createdAt` / `appointmentDate` fields are stored as ISO8601
  /// STRINGS, not Firestore Timestamps. ISO8601 strings still sort
  /// correctly with normal string comparison, so we filter/sort using
  /// string bounds instead of Timestamp.fromDate(). This is the fix for
  /// the "query always returns 0 docs" issue you were hitting.
  String _iso(DateTime d) => d.toIso8601String();

  /// Batch-resolve user display names for a set of IDs (Firestore
  /// `whereIn` supports max 10 values per query, so we chunk).
  Future<Map<String, String>> _resolveUserNames(Set<String> ids) async {
    final info = await _resolveUserInfo(ids);
    return info.map((id, data) => MapEntry(id, data['name'] ?? id));
  }

  /// Batch-resolve name + phone (+ anything else needed later) for a set
  /// of user IDs, chunked into groups of 10 for Firestore's `whereIn`
  /// limit. Cached so repeat lookups across report generations are free.
  Future<Map<String, Map<String, String>>> _resolveUserInfo(
      Set<String> ids) async {
    final result = <String, Map<String, String>>{};
    final toFetch = <String>[];

    for (final id in ids) {
      if (id.isEmpty) continue;
      if (_userInfoCache.containsKey(id)) {
        result[id] = _userInfoCache[id]!;
      } else {
        toFetch.add(id);
      }
    }

    for (var i = 0; i < toFetch.length; i += 10) {
      final chunk = toFetch.sublist(i, (i + 10).clamp(0, toFetch.length));
      final snap = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        final data = _safeMap(doc);
        final entry = {
          'name': data['name']?.toString() ?? doc.id,
          'phone': data['phone']?.toString() ?? '',
        };
        _userInfoCache[doc.id] = entry;
        result[doc.id] = entry;
      }
    }

    return result;
  }

  Future<List<List<String>>> _fetchBookingsRows() async {
    final cols =
        reportTypes.firstWhere((r) => r.type == ReportType.bookings).columns;

    final snapshot = await _firestore
        .collection('bookings')
        .where('createdAt', isGreaterThanOrEqualTo: _iso(_rangeStart))
        .where('createdAt', isLessThanOrEqualTo: _iso(_rangeEnd))
        .orderBy('createdAt', descending: true)
        .limit(500)
        .get();

    final customerIds = <String>{};
    final artistIds = <String>{};
    for (final doc in snapshot.docs) {
      final data = _safeMap(doc);
      if (data['customerId'] != null) customerIds.add(data['customerId']);
      if (data['artistId'] != null) artistIds.add(data['artistId']);
    }
    final names = await _resolveUserNames({...customerIds, ...artistIds});

    final headers = cols.map(_formatHeader).toList();
    final rows = <List<String>>[headers];

    for (final doc in snapshot.docs) {
      final data = _safeMap(doc);
      final row = cols.map((c) {
        switch (c) {
          case 'id':
            return doc.id;
          case 'customerName':
            return names[data['customerId']] ??
                data['customerId']?.toString() ??
                '-';
          case 'artistName':
            return names[data['artistId']] ??
                data['artistId']?.toString() ??
                '-';
          default:
            return _formatCellValue(data[c]);
        }
      }).toList();
      rows.add(row);
    }

    if (rows.length == 1) {
      rows.add(List.filled(headers.length, 'No data found'));
    }
    return rows;
  }

  Future<List<List<String>>> _fetchRevenueRows() async {
    final cols =
        reportTypes.firstWhere((r) => r.type == ReportType.revenue).columns;

    final snapshot = await _firestore
        .collection('bookings')
        .where('createdAt', isGreaterThanOrEqualTo: _iso(_rangeStart))
        .where('createdAt', isLessThanOrEqualTo: _iso(_rangeEnd))
        .orderBy('createdAt', descending: true)
        .limit(500)
        .get();

    final headers = cols.map(_formatHeader).toList();
    final rows = <List<String>>[headers];

    for (final doc in snapshot.docs) {
      final data = _safeMap(doc);
      rows.add(cols.map((c) => _formatCellValue(data[c])).toList());
    }

    if (rows.length == 1) {
      rows.add(List.filled(headers.length, 'No data found'));
    }
    return rows;
  }

  /// Customers / Artists / Riders all come from `users`, filtered by
  /// `role`. Adjust the role string below if your actual values differ
  /// (e.g. "Customer" vs "customer").
  /// Customers / Artists come from `users`, filtered by `role`.
  /// NOTE: unlike Revenue/Bookings, we deliberately do NOT apply the
  /// Date Range filter here. Customers/Artists are a roster of entities,
  /// not a log of events — filtering by signup date would exclude
  /// nearly everyone once your user base is more than a few days old.
  /// We show the full roster, most recently joined first.
  Future<List<List<String>>> _fetchUsersRowsByRole(
    ReportType type,
    String role,
  ) async {
    final cols = reportTypes.firstWhere((r) => r.type == type).columns;

    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .get();

    final docs = snapshot.docs.toList()
      ..sort((a, b) => (_safeMap(b)['createdAt'] ?? '')
          .toString()
          .compareTo((_safeMap(a)['createdAt'] ?? '').toString()));

    final headers = cols.map(_formatHeader).toList();
    final rows = <List<String>>[headers];

    for (final doc in docs) {
      final data = _safeMap(doc);
      rows.add(cols.map((c) => _formatCellValue(data[c])).toList());
    }

    if (rows.length == 1) {
      rows.add(List.filled(headers.length, 'No data found'));
    }
    return rows;
  }

  /// Riders live in their OWN `riders` collection (not `users` + role),
  /// with rider-specific fields like vehicleType/totalDeliveries/rating.
  /// Each rider doc links back to its `users` doc via `userId`, so we
  /// join in name/phone from there. Like Customers/Artists, this is a
  /// roster (not an event log), so we don't apply the Date Range filter
  /// — we show every rider, most recently joined first.
  Future<List<List<String>>> _fetchRidersRows() async {
    final cols =
        reportTypes.firstWhere((r) => r.type == ReportType.riders).columns;

    final snapshot = await _firestore.collection('riders').get();

    final docs = snapshot.docs.toList()
      ..sort((a, b) => (_safeMap(b)['joinedAt'] ?? '')
          .toString()
          .compareTo((_safeMap(a)['joinedAt'] ?? '').toString()));

    final userIds = docs
        .map((d) => _safeMap(d)['userId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final info = await _resolveUserInfo(userIds);

    final headers = cols.map(_formatHeader).toList();
    final rows = <List<String>>[headers];

    for (final doc in docs) {
      final data = _safeMap(doc);
      final userId = data['userId']?.toString() ?? '';
      final row = cols.map((c) {
        switch (c) {
          case 'name':
            return info[userId]?['name'] ?? userId;
          case 'phone':
            return info[userId]?['phone'] ?? '-';
          default:
            return _formatCellValue(data[c]);
        }
      }).toList();
      rows.add(row);
    }

    if (rows.length == 1) {
      rows.add(List.filled(headers.length, 'No data found'));
    }
    return rows;
  }

  /// Withdrawals come from `withdrawal_request`. Unlike bookings/users,
  /// this collection stores `requestedAt`/`processedAt` as REAL Firestore
  /// Timestamps (not ISO strings) — confirmed from your sample doc — so
  /// this one correctly uses Timestamp.fromDate() range queries, unlike
  /// the string-comparison approach used elsewhere in this file. This is
  /// a transactional/event-style report (like Revenue/Bookings), so the
  /// Date Range filter DOES apply here, filtered on `requestedAt`.
  Future<List<List<String>>> _fetchWithdrawalsRows() async {
    final cols =
        reportTypes.firstWhere((r) => r.type == ReportType.withdrawals).columns;

    final snapshot = await _firestore
        .collection('withdrawal_request')
        .where('requestedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_rangeStart))
        .where('requestedAt',
            isLessThanOrEqualTo: Timestamp.fromDate(_rangeEnd))
        .orderBy('requestedAt', descending: true)
        .limit(500)
        .get();

    final headers = cols.map(_formatHeader).toList();
    final rows = <List<String>>[headers];

    for (final doc in snapshot.docs) {
      final data = _safeMap(doc);
      rows.add(cols.map((c) => _formatCellValue(data[c])).toList());
    }

    if (rows.length == 1) {
      rows.add(List.filled(headers.length, 'No data found'));
    }
    return rows;
  }

  /// Payments has no dedicated collection — derived from `bookings`,
  /// same source/date-field format as Bookings Report, just surfacing
  /// the payment-relevant fields instead.
  Future<List<List<String>>> _fetchPaymentsRows() async {
    final cols =
        reportTypes.firstWhere((r) => r.type == ReportType.payments).columns;

    final snapshot = await _firestore
        .collection('bookings')
        .where('createdAt', isGreaterThanOrEqualTo: _iso(_rangeStart))
        .where('createdAt', isLessThanOrEqualTo: _iso(_rangeEnd))
        .orderBy('createdAt', descending: true)
        .limit(500)
        .get();

    final customerIds = <String>{};
    for (final doc in snapshot.docs) {
      final data = _safeMap(doc);
      if (data['customerId'] != null) customerIds.add(data['customerId']);
    }
    final names = await _resolveUserNames(customerIds);

    final headers = cols.map(_formatHeader).toList();
    final rows = <List<String>>[headers];

    for (final doc in snapshot.docs) {
      final data = _safeMap(doc);
      final row = cols.map((c) {
        switch (c) {
          case 'id':
            return doc.id;
          case 'customerName':
            return names[data['customerId']] ??
                data['customerId']?.toString() ??
                '-';
          default:
            return _formatCellValue(data[c]);
        }
      }).toList();
      rows.add(row);
    }

    if (rows.length == 1) {
      rows.add(List.filled(headers.length, 'No data found'));
    }
    return rows;
  }

  /// Reviews: `createdAt` is an ISO STRING here (confirmed from your
  /// sample doc), so this uses the string-comparison approach like
  /// Bookings/Revenue. `artistName` is already denormalized on the
  /// review doc, but `customerId` needs a join to `users` for a name.
  Future<List<List<String>>> _fetchReviewsRows() async {
    final cols =
        reportTypes.firstWhere((r) => r.type == ReportType.reviews).columns;

    final snapshot = await _firestore
        .collection('reviews')
        .where('createdAt', isGreaterThanOrEqualTo: _iso(_rangeStart))
        .where('createdAt', isLessThanOrEqualTo: _iso(_rangeEnd))
        .orderBy('createdAt', descending: true)
        .limit(500)
        .get();

    final customerIds = <String>{};
    for (final doc in snapshot.docs) {
      final data = _safeMap(doc);
      if (data['customerId'] != null) customerIds.add(data['customerId']);
    }
    final names = await _resolveUserNames(customerIds);

    final headers = cols.map(_formatHeader).toList();
    final rows = <List<String>>[headers];

    for (final doc in snapshot.docs) {
      final data = _safeMap(doc);
      final row = cols.map((c) {
        switch (c) {
          case 'customerName':
            return names[data['customerId']] ??
                data['customerId']?.toString() ??
                '-';
          default:
            return _formatCellValue(data[c]);
        }
      }).toList();
      rows.add(row);
    }

    if (rows.length == 1) {
      rows.add(List.filled(headers.length, 'No data found'));
    }
    return rows;
  }

  /// Services is a catalog, not an event log — like Customers/Artists/
  /// Riders, we show the full list regardless of Date Range, sorted
  /// most-recently-added first. `createdAt` here is a real Timestamp.
  Future<List<List<String>>> _fetchServicesRows() async {
    final cols =
        reportTypes.firstWhere((r) => r.type == ReportType.services).columns;

    final snapshot = await _firestore.collection('services').get();

    final docs = snapshot.docs.toList()
      ..sort((a, b) {
        final aTs = _safeMap(a)['createdAt'];
        final bTs = _safeMap(b)['createdAt'];
        final aDate = aTs is Timestamp ? aTs.toDate() : DateTime(1970);
        final bDate = bTs is Timestamp ? bTs.toDate() : DateTime(1970);
        return bDate.compareTo(aDate);
      });

    final headers = cols.map(_formatHeader).toList();
    final rows = <List<String>>[headers];

    for (final doc in docs) {
      final data = _safeMap(doc);
      rows.add(cols.map((c) => _formatCellValue(data[c])).toList());
    }

    if (rows.length == 1) {
      rows.add(List.filled(headers.length, 'No data found'));
    }
    return rows;
  }

  Future<List<List<String>>> _fetchReportRows(ReportType type) async {
    switch (type) {
      case ReportType.revenue:
        return _fetchRevenueRows();
      case ReportType.bookings:
        return _fetchBookingsRows();
      case ReportType.payments:
        return _fetchPaymentsRows();
      case ReportType.customers:
        return _fetchUsersRowsByRole(type, 'customer');
      case ReportType.artists:
        return _fetchUsersRowsByRole(type, 'artist');
      case ReportType.riders:
        return _fetchRidersRows();
      case ReportType.withdrawals:
        return _fetchWithdrawalsRows();
      case ReportType.reviews:
        return _fetchReviewsRows();
      case ReportType.services:
        return _fetchServicesRows();
    }
  }

  Future<void> generateReport() async {
    if (selectedReportType.value == null) {
      Get.snackbar(
        'Select Report',
        'Please select a report type first.',
        backgroundColor: const Color(0xFFFFE4E4),
      );
      return;
    }

    isGenerating.value = true;
    try {
      final rows = await _fetchReportRows(selectedReportType.value!);

      final headers = rows.first;
      final newData = <Map<String, dynamic>>[];
      for (var i = 1; i < rows.length; i++) {
        final map = <String, dynamic>{};
        for (var j = 0; j < headers.length; j++) {
          map[headers[j]] = rows[i][j];
        }
        newData.add(map);
      }
      previewData.value = newData;
      isPreviewVisible.value = true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate report: $e');
    } finally {
      isGenerating.value = false;
    }
  }

  Future<void> previewReport() async {
    if (selectedReportType.value == null) {
      Get.snackbar(
        'Select Report',
        'Please select a report type first.',
        backgroundColor: const Color(0xFFFFE4E4),
      );
      return;
    }

    if (previewData.value.isEmpty) {
      await generateReport();
      return;
    }

    isPreviewVisible.value = !isPreviewVisible.value;
  }

  Future<Uint8List> _buildPdfBytes() async {
    final reportData = currentReportData!;
    final rows = await _fetchReportRows(selectedReportType.value!);

    // NOTE: Using the default built-in font here (no custom Unicode font).
    // You'll still see the harmless "Helvetica has no Unicode support"
    // console warning for non-Latin characters, but it does NOT block PDF
    // generation. If you want a proper Unicode font later, bundle a .ttf
    // as a local asset (see chat) rather than fetching one over the
    // network — that network fetch is what caused the crash you just hit.
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'SmartStitch - ${reportData.title}',
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Text(
                'Generated on: ${DateFormat('MMM d, yyyy h:mm a').format(DateTime.now())}'),
            pw.Text('Date Range: $dateRangeLabel'),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: rows.first,
              data: rows.sublist(1),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF0E8F95),
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(6),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List?> _buildExcelBytes() async {
    final rows = await _fetchReportRows(selectedReportType.value!);
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet() ?? 'Sheet1'];

    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < rows[r].length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r),
        );
        cell.value = TextCellValue(rows[r][c]);
        if (r == 0) {
          cell.cellStyle = CellStyle(
            bold: true,
            backgroundColorHex: ExcelColor.fromHexString('#0E8F95'),
            fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
          );
        }
      }
    }

    final bytes = excel.encode();
    return bytes != null ? Uint8List.fromList(bytes) : null;
  }

  String _buildFileName(String extension) {
    final reportData = currentReportData!;
    return '${reportData.title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.$extension';
  }

  static const String _cloudinaryCloudName = 'dyqmhencs';
  static const String _cloudinaryUploadPreset = 'smartstitch_reports';

  Future<String> _uploadBytesToStorage(Uint8List bytes, String fileName) async {
    if (bytes.isEmpty) {
      throw Exception('Generated file is empty');
    }

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/raw/upload',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = _cloudinaryUploadPreset
      ..fields['public_id'] = fileName.split('.').first
      ..files
          .add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode != 200) {
      throw Exception(
          'Cloudinary upload failed (${streamedResponse.statusCode}): $responseBody');
    }

    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    final secureUrl = data['secure_url'] as String?;
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary response missing secure_url');
    }
    return secureUrl;
  }

  Future<void> downloadPdf() async {
    if (selectedReportType.value == null) return;
    isGenerating.value = true;
    try {
      final bytes = await _buildPdfBytes();
      if (bytes.isEmpty) {
        Get.snackbar('Error', 'Generated PDF is empty');
        return;
      }

      final fileName = _buildFileName('pdf');

      if (kIsWeb) {
        downloadBytesWeb(bytes, fileName);
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        await OpenFile.open(file.path);
      }

      // The file is already downloaded to the device at this point — that
      // part succeeded. Uploading a copy to Storage + logging it under
      // Recent Reports is a "nice to have" on top, NOT a requirement for
      // the download itself to count as successful. If Storage isn't set
      // up (or is slow/misconfigured), it must not hang the button forever
      // or hide the fact that the actual download worked.
      Get.snackbar(
        'Success',
        'PDF report downloaded successfully',
        backgroundColor: const Color(0xFFE6FCEB),
      );

      try {
        final url = await _uploadBytesToStorage(bytes, fileName)
            .timeout(const Duration(seconds: 20));
        await _addToRecentReportsFromBytes(bytes.length, 'pdf', url);
      } catch (e) {
        Get.snackbar(
          'Note',
          'Downloaded, but couldn\'t save to Recent Reports: $e',
          backgroundColor: const Color(0xFFFFF3CD),
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate PDF: $e');
    } finally {
      isGenerating.value = false;
    }
  }

  Future<void> downloadExcel() async {
    if (selectedReportType.value == null) return;
    isGenerating.value = true;
    try {
      final bytes = await _buildExcelBytes();
      if (bytes == null || bytes.isEmpty) {
        Get.snackbar('Error', 'Failed to encode Excel file');
        return;
      }

      final fileName = _buildFileName('xlsx');

      if (kIsWeb) {
        downloadBytesWeb(bytes, fileName);
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        await OpenFile.open(file.path);
      }

      // Same reasoning as downloadPdf(): local download already succeeded,
      // so that's reported immediately. Cloud upload/logging is best-effort
      // and time-boxed so it can never leave the UI stuck.
      Get.snackbar(
        'Success',
        'Excel report downloaded successfully',
        backgroundColor: const Color(0xFFE6FCEB),
      );

      try {
        final url = await _uploadBytesToStorage(bytes, fileName)
            .timeout(const Duration(seconds: 20));
        await _addToRecentReportsFromBytes(bytes.length, 'excel', url);
      } catch (e) {
        Get.snackbar(
          'Note',
          'Downloaded, but couldn\'t save to Recent Reports: $e',
          backgroundColor: const Color(0xFFFFF3CD),
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate Excel: $e');
    } finally {
      isGenerating.value = false;
    }
  }

  Future<void> printReport() async {
    if (selectedReportType.value == null) return;
    try {
      final bytes = await _buildPdfBytes();
      await Printing.layoutPdf(onLayout: (format) async => bytes);
    } catch (e) {
      Get.snackbar('Error', 'Failed to print report: $e');
    }
  }

  Future<void> shareReport() async {
    if (selectedReportType.value == null) return;
    try {
      final bytes = await _buildPdfBytes();
      final fileName = _buildFileName('pdf');

      if (kIsWeb) {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: '${currentReportData!.title} - SmartStitch Admin',
          ),
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to share report: $e');
    }
  }

  Future<void> _addToRecentReportsFromBytes(
    int byteLength,
    String type,
    String downloadUrl,
  ) async {
    final sizeStr = byteLength > 1024 * 1024
        ? '${(byteLength / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '${(byteLength / 1024).toStringAsFixed(0)} KB';

    final report = RecentReport(
      id: '',
      name: '${currentReportData!.title} - $dateRangeLabel',
      generatedBy: 'Admin (You)',
      generatedDate: DateTime.now(),
      fileSize: sizeStr,
      filePath: downloadUrl,
      fileType: type,
    );

    await _saveRecentReportToFirestore(report);
    await fetchRecentReports();
  }

  Future<void> downloadFromRecent(RecentReport report) async {
    if (report.filePath.isEmpty) {
      Get.snackbar('Unavailable', 'No file URL found for this report.');
      return;
    }

    try {
      final response = await http.get(Uri.parse(report.filePath));
      print('Status: ${response.statusCode}');
      print(
          'Body: ${response.body}'); // will show Cloudinary's error message if blocked
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        Get.snackbar('Error', 'Downloaded file is empty.');
        return;
      }

      final fileName = report.filePath.split('/').last;

      if (kIsWeb) {
        downloadBytesWeb(response.bodyBytes, fileName);
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final localFile = File('${dir.path}/$fileName');
        await localFile.writeAsBytes(response.bodyBytes, flush: true);
        await OpenFile.open(localFile.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to download report: $e');
    }
  }
}
