import 'enums.dart';
import 'address_model.dart';
import 'body_measurement_model.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImageUrl;
  final UserRole role;
  final AuthProvider authProvider;
  final bool isVerified;
  final bool isBlocked;
  final String? fcmToken;
  final String preferredLanguage;
  final bool isDarkMode;
  final List<AddressModel> addresses;
  final BodyMeasurementModel? savedMeasurements;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImageUrl,
    required this.role,
    required this.authProvider,
    this.isVerified = false,
    this.isBlocked = false,
    this.fcmToken,
    this.preferredLanguage = 'en',
    this.isDarkMode = false,
    this.addresses = const [],
    this.savedMeasurements,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // ─── Safe role parse ──────────────────────────────────
    UserRole role = UserRole.customer;
    try {
      final roleStr = json['role'] as String? ?? 'customer';
      role = UserRole.values.byName(roleStr);
    } catch (_) {}

    // ─── Safe authProvider parse ──────────────────────────
    AuthProvider authProvider = AuthProvider.email;
    try {
      final providerStr = json['authProvider'] as String? ?? 'email';
      authProvider = AuthProvider.values.byName(providerStr);
    } catch (_) {}

    // ─── Safe addresses parse ─────────────────────────────
    List<AddressModel> addresses = [];
    try {
      final rawList = json['addresses'] as List<dynamic>?;
      if (rawList != null) {
        addresses = rawList
            .whereType<Map<String, dynamic>>()
            .map((e) => AddressModel.fromJson(e))
            .toList();
      }
    } catch (_) {}

    // ─── Safe measurements parse ──────────────────────────
    BodyMeasurementModel? savedMeasurements;
    try {
      if (json['savedMeasurements'] != null) {
        savedMeasurements = BodyMeasurementModel.fromJson(
            json['savedMeasurements'] as Map<String, dynamic>);
      }
    } catch (_) {}

    // ─── Safe dates parse ─────────────────────────────────
    DateTime createdAt = DateTime.now();
    DateTime updatedAt = DateTime.now();
    try {
      createdAt = DateTime.parse(json['createdAt'] as String);
    } catch (_) {}
    try {
      updatedAt = DateTime.parse(json['updatedAt'] as String);
    } catch (_) {}

    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      role: role,
      authProvider: authProvider,
      isVerified: json['isVerified'] as bool? ?? false,
      isBlocked: json['isBlocked'] as bool? ?? false,
      fcmToken: json['fcmToken'] as String?,
      preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      addresses: addresses,
      savedMeasurements: savedMeasurements,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String? get city => null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'profileImageUrl': profileImageUrl,
        'role': role.name,
        'authProvider': authProvider.name,
        'isVerified': isVerified,
        'isBlocked': isBlocked,
        'fcmToken': fcmToken,
        'preferredLanguage': preferredLanguage,
        'isDarkMode': isDarkMode,
        'addresses': addresses.map((e) => e.toJson()).toList(),
        'savedMeasurements': savedMeasurements?.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  UserModel copyWith({
    String? name,
    String? phone,
    String? profileImageUrl,
    bool? isDarkMode,
    String? preferredLanguage,
    List<AddressModel>? addresses,
    BodyMeasurementModel? savedMeasurements,
    String? fcmToken,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        profileImageUrl: profileImageUrl ?? this.profileImageUrl,
        role: role,
        authProvider: authProvider,
        isVerified: isVerified,
        isBlocked: isBlocked,
        fcmToken: fcmToken ?? this.fcmToken,
        preferredLanguage: preferredLanguage ?? this.preferredLanguage,
        isDarkMode: isDarkMode ?? this.isDarkMode,
        addresses: addresses ?? this.addresses,
        savedMeasurements: savedMeasurements ?? this.savedMeasurements,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}