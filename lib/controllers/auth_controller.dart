import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:smartstitch/auth/post_login_welcome_screen.dart';
import 'package:smartstitch/auth/otp_verification_screen.dart';
import 'package:smartstitch/core/utils/helpers.dart';
import 'package:smartstitch/models/address_model.dart';
import 'package:smartstitch/routes/routes.dart';
import 'package:smartstitch/services/wallet_brevo_service.dart';
import '../../models/user_model.dart';
import '../../models/artist_model.dart';
import '../../models/rider_model.dart';
import '../../models/enums.dart';
import '../../services/firebase_service.dart';
import '../../services/notification_service.dart';

class _AdminConfig {
  static const String email = 'admin@smartstitch.com';
}

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final FirebaseService _firebaseService = FirebaseService();

  // 🔒 Signup ke dauran authStateChanges() listener ko interfere hone se rokta hai
  bool _isSigningUp = false;

  // ✅ Web pe serverClientId support nahi
  final GoogleSignIn _googleSignIn = kIsWeb
      ? GoogleSignIn(scopes: ['email'])
      : GoogleSignIn(
          scopes: ['email'],
          serverClientId:
              '975527246570-lr402mc3lr8r7nad7626utk14nbd903r.apps.googleusercontent.com',
        );

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isGoogleLoading = false.obs;
  final RxBool isLoggedIn = false.obs;
  final Rx<UserRole> userRole = UserRole.customer.obs;
  RxList<String> specializations = <String>[].obs;
  RxBool isLoadingSpecs = false.obs;

  String? _verificationId;

  bool get isGuest => currentUser.value == null;
  String? get currentUserId => _firebaseService.currentUserId;

  // ─── DEFAULT / DUMMY AVATAR ───────────────────────────────────────────────
  static const String _dummyImageBase =
      'https://ui-avatars.com/api/?background=6C5CE7&color=fff&size=256&name=';

  String _dummyImageUrl(String name) =>
      '$_dummyImageBase${Uri.encodeComponent(name.trim().isEmpty ? 'User' : name.trim())}';

  Future<String> _uploadOrDummyImage({
    required XFile? image,
    required String uid,
    required String name,
  }) async {
    if (image == null) {
      return _dummyImageUrl(name);
    }

    try {
      final bytes = await image.readAsBytes();
      final fileName = '${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/dc58vppqz/image/upload'),
      );

      request.fields['upload_preset'] = 'smartstitch_profile';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);
      final url = jsonData['secure_url'];

      if (url == null) {
        throw Exception('Upload failed: ${jsonData['error']?['message']}');
      }
      return url as String;
    } catch (e) {
      debugPrint(
          '⚠️ Signup image upload failed, falling back to dummy avatar: $e');
      return _dummyImageUrl(name);
    }
  }

  // ─── OTP HELPERS ──────────────────────────────────────────────────────────

  String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<void> _createOtpAndSendEmail({
    required String uid,
    required String name,
    required String email,
    required String role, // 'Customer' | 'Artist' | 'Rider'
  }) async {
    final otp = _generateOtp();
    final expiry = DateTime.now().add(const Duration(minutes: 10));

    await _firebaseService.updateDocument(
      collection: 'users',
      docId: uid,
      data: {
        'otpCode': otp,
        'otpExpiry': expiry.toIso8601String(),
      },
    );

    await WalletBrevoService.sendRegistrationOtp(
      toEmail: email,
      fullName: name,
      otpCode: otp,
      role: role,
    );
  }

  /// Call this after the user enters the 6-digit code on OtpVerificationScreen.
  Future<bool> verifyOtp({required String email, required String otp}) async {
    try {
      final query = await _firebaseService.firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return false;

      final doc = query.docs.first;
      final data = doc.data();

      final storedOtp = data['otpCode'] as String?;
      final expiryStr = data['otpExpiry'] as String?;

      if (storedOtp == null || expiryStr == null) return false;
      if (storedOtp != otp) return false;

      final expiry = DateTime.parse(expiryStr);
      if (DateTime.now().isAfter(expiry)) return false; // expired

      await _firebaseService.updateDocument(
        collection: 'users',
        docId: doc.id,
        data: {
          'isEmailVerified': true,
          'otpCode': FieldValue.delete(),
          'otpExpiry': FieldValue.delete(),
        },
      );

      // Send the welcome email now that email is confirmed
      final role = (data['role'] as String).replaceAll('UserRole.', '');
      await WalletBrevoService.sendRegistrationWelcome(
        toEmail: email,
        fullName: data['name'] as String? ?? 'there',
        role: role[0].toUpperCase() + role.substring(1), // 'artist' -> 'Artist'
      );

      // Now that they're verified, let the normal auth-state flow take over
      await _loadUserData(doc.id);

      return true;
    } catch (e) {
      debugPrint('❌ verifyOtp error: $e');
      return false;
    }
  }

  /// Call this when the user taps "Resend" on OtpVerificationScreen.
  Future<bool> resendOtp({required String email}) async {
    try {
      final query = await _firebaseService.firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return false;

      final doc = query.docs.first;
      final data = doc.data();
      final role = (data['role'] as String).replaceAll('UserRole.', '');

      await _createOtpAndSendEmail(
        uid: doc.id,
        name: data['name'] as String? ?? 'there',
        email: email,
        role: role[0].toUpperCase() + role.substring(1),
      );

      return true;
    } catch (e) {
      debugPrint('❌ resendOtp error: $e');
      return false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _firebaseService.auth.authStateChanges().listen((firebaseUser) async {
      if (_isSigningUp) return;

      if (firebaseUser == null) {
        currentUser.value = null;
        isLoggedIn.value = false;
        userRole.value = UserRole.customer;
        return;
      }

      if (currentUser.value != null &&
          currentUser.value!.id != firebaseUser.uid) {
        currentUser.value = null;
        userRole.value = UserRole.customer;
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Admin check
      if (firebaseUser.email?.toLowerCase() ==
          _AdminConfig.email.toLowerCase()) {
        debugPrint('✅ Admin detected — going to welcome');

        final adminUser = UserModel(
          id: firebaseUser.uid,
          name: 'Admin',
          email: firebaseUser.email!,
          phone: '',
          role: UserRole.admin,
          authProvider: AuthProvider.email,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firebaseService.firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(adminUser.toJson(), SetOptions(merge: true));

        try {
          await NotificationService.instance
              .saveTokenToFirestore(firebaseUser.uid);
        } catch (e) {
          debugPrint('⚠️ Notification skip: $e');
        }

        currentUser.value = adminUser;
        userRole.value = UserRole.admin;
        isLoggedIn.value = true;

        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed(AppRoutes.postLoginWelcome);
        return;
      }

      await _loadUserData(firebaseUser.uid);
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firebaseService.getDocument(
        collection: 'users',
        docId: uid,
      );

      if (!doc.exists) {
        await _firebaseService.signOut();
        AppHelpers.showError('Account not found. Please signup again.');
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      if (data['isBlocked'] == true) {
        await _firebaseService.signOut();
        AppHelpers.showError('Account blocked. Contact support.');
        return;
      }

      // ─── EMAIL NOT VERIFIED YET → send them to OTP screen instead ──────
      if (data['isEmailVerified'] == false) {
        final role = (data['role'] as String).replaceAll('UserRole.', '');
        Get.offAll(() => OtpVerificationScreen(
              email: data['email'] as String,
              role: role[0].toUpperCase() + role.substring(1),
            ));
        return;
      }

      final safeData = {
        ...data,
        'id': doc.id,
        'createdAt': data['createdAt'] is String
            ? data['createdAt']
            : (data['createdAt'] as dynamic).toDate().toIso8601String(),
        'updatedAt': data['updatedAt'] is String
            ? data['updatedAt']
            : (data['updatedAt'] as dynamic).toDate().toIso8601String(),
        'role': (data['role'] as String).replaceAll('UserRole.', ''),
        'authProvider':
            (data['authProvider'] as String).replaceAll('AuthProvider.', ''),
      };

      currentUser.value = UserModel.fromJson(safeData);
      userRole.value = currentUser.value!.role;
      isLoggedIn.value = true;

      // ─── Dark mode restore ─────────────────────────────
      final isDark = currentUser.value?.isDarkMode ?? false;
      Get.changeThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);

      debugPrint('✅ User loaded — role: ${currentUser.value!.role.name}');

      await Future.delayed(const Duration(milliseconds: 800));

      // 👉 Role ke hisaab se seedha respective dashboard pe navigate karo
      switch (currentUser.value!.role.name) {
        case 'artist':
          debugPrint(">>> Going to Artist Dashboard");
          Get.offAllNamed(AppRoutes.artistDashboard);
          break;

        case 'rider':
          debugPrint(">>> Going to Rider Dashboard");
          Get.offAllNamed(AppRoutes.riderDashboard);
          break;

        case 'admin':
          debugPrint(">>> Going to Admin Dashboard");
          Get.offAllNamed(AppRoutes.adminDashboard);
          break;

        default:
          debugPrint(">>> Going to Customer Home");
          Get.offAllNamed(AppRoutes.customerHome);
      }
    } catch (e, stack) {
      debugPrint("LOAD USER ERROR: $e");
      debugPrintStack(stackTrace: stack);

      AppHelpers.showError(e.toString());
    }
  }

  // ─── FETCH SPECIALIZATIONS ────────────────────────────────────────────────
  Future<void> fetchSpecializations() async {
    try {
      isLoadingSpecs.value = true;
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('createdAt')
          .get();

      specializations.value =
          snapshot.docs.map((doc) => doc.data()['name'] as String).toList();
    } catch (e) {
      AppHelpers.showError('Failed to load specializations');
    } finally {
      isLoadingSpecs.value = false;
    }
  }

  // ─── EMAIL LOGIN ──────────────────────────────────────────────────────────
  Future<void> login({required String email, required String password}) async {
    try {
      isLoading.value = true;
      await _firebaseService.signIn(email: email, password: password);
    } catch (e) {
      AppHelpers.showError(_errorMessage(e.toString()));
    } finally {
      isLoading.value = false;
    }
  }

  // ─── GOOGLE SIGN-IN ───────────────────────────────────────────────────────
  Future<void> signInWithGoogle() async {
    try {
      isGoogleLoading.value = true;

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        isGoogleLoading.value = false;
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseService.auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;

      final doc = await _firebaseService.getDocument(
        collection: 'users',
        docId: firebaseUser.uid,
      );

      if (!doc.exists) {
        final newUser = UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email ?? '',
          phone: firebaseUser.phoneNumber ?? '',
          profileImageUrl: firebaseUser.photoURL,
          role: UserRole.customer,
          authProvider: AuthProvider.google,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _firebaseService.setDocument(
          collection: 'users',
          docId: newUser.id,
          data: {...newUser.toJson(), 'isEmailVerified': true},
        );
        AppHelpers.showSuccess('Welcome, ${newUser.name}!');
      }
    } catch (e) {
      AppHelpers.showError(_errorMessage(e.toString()));
    } finally {
      isGoogleLoading.value = false;
    }
  }

  // ─── PHONE OTP SEND ───────────────────────────────────────────────────────
  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required VoidCallback onCodeSent,
  }) async {
    try {
      isLoading.value = true;
      await _firebaseService.auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithPhoneCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          AppHelpers.showError(_errorMessage(e.code));
          isLoading.value = false;
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          isLoading.value = false;
          onCodeSent();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      isLoading.value = false;
      AppHelpers.showError(_errorMessage(e.toString()));
    }
  }

  // ─── PHONE OTP VERIFY ─────────────────────────────────────────────────────
  Future<void> verifyPhoneOtp(String otp) async {
    if (_verificationId == null) {
      AppHelpers.showError('Please request OTP first');
      return;
    }
    try {
      isLoading.value = true;
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await _signInWithPhoneCredential(credential);
    } catch (e) {
      AppHelpers.showError(_errorMessage(e.toString()));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _signInWithPhoneCredential(
      PhoneAuthCredential credential) async {
    final userCredential =
        await _firebaseService.auth.signInWithCredential(credential);
    final firebaseUser = userCredential.user!;

    final doc = await _firebaseService.getDocument(
      collection: 'users',
      docId: firebaseUser.uid,
    );

    if (!doc.exists) {
      final newUser = UserModel(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'User',
        email: firebaseUser.email ?? '',
        phone: firebaseUser.phoneNumber ?? '',
        role: UserRole.customer,
        authProvider: AuthProvider.phone,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _firebaseService.setDocument(
        collection: 'users',
        docId: newUser.id,
        data: {...newUser.toJson(), 'isEmailVerified': true},
      );
      AppHelpers.showSuccess('Welcome!');
    }
  }

  // ─── SIGNUP (Customer) ────────────────────────────────────────────────────
  Future<void> signupCustomer({
    required String name,
    required String email,
    required String password,
    required String phone,
    XFile? profileImage,
  }) async {
    if (email.trim().toLowerCase() == _AdminConfig.email.toLowerCase()) {
      AppHelpers.showError('This email is reserved.');
      return;
    }
    try {
      isLoading.value = true;
      _isSigningUp = true;

      final credential =
          await _firebaseService.signUp(email: email, password: password);

      final imageUrl = await _uploadOrDummyImage(
        image: profileImage,
        uid: credential.user!.uid,
        name: name,
      );

      final user = UserModel(
        id: credential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        profileImageUrl: imageUrl,
        role: UserRole.customer,
        authProvider: AuthProvider.email,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firebaseService.setDocument(
        collection: 'users',
        docId: user.id,
        data: {...user.toJson(), 'isEmailVerified': false},
      );

      await _createOtpAndSendEmail(
        uid: user.id,
        name: name,
        email: email,
        role: 'Customer',
      );

      AppHelpers.showSuccess('Almost there! Check your email for the code.');
      Get.offAll(() => OtpVerificationScreen(
            email: email,
            role: 'Customer',
          ));
    } catch (e) {
      AppHelpers.showError(_errorMessage(e.toString()));
    } finally {
      isLoading.value = false;
      _isSigningUp = false;
    }
  }

  // ─── SIGNUP (Artist) ──────────────────────────────────────────────────────
  Future<void> signupArtist({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String businessName,
    required String bio,
    required String cnicNumber,
    required List<String> specializations,
    required String shopAddress,
    required String shopCity,
    required String shopProvince,
    XFile? profileImage,
  }) async {
    if (email.trim().toLowerCase() == _AdminConfig.email.toLowerCase()) {
      AppHelpers.showError('This email is reserved.');
      return;
    }
    try {
      isLoading.value = true;
      _isSigningUp = true;

      final credential =
          await _firebaseService.signUp(email: email, password: password);

      final imageUrl = await _uploadOrDummyImage(
        image: profileImage,
        uid: credential.user!.uid,
        name: name,
      );

      final user = UserModel(
        id: credential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        profileImageUrl: imageUrl,
        role: UserRole.artist,
        authProvider: AuthProvider.email,
        isVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firebaseService.setDocument(
        collection: 'users',
        docId: user.id,
        data: {...user.toJson(), 'isEmailVerified': false},
      );

      final artist = ArtistModel(
        id: credential.user!.uid,
        userId: credential.user!.uid,
        businessName: businessName,
        bio: bio,
        cnicNumber: cnicNumber,
        cnicImageUrl: '',
        profileImageUrl: imageUrl,
        specializations: specializations,
        shopAddress: AddressModel(
          id: credential.user!.uid,
          label: 'Shop',
          fullAddress: shopAddress,
          city: shopCity,
          province: shopProvince,
          latitude: 0.0,
          longitude: 0.0,
          isDefault: true,
        ),
        joinedAt: DateTime.now(),
      );

      await _firebaseService.setDocument(
        collection: 'artists',
        docId: artist.id,
        data: artist.toJson(),
      );

      await _createOtpAndSendEmail(
        uid: user.id,
        name: name,
        email: email,
        role: 'Artist',
      );

      AppHelpers.showSuccess('Almost there! Check your email for the code.');

      Get.offAll(() => OtpVerificationScreen(
            email: email,
            role: 'Artist',
          ));
    } catch (e) {
      AppHelpers.showError(_errorMessage(e.toString()));
    } finally {
      isLoading.value = false;
      _isSigningUp = false;
    }
  }

  // ─── SIGNUP (Rider) ───────────────────────────────────────────────────────
  Future<void> signupRider({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String cnicNumber,
    required String vehicleType,
    required String vehicleNumber,
    XFile? profileImage,
  }) async {
    if (email.trim().toLowerCase() == _AdminConfig.email.toLowerCase()) {
      AppHelpers.showError('This email is reserved.');
      return;
    }
    try {
      isLoading.value = true;
      _isSigningUp = true;

      final credential =
          await _firebaseService.signUp(email: email, password: password);

      final imageUrl = await _uploadOrDummyImage(
        image: profileImage,
        uid: credential.user!.uid,
        name: name,
      );

      final user = UserModel(
        id: credential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        profileImageUrl: imageUrl,
        role: UserRole.rider,
        authProvider: AuthProvider.email,
        isVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firebaseService.setDocument(
        collection: 'users',
        docId: user.id,
        data: {...user.toJson(), 'isEmailVerified': false},
      );

      final rider = RiderModel(
        id: credential.user!.uid,
        userId: credential.user!.uid,
        cnicNumber: cnicNumber,
        cnicImageUrl: '',
        drivingLicenseUrl: '',
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        joinedAt: DateTime.now(),
      );

      await _firebaseService.setDocument(
        collection: 'riders',
        docId: rider.id,
        data: rider.toJson(),
      );

      await _createOtpAndSendEmail(
        uid: user.id,
        name: name,
        email: email,
        role: 'Rider',
      );

      AppHelpers.showSuccess('Almost there! Check your email for the code.');
      Get.offAll(() => OtpVerificationScreen(
            email: email,
            role: 'Rider',
          ));
    } catch (e) {
      AppHelpers.showError(_errorMessage(e.toString()));
    } finally {
      isLoading.value = false;
      _isSigningUp = false;
    }
  }

  // ─── RELOAD CURRENT USER ──────────────────────────────────────────────────
  Future<void> reloadCurrentUser() async {
    try {
      final uid = currentUserId;
      if (uid == null) return;

      final doc =
          await _firebaseService.firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        currentUser.value = UserModel.fromJson({...doc.data()!, 'id': doc.id});
        debugPrint('✅ User reloaded');
      }
    } catch (e) {
      debugPrint('❌ reloadCurrentUser error: $e');
    }
  }

  // ─── LOGOUT ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    try {
      await _firebaseService.signOut();
    } catch (_) {}

    currentUser.value = null;
    isLoggedIn.value = false;

    Get.offAllNamed(AppRoutes.customerHome);
  }

  // ─── FORGOT PASSWORD ──────────────────────────────────────────────────────
  Future<void> forgotPassword(String email) async {
    try {
      isLoading.value = true;
      await _firebaseService.sendPasswordResetEmail(email);
      AppHelpers.showSuccess('Reset email sent! Check your inbox.');
      Get.back();
    } catch (e) {
      AppHelpers.showError(_errorMessage(e.toString()));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgotPasswordSilent(String email) async {
    try {
      await _firebaseService.sendPasswordResetEmail(email);
    } catch (e) {
      AppHelpers.showError(_errorMessage(e.toString()));
      rethrow;
    }
  }

  // ─── ERROR MESSAGES ───────────────────────────────────────────────────────
  String _errorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'No account found with this email';
    }
    if (error.contains('wrong-password')) return 'Incorrect password';
    if (error.contains('invalid-credential')) {
      return 'Invalid email or password';
    }
    if (error.contains('email-already-in-use')) {
      return 'Email already registered';
    }
    if (error.contains('weak-password')) return 'Password is too weak';
    if (error.contains('network-request-failed')) {
      return 'No internet connection';
    }
    if (error.contains('too-many-requests')) {
      return 'Too many attempts. Try later.';
    }
    if (error.contains('sign_in_canceled')) return 'Google sign-in cancelled';
    if (error.contains('network_error')) return 'No internet connection';
    return 'An error occurred. Please try again.';
  }

  Future<void> toggleDarkMode(bool isDark) async {
    try {
      final uid = currentUserId;
      if (uid == null) return;

      await _firebaseService.updateDocument(
        collection: 'users',
        docId: uid,
        data: {'isDarkMode': isDark},
      );
      currentUser.value = currentUser.value!.copyWith(isDarkMode: isDark);
      Get.changeThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
    } catch (e) {
      AppHelpers.showError('Failed to update theme.');
    }
  }
}
