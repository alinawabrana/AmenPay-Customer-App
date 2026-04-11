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
import '../models/nfc_payment_method_status_model.dart';

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
      ApiService.getPaymentMethodsWithStatus(),
      ApiService.getUserCards(),
      ApiService.getPalmEnrollMeStatus(),
    ]);

    final user = results[0] as UserModel;
    final paymentMethodsJson = results[1] as Map<String, dynamic>;
    final userCardsJson = results[2] as Map<String, dynamic>;
    final palmEnrollJson = results[3] as Map<String, dynamic>;

    final methodsRaw = paymentMethodsJson['payment_methods'];
    final methods = methodsRaw is List
        ? methodsRaw
              .whereType<Map<String, dynamic>>()
              .map(NfcPaymentMethodStatus.fromJson)
              .toList()
        : <NfcPaymentMethodStatus>[];

    final nfcBadge = _deriveNfcBadge(methods);

    final isPalmEnrolled = _parseIsPalmEnrolled(
      methods,
      palmEnrollJson,
      userCardsJson,
    );

    return _PaymentMethodsData(
      user: user,
      nfcBadge: nfcBadge,
      isPalmEnrolled: isPalmEnrolled,
    );
  }

  _NfcBadgeState _deriveNfcBadge(List<NfcPaymentMethodStatus> methods) {
    if (methods.any((m) => m.isNfcActive)) return _NfcBadgeState.active;
    if (methods.any((m) => m.isNfcEnrolledKnown)) {
      return _NfcBadgeState.inactive;
    }
    return _NfcBadgeState.notEnrolled;
  }

  bool _parseIsPalmEnrolled(
    List<NfcPaymentMethodStatus> methods,
    Map<String, dynamic> palmEnrollJson,
    Map<String, dynamic> userCardsJson,
  ) {
    if (methods.any((m) => m.palmEnrolled)) {
      return true;
    }

    final palmData = palmEnrollJson['data'] is Map<String, dynamic>
        ? (palmEnrollJson['data'] as Map<String, dynamic>)
        : palmEnrollJson;

    final enrolledList = palmData['enrolled_methods'] ??
        palmData['enrolled_payment_methods'] ??
        palmData['enrolled_ids'];
    if (enrolledList is List && enrolledList.isNotEmpty) {
      return true;
    }
    if (enrolledList is Map && enrolledList.isNotEmpty) {
      return true;
    }

    final enrolledCount = palmData['enrolled_count'];
    if (enrolledCount is num && enrolledCount > 0) {
      return true;
    }

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
                    badgeText: switch (data.nfcBadge) {
                      _NfcBadgeState.active => l10n.t('active'),
                      _NfcBadgeState.inactive => l10n.t('inactive'),
                      _NfcBadgeState.notEnrolled => l10n.t('not_enrolled'),
                    },
                    badgeColor: switch (data.nfcBadge) {
                      _NfcBadgeState.active => const Color(0xFF238EC2),
                      _NfcBadgeState.inactive => const Color(0xFF9CA3AF),
                      _NfcBadgeState.notEnrolled => const Color(0xFF9CA3AF),
                    },
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
  final _NfcBadgeState nfcBadge;
  final bool isPalmEnrolled;

  const _PaymentMethodsData({
    required this.user,
    required this.nfcBadge,
    required this.isPalmEnrolled,
  });
}

enum _NfcBadgeState { active, inactive, notEnrolled }
