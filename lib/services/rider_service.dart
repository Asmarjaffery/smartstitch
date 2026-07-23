import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartstitch/models/delivery_model.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:smartstitch/models/rider_model.dart';

/// Backing service for [RiderController].
/// Handles Firestore reads/writes for rider profile, online status,
/// location updates, delivery assignment, and OTP verification.
class RiderService {
  static final RiderService instance = RiderService._();
  RiderService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _riders =>
      _db.collection('riders');
  CollectionReference<Map<String, dynamic>> get _deliveries =>
      _db.collection('deliveries');

  // ─── Profile ──────────────────────────────────────────────────────────
  Stream<RiderModel> watchRiderProfile(String riderId) {
    return _riders.doc(riderId).snapshots().map((snap) {
      final data = snap.data() ?? {};
      // Make sure the id is always present even if the doc doesn't store it.
      return RiderModel.fromJson({...data, 'id': snap.id});
    });
  }

  // ─── Online / Offline ─────────────────────────────────────────────────
  Future<void> setOnline(String riderId) async {
    await _riders.doc(riderId).update({
      'isOnline': true,
      'lastOnlineAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> setOffline(String riderId) async {
    await _riders.doc(riderId).update({
      'isOnline': false,
      'lastOfflineAt': DateTime.now().toIso8601String(),
    });
  }

  // ─── Location ─────────────────────────────────────────────────────────
  Future<Position?> getCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> updateRiderLocation(
    String riderId,
    double latitude,
    double longitude,
  ) async {
    await _riders.doc(riderId).update({
      'currentLocation': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'locationUpdatedAt': DateTime.now().toIso8601String(),
    });
  }

  // ─── Delivery streams ─────────────────────────────────────────────────
  Stream<List<DeliveryModel>> watchAssignedDeliveries(String riderId) {
    return _deliveries
        .where('riderId', isEqualTo: riderId)
        .where('status', whereIn: [
          DeliveryStatus.assigned.name,
          DeliveryStatus.pickedUp.name,
          DeliveryStatus.onTheWay.name,
        ])
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => DeliveryModel.fromJson({...d.data(), 'id': d.id}))
            .toList());
  }

  Stream<List<DeliveryModel>> watchDeliveryHistory(String riderId) {
    return _deliveries
        .where('riderId', isEqualTo: riderId)
        .where('status', whereIn: [
          DeliveryStatus.delivered.name,
          DeliveryStatus.failed.name,
        ])
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => DeliveryModel.fromJson({...d.data(), 'id': d.id}))
            .toList());
  }

  // ─── Earnings ─────────────────────────────────────────────────────────
  Stream<Map<String, dynamic>> watchEarnings(String riderId) {
    return _riders.doc(riderId).snapshots().map((snap) {
      final data = snap.data() ?? {};
      return {
        'totalEarnings': (data['totalEarnings'] as num?)?.toDouble() ?? 0.0,
        'walletBalance': (data['walletBalance'] as num?)?.toDouble() ?? 0.0,
        'totalDeliveries': (data['totalDeliveries'] as num?)?.toInt() ?? 0,
      };
    });
  }

  // ─── Accept / Reject ──────────────────────────────────────────────────
  Future<void> acceptDelivery(String deliveryId) async {
    await _deliveries.doc(deliveryId).update({
      'status': DeliveryStatus.pickedUp.name,
      'acceptedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> rejectDelivery(String deliveryId, String riderId) async {
    await _deliveries.doc(deliveryId).update({
      'status': DeliveryStatus.failed.name,
      'rejectedBy': riderId,
      'rejectedAt': DateTime.now().toIso8601String(),
    });
  }

  // ─── Generic status update ────────────────────────────────────────────
  Future<void> updateDeliveryStatus(
    String deliveryId,
    DeliveryStatus status,
  ) async {
    final updates = <String, dynamic>{
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (status == DeliveryStatus.delivered) {
      updates['deliveredAt'] = DateTime.now().toIso8601String();
    }
    await _deliveries.doc(deliveryId).update(updates);
  }

  // ─── OTP verification ──────────────────────────────────────────────────
  Future<bool> verifyOtp(String deliveryId, String otp) async {
    final doc = await _deliveries.doc(deliveryId).get();
    final data = doc.data();
    final correctOtp = data?['otpCode'] as String?;

    if (correctOtp == null || correctOtp != otp) return false;

    await _deliveries.doc(deliveryId).update({
      'status': DeliveryStatus.delivered.name,
      'isOtpVerified': true,
      'deliveredAt': DateTime.now().toIso8601String(),
    });

    return true;
  }
}