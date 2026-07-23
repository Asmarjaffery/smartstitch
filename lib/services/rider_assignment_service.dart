import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartstitch/services/notification_service.dart';
import 'package:smartstitch/models/enums.dart';

/// Tracks rider assignment timeouts.
/// When admin assigns a rider, this service starts a 60s timer.
/// If the rider doesn't accept in time, the next rider in the list gets assigned.
class RiderAssignmentService {
  static final RiderAssignmentService instance = RiderAssignmentService._();
  RiderAssignmentService._();

  final _db = FirebaseFirestore.instance;

  // orderId → Timer (active timers)
  final Map<String, Timer> _timers = {};

  // orderId → attempted rider IDs (already tried for this order)
  final Map<String, List<String>> _triedRiders = {};

  // ─── Admin assigned a rider ─────────────────────────────────────────
  Future<void> assignRiderWithTimeout({
    required String orderId,
    required String riderId,
    required List<String> allRiderIds, // List of riders available to admin
  }) async {
    // Cancel any previous timer for this order
    _cancelTimer(orderId);

    // Add to tried list
    _triedRiders[orderId] = [...(_triedRiders[orderId] ?? []), riderId];

    // Firestore update: riderId + assignedAt + status = riderAssigned
    await _db.collection('bookings').doc(orderId).update({
      'riderId': riderId,
      'riderAssignedAt': DateTime.now().toIso8601String(),
      'riderStatus': 'pending', // rider hasn't accepted yet
      'status': 'riderAssigned',
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Send notification to rider
    await NotificationService.instance.sendNotification(
      recipientId: riderId,
      recipientRole: UserRole.rider,
      type: NotificationType.orderUpdate,
      title: 'New Delivery Request',
      body: 'You have a new delivery order. Accept within 60 seconds.',
      data: {'orderId': orderId},
    );

    debugPrint('60s timer started: orderId=$orderId, riderId=$riderId');

    // 60 second timer
    _timers[orderId] = Timer(const Duration(seconds: 60), () async {
      await _handleTimeout(
        orderId: orderId,
        failedRiderId: riderId,
        allRiderIds: allRiderIds,
      );
    });
  }

  // ─── Rider accepted → cancel timer ──────────────────────────
  Future<void> riderAccepted(String orderId) async {
    _cancelTimer(orderId);
    _triedRiders.remove(orderId);

    await _db.collection('bookings').doc(orderId).update({
      'riderStatus': 'accepted',
      'updatedAt': DateTime.now().toIso8601String(),
    });

    debugPrint('Rider accepted order: $orderId');
  }

  // ─── Timeout handler: assign the next rider ────────────────────────
  Future<void> _handleTimeout({
    required String orderId,
    required String failedRiderId,
    required List<String> allRiderIds,
  }) async {
    debugPrint('Timeout! Rider $failedRiderId did not accept: $orderId');

    // SAFETY CHECK: the rider may have already accepted
    // (on a different device/app instance), so the local Timer couldn't be
    // cancelled. Confirm the latest Firestore status before reassigning.
    final bookingDoc = await _db.collection('bookings').doc(orderId).get();
    final currentRiderStatus = bookingDoc.data()?['riderStatus'] as String?;

    if (currentRiderStatus != null && currentRiderStatus != 'pending') {
      // accepted / delivering / delivered — already handled, skip reassignment
      debugPrint(
          'Order $orderId is already "$currentRiderStatus" — skipping reassignment.');
      _cancelTimer(orderId);
      _triedRiders.remove(orderId);
      return;
    }

    final tried = _triedRiders[orderId] ?? [];

    // Riders not yet tried
    final remaining = allRiderIds.where((id) => !tried.contains(id)).toList();

    if (remaining.isEmpty) {
      // No riders left → alert admin
      debugPrint('No available riders: $orderId');
      await _db.collection('bookings').doc(orderId).update({
        'riderId': null,
        'riderStatus': 'noRiderAvailable',
        'status': 'stitchingCompleted', // revert to previous status
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Notify admin
      // If you have an admin ID in your system, send it here
      // NotificationService.instance.sendNotification(...)
      return;
    }

    // Next rider
    final nextRider = remaining.first;
    debugPrint('Assigning next rider: $nextRider → $orderId');

    await assignRiderWithTimeout(
      orderId: orderId,
      riderId: nextRider,
      allRiderIds: allRiderIds,
    );
  }

  // ─── Cancel timer ───────────────────────────────────────────────────────
  void _cancelTimer(String orderId) {
    _timers[orderId]?.cancel();
    _timers.remove(orderId);
  }

  // ─── Cleanup on app close ───────────────────────────────────────────────
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    _triedRiders.clear();
  }
}