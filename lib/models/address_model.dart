class AddressModel {
  final String id;
  final String label; 
  final String fullAddress;
  final String city;
  final String province;
  final double latitude;
  final double longitude;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.city,
    required this.province,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
  });
  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: json['id'] as String? ?? '',
        label: json['label'] as String? ?? 'Address',
        fullAddress: json['fullAddress'] as String? ?? '',
        city: json['city'] as String? ?? '',
        province: json['province'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
        isDefault: json['isDefault'] as bool? ?? false,
      );

  AddressModel copyWith({
    String? id,
    String? label,
    String? fullAddress,
    String? city,
    String? province,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) =>
      AddressModel(
        id: id ?? this.id,
        label: label ?? this.label,
        fullAddress: fullAddress ?? this.fullAddress,
        city: city ?? this.city,
        province: province ?? this.province,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        isDefault: isDefault ?? this.isDefault,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'fullAddress': fullAddress,
        'city': city,
        'province': province,
        'latitude': latitude,
        'longitude': longitude,
        'isDefault': isDefault,
      };
}