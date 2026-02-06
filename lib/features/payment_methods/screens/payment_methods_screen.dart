import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palmpay/app_routes.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/services/api_service.dart';
import 'package:palmpay/utils/themes/text_theme.dart';
import 'package:palmpay/widgets/payment_method_card.dart';

import 'package:palmpay/features/payment_methods/providers/payment_methods_refresh_provider.dart';

import '../../authentication/models/profile/user_model.dart';
import '../../home/models/QR Code/payment_method_model.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  late Future<_PaymentMethodsData> _future;

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

  Future<_PaymentMethodsData> _load() async {
    final results = await Future.wait([
      ApiService.getUserDetails(),
      ApiService.getPaymentMethods(),
      ApiService.getUserCards(),
      ApiService.getPalmEnrollMeStatus(),
    ]);

    final user = results[0] as UserModel;
    final paymentMethodsJson = results[1] as Map<String, dynamic>;
    final userCardsJson = results[2] as Map<String, dynamic>;
    final palmEnrollJson = results[3] as Map<String, dynamic>;

    final paymentResponse = PaymentMethodsResponse.fromJson(paymentMethodsJson);

    final methods = paymentResponse.paymentMethods;

    bool isNfcActive = false;
    if (methods.isNotEmpty) {
      final statuses = <bool>[];
      await Future.wait(
        methods.map((m) async {
          try {
            final res = await ApiService.getNfcStatus(paymentMethodId: m.id);
            final dynamic inner = res['data'];
            final Map<String, dynamic>? dataMap = inner is Map<String, dynamic>
                ? inner
                : null;

            dynamic v = res['NFC_status'] ?? res['nfc_status'];
            v ??= dataMap?['NFC_status'] ?? dataMap?['nfc_status'];

            // NOTE: Do NOT fall back to res['status'] here; many APIs use that
            // for request status (e.g., "success"), which would incorrectly
            // mark NFC as active.
            bool parsed = false;
            if (v is bool) parsed = v;
            if (v is num) parsed = v != 0;
            if (v is String) {
              final s = v.toLowerCase().trim();
              parsed =
                  s == '1' || s == 'true' || s == 'active' || s == 'enabled';
            }
            statuses.add(parsed);
          } catch (_) {
            statuses.add(false);
          }
        }),
      );
      isNfcActive = statuses.any((e) => e);
    }

    final isPalmEnrolled = _parseIsPalmEnrolled(palmEnrollJson, userCardsJson);

    return _PaymentMethodsData(
      user: user,
      firstPaymentMethod: methods.isNotEmpty ? methods.first : null,
      isNfcActive: isNfcActive,
      isPalmEnrolled: isPalmEnrolled,
    );
  }

  bool _parseIsPalmEnrolled(
    Map<String, dynamic> palmEnrollJson,
    Map<String, dynamic> userCardsJson,
  ) {
    final candidates = [
      palmEnrollJson['is_enrolled'],
      palmEnrollJson['palm_vein_enrolled'],
      palmEnrollJson['is_palm_enrolled'],
      palmEnrollJson['palmEnrolled'],
      userCardsJson['palm_vein_enrolled'],
      userCardsJson['is_palm_enrolled'],
      userCardsJson['palmEnrolled'],
    ];

    for (final value in candidates) {
      if (value is bool) return value;
      if (value is String) {
        final lowered = value.toLowerCase();
        if (lowered == 'true') return true;
        if (lowered == 'false') return false;
      }
      if (value is num) {
        if (value == 1) return true;
        if (value == 0) return false;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
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
              )
            : null,
        title: Text(
          l10n.t('payment_methods'),
          style: ATextTheme.textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<_PaymentMethodsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data!;

          return Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 24),
            child: Column(
              children: [
                InkWell(
                  onTap: () => context.push(AppRoutes.paymentMethodsQrPath),
                  child: PaymentMethodCard(
                    title: l10n.t('qr_code'),
                    subtitle: l10n.t('scan_to_pay'),
                    icon: Icons.qr_code,
                    iconColor: const Color(0xFF00AA44),
                    iconBackgroundColor: const Color(0xFFEFFDF5),
                    badgeText: l10n.t('available'),
                    badgeColor: const Color(0xFF00AA44),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => context.push(AppRoutes.paymentMethodsNfcPath),
                  child: PaymentMethodCard(
                    title: l10n.t('nfc_card'),
                    subtitle: l10n.t('contactless_payment'),
                    icon: Icons.credit_card,
                    iconColor: const Color(0xFF238EC2),
                    iconBackgroundColor: const Color(0xFFEFF6FF),
                    badgeText: data.isNfcActive
                        ? l10n.t('active')
                        : l10n.t('inactive'),
                    badgeColor: data.isNfcActive
                        ? const Color(0xFF238EC2)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => context.push(AppRoutes.paymentMethodsPalmPath),
                  child: PaymentMethodCard(
                    title: l10n.t('palm_vein'),
                    subtitle: l10n.t('biometric_payment'),
                    icon: Icons.fingerprint,
                    iconColor: const Color(0xFF7C3AED),
                    iconBackgroundColor: const Color(0xFFF5F3FF),
                    badgeText: data.isPalmEnrolled
                        ? l10n.t('enrolled')
                        : l10n.t('not_enrolled'),
                    badgeColor: data.isPalmEnrolled
                        ? const Color(0xFF00AA44)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PaymentMethodsData {
  final UserModel user;
  final PaymentMethod? firstPaymentMethod;
  final bool isNfcActive;
  final bool isPalmEnrolled;

  const _PaymentMethodsData({
    required this.user,
    required this.firstPaymentMethod,
    required this.isNfcActive,
    required this.isPalmEnrolled,
  });
}
