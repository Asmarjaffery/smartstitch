import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/models/artist_model.dart';
import 'package:smartstitch/models/body_measurement_model.dart';
import 'package:smartstitch/models/booking_model.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:smartstitch/models/service_model.dart';
import 'package:smartstitch/models/address_model.dart';
import 'package:smartstitch/core/utils/helpers.dart';
import 'package:smartstitch/services/brevo_service.dart';
import 'package:smartstitch/services/firebase_service.dart';
import 'package:smartstitch/services/notification_service.dart';
import 'package:smartstitch/services/strip_service.dart';
import 'package:smartstitch/user/booking/booking_confirm_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingController extends GetxController {
  static BookingController get to => Get.find();

  final FirebaseService _firebaseService = FirebaseService();
  final ImagePicker _picker = ImagePicker();

  final RxList<ServiceModel> services = <ServiceModel>[].obs;
  final RxList<ServiceModel> filteredServices = <ServiceModel>[].obs;
  final RxList<BookingModel> myBookings = <BookingModel>[].obs;
  final Rx<ServiceModel?> selectedService = Rx<ServiceModel?>(null);
  final Rx<AddressModel?> selectedAddress = Rx<AddressModel?>(null);
  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);
  final RxString selectedTimeSlot = ''.obs;
  final RxBool isHomeVisit = false.obs;
  final RxString designImageUrl = ''.obs;
  final RxString specialInstructions = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isUploadingImage = false.obs;
  final RxString selectedArtistId = ''.obs;
  final RxString selectedArtistCategoryId = ''.obs;
  final Rx<ArtistModel?> selectedArtist = Rx<ArtistModel?>(null);
  final Rx<BodyMeasurementModel?> selectedMeasurement =
      Rx<BodyMeasurementModel?>(null);
  final Rx<PaymentMethod> selectedPaymentMethod =
      Rx<PaymentMethod>(PaymentMethod.wallet);
  final RxBool uploadFailed = false.obs;

  final Rx<BookingModel?> lastBooking = Rx<BookingModel?>(null);

  final List<String> timeSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
  ];

  @override
  void onInit() {
    super.onInit();
    loadMyBookings();

    final artistId = Get.parameters['artistId'];
    final categoryId = Get.parameters['categoryId'];

    if (artistId != null && artistId.isNotEmpty) {
      if (selectedArtist.value == null) {
        setArtist(artistId, categoryId ?? '');
      }
    }
  }

  void setArtistDirectly(ArtistModel artist) {
    selectedArtistId.value = artist.id;
    selectedArtist.value = artist;
    selectedArtistCategoryId.value = '';
    loadServicesForArtist(artist.id);
  }

  Future<void> loadServicesForArtist(String artistId) async {
    try {
      isLoading.value = true;
      final snapshot = await _firebaseService.firestore
          .collection('services')
          .where('artistId', isEqualTo: artistId)
          .get();

      services.value = snapshot.docs
          .map((doc) => ServiceModel.fromJson({...doc.data(), 'id': doc.id}))
          .where((s) => s.status == 'published')
          .toList();

      _applyFilter();
    } catch (e) {
      AppHelpers.showError('Failed to load services.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setArtist(String artistId, String categoryId) async {
    selectedArtistId.value = artistId;
    selectedArtistCategoryId.value = categoryId;
    await _fetchArtist(artistId);
    await loadServicesForArtist(artistId);
  }

  Future<void> _fetchArtist(String artistId) async {
    try {
      final artistDoc = await _firebaseService.firestore
          .collection('artists')
          .doc(artistId)
          .get();

      if (artistDoc.exists) {
        var artistData = {...artistDoc.data()!};

        if (artistData['shopAddress'] == null ||
            artistData['shopAddress'] is! Map) {
          try {
            final userDoc = await _firebaseService.firestore
                .collection('users')
                .doc(artistId)
                .get();

            if (userDoc.exists) {
              final addresses = userDoc.data()?['addresses'] as List?;
              if (addresses != null && addresses.isNotEmpty) {
                final firstAddr = addresses.first;
                if (firstAddr is Map) {
                  artistData['shopAddress'] = {
                    'id': _safeString(firstAddr['id']),
                    'label':
                        _safeString(firstAddr['label'], defaultVal: 'Shop'),
                    'fullAddress': _safeString(firstAddr['fullAddress']),
                    'city': _safeString(firstAddr['city']),
                    'province': _safeString(firstAddr['province']),
                    'latitude': _safeDouble(firstAddr['latitude']),
                    'longitude': _safeDouble(firstAddr['longitude']),
                    'isDefault': firstAddr['isDefault'] is bool
                        ? firstAddr['isDefault']
                        : false,
                  };
                }
              }
            }
          } catch (_) {}
        }

        selectedArtist.value = ArtistModel.fromJson({
          ...artistData,
          'id': artistDoc.id,
        });
      }
    } catch (_) {}
  }

  String _safeString(dynamic value, {String defaultVal = ''}) {
    if (value is String) return value;
    if (value == null) return defaultVal;
    return value.toString();
  }

  double _safeDouble(dynamic value, {double defaultVal = 0.0}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return defaultVal;
  }

  void _applyFilter() {
    if (selectedArtistCategoryId.value.isEmpty) {
      filteredServices.value = services;
    } else {
      filteredServices.value = services
          .where((s) => s.categoryId == selectedArtistCategoryId.value)
          .toList();
    }
  }

  Future<void> loadMyBookings() async {
    try {
      final uid = AuthController.to.currentUserId;
      if (uid == null) return;

      final snapshot = await _firebaseService.firestore
          .collection('bookings')
          .where('customerId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      myBookings.value = snapshot.docs
          .map((doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      AppHelpers.showError('Failed to load bookings.');
    }
  }

  void selectService(ServiceModel service) {
    selectedService.value = service;
  }

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0E8F95),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) selectedDate.value = picked;
  }

  void selectTimeSlot(String slot) {
    selectedTimeSlot.value = slot;
  }

  Future<void> uploadDesignImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image == null) return;

      isUploadingImage.value = true;
      uploadFailed.value = false;

      final uid = AuthController.to.currentUserId!;
      final bytes = await image.readAsBytes();
      final fileName = '${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/dc58vppqz/image/upload'),
      );
      request.fields['upload_preset'] = 'smartstitch_profile';
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);
      final url = jsonData['secure_url'] as String?;

      if (url == null) {
        throw Exception('Upload failed: ${jsonData['error']?['message']}');
      }

      designImageUrl.value = url;
      AppHelpers.showSuccess('Design uploaded!');
    } catch (e) {
      uploadFailed.value = true;
      AppHelpers.showError('Failed to upload design.');
    } finally {
      isUploadingImage.value = false;
    }
  }

  String _formatEmailDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> createBooking() async {
    if (selectedService.value == null) {
      AppHelpers.showError('Please select a service.');
      return;
    }
    if (selectedArtistId.value.isEmpty) {
      AppHelpers.showError('Please select an artist.');
      return;
    }
    if (selectedDate.value == null) {
      AppHelpers.showError('Please select a date.');
      return;
    }
    if (selectedTimeSlot.value.isEmpty) {
      AppHelpers.showError('Please select a time slot.');
      return;
    }

    try {
      isLoading.value = true;

      final dateOnly = DateTime(
        selectedDate.value!.year,
        selectedDate.value!.month,
        selectedDate.value!.day,
      );

      try {
        final conflictSnapshot = await _firebaseService.firestore
            .collection('bookings')
            .where('artistId', isEqualTo: selectedArtistId.value)
            .where('timeSlot', isEqualTo: selectedTimeSlot.value)
            .get();

        final hasConflict = conflictSnapshot.docs.any((doc) {
          final data = doc.data();
          final status = data['status'] as String?;
          if (status == 'cancelled') return false;

          final apptRaw = data['appointmentDate'];
          if (apptRaw == null) return false;
          final apptDate = apptRaw is Timestamp
              ? apptRaw.toDate()
              : DateTime.tryParse(apptRaw.toString());
          if (apptDate == null) return false;

          return apptDate.year == dateOnly.year &&
              apptDate.month == dateOnly.month &&
              apptDate.day == dateOnly.day;
        });

        if (hasConflict) {
          AppHelpers.showError(
            'This time slot is already booked. Please choose another time.',
          );
          isLoading.value = false;
          return;
        }
      } catch (e) {
        AppHelpers.showError('Failed to verify booking slot.');
        isLoading.value = false;
        return;
      }

      final uid = AuthController.to.currentUserId!;
      final bookingId = const Uuid().v4();

      final basePrice = selectedService.value!.basePrice;
      final deliveryFee = isHomeVisit.value ? 200.0 : 0.0;
      final totalAmount = basePrice + deliveryFee;

      if (selectedPaymentMethod.value == PaymentMethod.stripe) {
        final result = await StripeService.instance.makePayment(
          amount: totalAmount,
          currency: 'pkr',
          bookingId: bookingId,
          customerEmail: AuthController.to.currentUser.value?.email,
        );

        if (!result.success) {
          AppHelpers.showError(
            result.message.isNotEmpty ? result.message : 'Payment failed.',
          );
          isLoading.value = false;
          return;
        }
      }

      final booking = BookingModel(
        id: bookingId,
        customerId: uid,
        artistId: selectedArtistId.value,
        serviceId: selectedService.value!.id,
        serviceTitle: selectedService.value!.title,
        servicePrice: basePrice,
        deliveryFee: deliveryFee,
        totalAmount: totalAmount,
        measurementId: selectedMeasurement.value?.id,
        paymentMethod: selectedPaymentMethod.value,
        bookingType:
            isHomeVisit.value ? BookingType.homeVisit : BookingType.dropOff,
        appointmentDate: selectedDate.value!,
        timeSlot: selectedTimeSlot.value,
        address: isHomeVisit.value ? selectedAddress.value : null,
        designImageUrl:
            designImageUrl.value.isNotEmpty ? designImageUrl.value : null,
        specialInstructions: specialInstructions.value.isNotEmpty
            ? specialInstructions.value
            : null,
        isHomeVisit: isHomeVisit.value,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firebaseService.firestore.collection('bookings').doc(booking.id).set({
        ...booking.toJson(),
        'address': isHomeVisit.value ? selectedAddress.value?.toJson() : null,
        'servicePrice': basePrice,
        'deliveryFee': deliveryFee,
        'totalAmount': totalAmount,
        'platformCommission': (basePrice * 0.15).roundToDouble(),
        'artistAmount': (basePrice * 0.85).roundToDouble(),
      });

      await _firebaseService.firestore
          .collection('artists')
          .doc(selectedArtistId.value)
          .update({
        'totalOrders': FieldValue.increment(1),
      });

      final userEmail = AuthController.to.currentUser.value?.email;
      if (userEmail != null) {
        await BrevoService.sendBookingConfirmation(
          toEmail: userEmail,
          bookingId: '#${booking.id.substring(0, 8).toUpperCase()}',
          serviceName: booking.serviceTitle,
          date: _formatEmailDate(booking.appointmentDate),
          time: booking.timeSlot,
          visitType: booking.isHomeVisit ? 'Home Visit' : 'Drop Off',
          amount: 'Rs ${totalAmount.toInt()}',
        );
      }

      try {
        await NotificationService.instance.sendNotification(
          recipientId: uid,
          recipientRole: UserRole.customer,
          type: NotificationType.orderUpdate,
          title: 'Booking Confirmed!',
          body: '${booking.serviceTitle} booked for ${booking.timeSlot}',
          data: {'bookingId': booking.id},
        );
        await NotificationService.instance.sendNotification(
          recipientId: booking.artistId,
          recipientRole: UserRole.artist,
          type: NotificationType.orderUpdate,
          title: 'New Booking Request!',
          body: 'New booking for ${booking.serviceTitle}',
          data: {'bookingId': booking.id},
        );
      } catch (e) {
        AppHelpers.showError('Notification failed.');
      }

      myBookings.insert(0, booking);
      lastBooking.value = booking;

      Get.off(() => const BookingConfirmScreen(isSuccess: true));
      _resetForm();
    } catch (e) {
      AppHelpers.showError('Failed to create booking.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await _firebaseService.firestore
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': AppointmentStatus.cancelled.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final index = myBookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        myBookings[index] =
            myBookings[index].copyWith(status: AppointmentStatus.cancelled);
      }
      AppHelpers.showSuccess('Booking cancelled.');
    } catch (e) {
      AppHelpers.showError('Failed to cancel booking.');
    }
  }

  void _resetForm() {
    selectedService.value = null;
    selectedDate.value = null;
    selectedTimeSlot.value = '';
    selectedAddress.value = null;
    isHomeVisit.value = false;
    designImageUrl.value = '';
    specialInstructions.value = '';
    selectedArtistId.value = '';
    selectedArtistCategoryId.value = '';
    selectedArtist.value = null;
    selectedMeasurement.value = null;
    selectedPaymentMethod.value = PaymentMethod.wallet;
  }
}