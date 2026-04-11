import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palmpay/features/payment_methods/providers/payment_methods_refresh_provider.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/services/api_service.dart';
import 'package:palmpay/utils/themes/text_theme.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../authentication/models/profile/user_model.dart';
import '../../home/models/QR Code/payment_method_model.dart';

class MyQrCodeScreen extends ConsumerStatefulWidget {
  const MyQrCodeScreen({super.key});

  @override
  ConsumerState<MyQrCodeScreen> createState() => _MyQrCodeScreenState();
}

class _MyQrCodeScreenState extends ConsumerState<MyQrCodeScreen> {
  late Future<_QrCodeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();

    ref.listenManual<int>(paymentMethodsRefreshProvider, (previous, next) {
      setState(() {
        _future = _load();
      });
    });
  }

  Future<_QrCodeData> _load() async {
    final results = await Future.wait([
      ApiService.getUserDetails(),
      ApiService.getPaymentMethods(),
      ApiService.getDefaultPaymentMethodCheck(),
    ]);

    final user = results[0] as UserModel;
    final paymentMethodsJson = results[1] as Map<String, dynamic>;
    final defaultJson = results[2] as Map<String, dynamic>;

    final paymentResponse = PaymentMethodsResponse.fromJson(paymentMethodsJson);
    final defaultId = _extractDefaultPaymentMethodId(defaultJson);
    final methods = paymentResponse.paymentMethods
        .map((method) => method.copyWith(isDefault: method.id == defaultId))
        .toList();

    if (methods.isEmpty) {
      throw Exception('no_payment_methods_found');
    }

    return _QrCodeData(
      user: user,
      paymentMethods: methods,
    );
  }

  int? _extractDefaultPaymentMethodId(Map<String, dynamic> json) {
    final candidates = <dynamic>[
      json['payment_method_id'],
      json['id'],
      json['default_payment_method_id'],
      (json['data'] is Map<String, dynamic>)
          ? (json['data'] as Map<String, dynamic>)['payment_method_id']
          : null,
      (json['data'] is Map<String, dynamic>)
          ? (json['data'] as Map<String, dynamic>)['id']
          : null,
      (json['payment_method'] is Map<String, dynamic>)
          ? (json['payment_method'] as Map<String, dynamic>)['payment_method_id']
          : null,
      (json['payment_method'] is Map<String, dynamic>)
          ? (json['payment_method'] as Map<String, dynamic>)['id']
          : null,
    ];

    for (final value in candidates) {
      final parsed = _coerceId(value);
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  int? _coerceId(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: SizedBox(
            width: 17,
            height: 15,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Icon(
                Icons.arrow_back,
                color: const Color(0xFF333333),
                textDirection: Directionality.of(context),
              ),
            ),
          ),
        ),
        title: Text(
          l10n.t('my_qr_code'),
          style: ATextTheme.textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<_QrCodeData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final rawMessage =
                snapshot.error.toString().replaceAll('Exception: ', '');
            final message = rawMessage == 'no_payment_methods_found'
                ? l10n.t('no_payment_methods_found')
                : rawMessage;

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final user = data.user;
          final methods = data.paymentMethods;

          return SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 32, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PaymentMethodsList(
                  methods: methods,
                  user: user,
                  onOpenQr: _showQrForMethod,
                  onToggleDefault: _toggleDefault,
                ),
                const SizedBox(height: 24),
                const _HowToUseCard(),
                const SizedBox(height: 32),
                const _QrActiveCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  String _maskAccountNumber(String raw) {
    if (raw.isEmpty) return '';
    final last4 = raw.length >= 4 ? raw.substring(raw.length - 4) : raw;
    return '****$last4';
  }

  Future<void> _toggleDefault(PaymentMethod method, bool isDefault) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    try {
      final res = await ApiService.toggleDefaultPaymentMethod(
        paymentMethodId: method.id,
        isDefault: isDefault,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            res['message']?.toString() ??
                l10n.t('default_payment_method_updated'),
          ),
        ),
      );
      ref.read(paymentMethodsRefreshProvider.notifier).state++;
      setState(() {
        _future = _load();
      });
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
    }
  }

  void _showQrForMethod(
    BuildContext context,
    UserModel user,
    PaymentMethod method,
  ) {
    final maskedCard = _maskAccountNumber(method.cardNumber);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLocalizations.of(sheetContext).t('qr_code'),
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _QrCard(qrCodeData: method.qrCode),
                    const SizedBox(height: 24),
                    _AccountInfoCard(
                      titleStyle: theme.textTheme.titleLarge?.copyWith(
                        height: 28 / 18,
                      ),
                      accountName: method.cardHolderName,
                      accountNumber: maskedCard,
                      qrCodeId: 'QR${method.id}',
                    ),
                    const SizedBox(height: 24),
                    const _QrActiveCard(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PaymentMethodsList extends StatelessWidget {
  final List<PaymentMethod> methods;
  final UserModel user;
  final void Function(BuildContext context, UserModel user, PaymentMethod method)
      onOpenQr;
  final Future<void> Function(PaymentMethod method, bool isDefault)
      onToggleDefault;

  const _PaymentMethodsList({
    required this.methods,
    required this.user,
    required this.onOpenQr,
    required this.onToggleDefault,
  });

  String _maskAccountNumber(String raw) {
    if (raw.isEmpty) return '';
    final last4 = raw.length >= 4 ? raw.substring(raw.length - 4) : raw;
    return '**** $last4';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.t('my_qr_code'),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...methods.map(
          (method) {
            final maskedCard = _maskAccountNumber(method.cardNumber);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onOpenQr(context, user, method),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.credit_card, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    method.cardHolderName,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF111827),
                                    ),
                                  ),
                                ),
                                if (method.isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFFDF5),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      l10n.t('default_label'),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF00AA44),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              maskedCard,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  l10n.t('default_label'),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4B5563),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Switch(
                                  value: method.isDefault,
                                  onChanged: (value) =>
                                      onToggleDefault(method, value),
                                  activeThumbColor: const Color(0xFF00AA44),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.qr_code, color: Color(0xFF238EC2)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _QrCard extends StatelessWidget {
  final String? qrCodeData;

  const _QrCard({required this.qrCodeData});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = qrCodeData?.trim() ?? '';

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        border: Border.all(color: const Color(0xFF238EC2), width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: data.isEmpty
              ? Text(
                  l10n.t('qr_code'),
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                )
              : QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 200,
                ),
        ),
      ),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  final TextStyle? titleStyle;
  final String accountName;
  final String accountNumber;
  final String qrCodeId;

  const _AccountInfoCard({
    required this.titleStyle,
    required this.accountName,
    required this.accountNumber,
    required this.qrCodeId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 1),
            blurRadius: 2,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.t('account_information'), style: titleStyle),
            const SizedBox(height: 16),
            _InfoRow(title: l10n.t('account_name'), value: accountName),
            const SizedBox(height: 12),
            _InfoRow(title: l10n.t('account_number'), value: accountNumber),
            const SizedBox(height: 12),
            _InfoRow(title: l10n.t('qr_code_id'), value: qrCodeId),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 20 / 14,
      letterSpacing: -0.5,
      color: const Color(0xFF4B5563),
    );

    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 20 / 14,
      letterSpacing: -0.5,
      color: const Color(0xFF333333),
    );

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: titleStyle,
            textAlign: TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            style: valueStyle,
            textAlign: TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _HowToUseCard extends StatelessWidget {
  const _HowToUseCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0x0D0066CC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1A0066CC), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _HowToIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('how_to_use'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 20 / 14,
                      letterSpacing: -0.5,
                      color: Color(0xFF238EC2),
                    ),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.t('how_to_use_qr_desc'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 23 / 14,
                      letterSpacing: -0.5,
                      color: Color(0xFF374151),
                    ),
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowToIcon extends StatelessWidget {
  const _HowToIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0x1A0066CC),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: SizedBox(
          width: 6,
          height: 13,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Icon(Icons.info, color: Color(0xFF238EC2)),
          ),
        ),
      ),
    );
  }
}

class _QrActiveCard extends StatelessWidget {
  const _QrActiveCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 1),
            blurRadius: 2,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF00AA44),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.t('qr_code_active'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 20 / 14,
                    letterSpacing: -0.5,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.t('qr_code_active_subtitle'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 16 / 12,
                    letterSpacing: -0.5,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QrCodeData {
  final UserModel user;
  final List<PaymentMethod> paymentMethods;

  const _QrCodeData({required this.user, required this.paymentMethods});
}
