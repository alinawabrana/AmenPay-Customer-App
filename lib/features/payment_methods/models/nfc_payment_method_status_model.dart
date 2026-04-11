class NfcPaymentMethodStatus {
  final int paymentMethodId;
  final String cardHolderName;
  final String cardNumber;
  final String cardType;
  final String expiryDate;
  final String? qrCode;
  final bool palmEnrolled;
  final String? nfcStatus;
  final bool nfcEnrolled;
  final bool nfcEnabled;
  final DateTime? nfcEnrolledAt;
  final bool isDefault;

  const NfcPaymentMethodStatus({
    required this.paymentMethodId,
    required this.cardHolderName,
    required this.cardNumber,
    required this.cardType,
    required this.expiryDate,
    required this.qrCode,
    required this.palmEnrolled,
    required this.nfcStatus,
    required this.nfcEnrolled,
    required this.nfcEnabled,
    required this.nfcEnrolledAt,
    required this.isDefault,
  });

  NfcPaymentMethodStatus copyWith({
    int? paymentMethodId,
    String? cardHolderName,
    String? cardNumber,
    String? cardType,
    String? expiryDate,
    String? qrCode,
    bool? palmEnrolled,
    String? nfcStatus,
    bool? nfcEnrolled,
    bool? nfcEnabled,
    DateTime? nfcEnrolledAt,
    bool? isDefault,
  }) {
    return NfcPaymentMethodStatus(
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      cardNumber: cardNumber ?? this.cardNumber,
      cardType: cardType ?? this.cardType,
      expiryDate: expiryDate ?? this.expiryDate,
      qrCode: qrCode ?? this.qrCode,
      palmEnrolled: palmEnrolled ?? this.palmEnrolled,
      nfcStatus: nfcStatus ?? this.nfcStatus,
      nfcEnrolled: nfcEnrolled ?? this.nfcEnrolled,
      nfcEnabled: nfcEnabled ?? this.nfcEnabled,
      nfcEnrolledAt: nfcEnrolledAt ?? this.nfcEnrolledAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  bool get isNfcActive =>
      isNfcEnrolledKnown && (nfcStatus ?? '').toLowerCase() == 'active';
  bool get isNfcInactive =>
      isNfcEnrolledKnown && (nfcStatus ?? '').toLowerCase() == 'inactive';
  bool get isNfcEnrolledKnown =>
      nfcEnrolled ||
      nfcEnabled ||
      nfcEnrolledAt != null ||
      ((nfcStatus ?? '').toLowerCase() == 'active') ||
      ((nfcStatus ?? '').toLowerCase() == 'inactive');
  bool get isNfcNotEnrolled => !isNfcEnrolledKnown;

  factory NfcPaymentMethodStatus.fromJson(Map<String, dynamic> json) {
    final enrolledAtRaw = json['nfc_enrolled_at']?.toString();
    return NfcPaymentMethodStatus(
      paymentMethodId: (json['payment_method_id'] as num?)?.toInt() ?? 0,
      cardHolderName: json['card_holder_name']?.toString() ?? '',
      cardNumber: json['card_number']?.toString() ?? '',
      cardType: json['card_type']?.toString() ?? '',
      expiryDate: json['expiry_date']?.toString() ?? '',
      qrCode: json['qr_code']?.toString(),
      palmEnrolled: _parseBool(json['palm_enrolled']),
      nfcStatus: json['nfc_status']?.toString(),
      nfcEnrolled: _parseBool(json['nfc_enrolled']),
      nfcEnabled: _parseBool(json['nfc_enabled']),
      nfcEnrolledAt: enrolledAtRaw == null || enrolledAtRaw.isEmpty
          ? null
          : DateTime.tryParse(enrolledAtRaw),
      isDefault: _parseBool(json['is_default'] ?? json['default']),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes' ||
          normalized == 'active' ||
          normalized == 'enabled';
    }
    return false;
  }
}
