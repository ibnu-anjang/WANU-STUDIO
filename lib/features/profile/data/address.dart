class Address {
  const Address({
    required this.id,
    required this.recipientName,
    required this.phone,
    required this.line1,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.isDefault,
  });

  final String id;
  final String recipientName;
  final String phone;
  final String line1;
  final String city;
  final String province;
  final String postalCode;
  final bool isDefault;

  factory Address.fromMap(Map<String, dynamic> map) => Address(
    id: map['id'] as String,
    recipientName: map['recipient_name'] as String,
    phone: map['phone'] as String,
    line1: map['line1'] as String,
    city: map['city'] as String,
    province: map['province'] as String,
    postalCode: map['postal_code'] as String,
    isDefault: map['is_default'] as bool,
  );
}
