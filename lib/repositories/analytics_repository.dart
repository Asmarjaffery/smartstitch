import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstitch/core/utils/bucket_helper.dart';
import 'package:smartstitch/core/utils/parser_helper.dart';
import '../models/analytics_metrics.dart';
import '../models/refund_metrics.dart';
import '../models/withdrawal_metrics.dart';

import '../services/analytics_service.dart';


class AnalyticsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<Map<String, dynamic>> streamPlatformSettings() {
    return _db.collection('settings').doc('platform').snapshots().map((snap) {
      return snap.data() ?? {};
    });
  }

  Stream<List<Map<String, dynamic>>> streamUsers() {
    return _db.collection('users').snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data();
        data['_docId'] = doc.id;
        return data;
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> streamOrders() {
    return _db.collection('orders').snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data();
        data['_docId'] = doc.id;
        return data;
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> streamBookings() {
    return _db.collection('bookings').snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data();
        data['totalAmount'] = ParserHelper.parseDouble(data['servicePrice']);
        data['_docId'] = doc.id;
        return data;
      }).toList();
    });
  }

  Stream<RefundMetrics> streamRefunds(DateTime start, DateTime end, BucketConfig bucketConfig) {
    return _db.collection('refunds').snapshots().map((snap) {
      double totalRefunds = 0.0;
      final trend = List<double>.filled(bucketConfig.bucketCount, 0.0);

      for (var doc in snap.docs) {
        final data = doc.data();
        final status = ParserHelper.parseString(data['status']).toLowerCase();
        final amount = ParserHelper.parseDouble(data['amount'] ?? data['refundAmount']);
        final createdAt = ParserHelper.parseDate(data['createdAt']);

        if (createdAt == null || createdAt.isBefore(start) || createdAt.isAfter(end)) {
          continue;
        }

        final isApproved = status == 'approved' || status == 'completed' || status == 'paid' || status == 'success';
        if (!isApproved) continue;

        totalRefunds += amount;
        final idx = bucketConfig.indexOf(createdAt);
        if (idx != -1) {
          trend[idx] += amount;
        }
      }

      return RefundMetrics(totalRefunds: totalRefunds, refundTrend: trend);
    });
  }

  Stream<WithdrawalMetrics> streamWithdrawals(DateTime start, DateTime end, BucketConfig bucketConfig) {
    return _db.collection('withdrawal_requests').snapshots().map((snap) {
      double totalWithdrawals = 0.0;
      final trend = List<double>.filled(bucketConfig.bucketCount, 0.0);

      for (var doc in snap.docs) {
        final data = doc.data();
        final status = ParserHelper.parseString(data['status']).toLowerCase();
        final amount = ParserHelper.parseDouble(data['amount']);
        final createdAt = ParserHelper.parseDate(data['createdAt']);

        if (createdAt == null || createdAt.isBefore(start) || createdAt.isAfter(end)) {
          continue;
        }

        final isApproved = status == 'approved' || status == 'completed' || status == 'success';
        if (!isApproved) continue;

        totalWithdrawals += amount;
        final idx = bucketConfig.indexOf(createdAt);
        if (idx != -1) {
          trend[idx] += amount;
        }
      }

      return WithdrawalMetrics(totalWithdrawals: totalWithdrawals, withdrawalTrend: trend);
    });
  }
}
