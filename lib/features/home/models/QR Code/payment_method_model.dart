// models/payment_method_model.dart
class PaymentMethod {
  final int id;
  final String cardHolderName;
  final String cardNumber;
  final String expiryDate;
  final String cardType;
  final String status;
  final DateTime createdAt;

  /// Optional / legacy fields (not always present in API)
  final int? cardId;
  final String? qrCode;

  PaymentMethod({
    required this.id,
    required this.cardHolderName,
    required this.cardNumber,
    required this.expiryDate,
    required this.cardType,
    required this.status,
    required this.createdAt,
    this.cardId,
    this.qrCode,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['created_at'] ?? json['createdAt'];
    DateTime createdAt;
    if (createdAtRaw is String && createdAtRaw.isNotEmpty) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return PaymentMethod(
      id: (json['id'] as num?)?.toInt() ?? 0,
      cardId: (json['card_id'] as num?)?.toInt(),
      cardHolderName:
          (json['card_holder_name'] ?? json['cardHolderName'] ?? '') as String,
      cardNumber: (json['card_number'] ?? json['cardNumber'] ?? '') as String,
      expiryDate: (json['expiry_date'] ?? json['expiryDate'] ?? '') as String,
      cardType: (json['card_type'] ?? json['cardType'] ?? '') as String,
      qrCode: (json['qr_code'] ?? json['qrCode']) as String?,
      status: (json['status'] ?? '') as String,
      createdAt: createdAt,
    );
  }
}

class PaymentMethodsResponse {
  final int userId;
  final List<PaymentMethod> paymentMethods;
  final String message;

  PaymentMethodsResponse({
    required this.userId,
    required this.paymentMethods,
    required this.message,
  });

  factory PaymentMethodsResponse.fromJson(Map<String, dynamic> json) {
    final listRaw = json['payment_methods'] ?? json['paymentMethods'] ?? [];
    final list = (listRaw is List) ? listRaw : <dynamic>[];

    return PaymentMethodsResponse(
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      message: (json['message'] ?? '') as String,
      paymentMethods: list
          .whereType<Map<String, dynamic>>()
          .map((e) => PaymentMethod.fromJson(e))
          .toList(),
    );
  }
}
