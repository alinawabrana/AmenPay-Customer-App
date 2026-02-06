import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/services/api_service.dart';
import 'package:palmpay/utils/themes/text_theme.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../authentication/models/profile/user_model.dart';
import '../../home/models/QR Code/payment_method_model.dart';

class MyQrCodeScreen extends StatefulWidget {
  const MyQrCodeScreen({super.key});

  @override
  State<MyQrCodeScreen> createState() => _MyQrCodeScreenState();
}

class _MyQrCodeScreenState extends State<MyQrCodeScreen> {
  late final Future<_QrCodeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_QrCodeData> _load() async {
    final results = await Future.wait([
      ApiService.getUserDetails(),
      ApiService.getPaymentMethods(),
    ]);

    final user = results[0] as UserModel;
    final paymentMethodsJson = results[1] as Map<String, dynamic>;

    final paymentResponse = PaymentMethodsResponse.fromJson(paymentMethodsJson);

    if (paymentResponse.paymentMethods.isEmpty) {
      throw Exception('no_payment_methods_found');
    }

    return _QrCodeData(
      user: user,
      paymentMethod: paymentResponse.paymentMethods.first,
    );
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
          final method = data.paymentMethod;

          final maskedCard = _maskAccountNumber(method.cardNumber);

          return SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 32, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _QrCard(qrCodeData: method.qrCode),
                const SizedBox(height: 32),
                _AccountInfoCard(
                  titleStyle: theme.textTheme.titleLarge?.copyWith(
                    height: 28 / 18,
                  ),
                  accountName: user.fullname,
                  accountNumber: maskedCard,
                  qrCodeId: 'QR${method.id}',
                ),
                const SizedBox(height: 32),
                const _HowToUseCard(),
                const SizedBox(height: 32),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(l10n.t('save_to_phone')),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.print, size: 18),
                          label: Text(l10n.t('print')),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF333333),
                            side: const BorderSide(
                              color: Color(0xFFE5E7EB),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.share, size: 18),
                          label: Text(l10n.t('share')),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF333333),
                            side: const BorderSide(
                              color: Color(0xFFE5E7EB),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
}

class _QrCard extends StatelessWidget {
  final String? qrCodeData;

  const _QrCard({required this.qrCodeData});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = qrCodeData?.trim() ?? '';

    return Container(
      height: 355,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 10),
            blurRadius: 15,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 4),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: data.isEmpty
              ? Text(
                  l10n.t('qr_code'),
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                )
              : QrImage(data: data, version: QrVersions.auto),
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
      height: 192,
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
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.t('account_information'), style: titleStyle),
            const SizedBox(height: 19),
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
          child: Text(title, style: titleStyle, textAlign: TextAlign.start),
        ),
        const SizedBox(width: 12),
        Text(value, style: valueStyle, textAlign: TextAlign.start),
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
  final PaymentMethod paymentMethod;

  const _QrCodeData({required this.user, required this.paymentMethod});
}
