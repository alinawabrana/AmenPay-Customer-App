import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palmpay/app_routes.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/services/api_service.dart';
import 'package:palmpay/utils/themes/text_theme.dart';

import '../../authentication/models/profile/user_model.dart';
import '../../home/models/QR Code/payment_method_model.dart';
import '../providers/payment_methods_refresh_provider.dart';

class PalmVeinScreen extends ConsumerStatefulWidget {
  const PalmVeinScreen({super.key});

  @override
  ConsumerState<PalmVeinScreen> createState() => _PalmVeinScreenState();
}

class _PalmVeinScreenState extends ConsumerState<PalmVeinScreen> {
  late final Future<_PalmVeinData> _future;

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

  Future<_PalmVeinData> _load() async {
    final results = await Future.wait([
      ApiService.getUserDetails(),
      ApiService.getPaymentMethods(),
      ApiService.getPalmEnrollMeStatus(),
    ]);

    final user = results[0] as UserModel;
    final paymentMethodsJson = results[1] as Map<String, dynamic>;
    final palmEnrollJson = results[2] as Map<String, dynamic>;

    final paymentResponse = PaymentMethodsResponse.fromJson(paymentMethodsJson);
    final methods = paymentResponse.paymentMethods;

    var enrolledByMethod = _extractEnrollmentByMethod(palmEnrollJson);
    if (enrolledByMethod.isEmpty) {
      final globalEnrolled = _inferPalmEnrollment(palmEnrollJson);
      if (globalEnrolled) {
        enrolledByMethod = {
          for (final m in methods) m.id: true,
        };
      }
    }
    if (kDebugMode) {
      // ignore: avoid_print
      print('PALM ENROLL → raw status: $palmEnrollJson');
      // ignore: avoid_print
      print('PALM ENROLL → per-method map: $enrolledByMethod');
    }

    return _PalmVeinData(
      user: user,
      paymentMethods: methods,
      enrolledByMethod: enrolledByMethod,
    );
  }

  bool _inferPalmEnrollment(Map<String, dynamic> json) {
    final candidates = [
      json['palm_vein_enrolled'],
      json['is_palm_enrolled'],
      json['palmEnrolled'],
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

  Map<int, bool> _extractEnrollmentByMethod(Map<String, dynamic> res) {
    final map = <int, bool>{};
      final root = res['data'] is Map<String, dynamic>
          ? (res['data'] as Map<String, dynamic>)
          : res;

    final listCandidates = [
      root['payment_methods'],
      root['cards'],
      root['enrollments'],
      res['payment_methods'],
      res['cards'],
      res['enrollments'],
    ];

    for (final raw in listCandidates) {
      if (raw is! List) continue;
      for (final item in raw) {
        if (item is! Map<String, dynamic>) continue;
        final id = _readMethodId(item);
        final enrolled = _readEnrolledFlag(item);
        if (id != null && enrolled != null) {
          map[id] = enrolled;
        }
        final cardId = _coerceId(item['card_id'] ?? item['cardId']);
        if (cardId != null && enrolled != null) {
          map[cardId] = enrolled;
        }
      }
    }

    final enrolledIdsRaw = root['enrolled_methods'] ??
        root['enrolled_payment_methods'] ??
        root['enrolled_ids'];
    if (enrolledIdsRaw is List) {
      for (final v in enrolledIdsRaw) {
        if (v is Map<String, dynamic>) {
          final id = _readMethodId(v);
          if (id != null) {
            map[id] = _readEnrolledFlag(v) ?? true;
          }
          continue;
        }
        final id = _coerceId(v);
        if (id != null) {
          map[id] = true;
        }
      }
    }
    if (enrolledIdsRaw is Map) {
      for (final entry in enrolledIdsRaw.values) {
        if (entry is Map<String, dynamic>) {
          final id = _readMethodId(entry);
          if (id != null) {
            map[id] = _readEnrolledFlag(entry) ?? true;
          }
        } else {
          final id = _coerceId(entry);
          if (id != null) {
            map[id] = true;
          }
        }
      }
    }

    final notEnrolledIdsRaw =
        root['not_enrolled_methods'] ?? root['not_enrolled_ids'];
    if (notEnrolledIdsRaw is List) {
      for (final v in notEnrolledIdsRaw) {
        final id = _coerceId(v);
        if (id != null && !map.containsKey(id)) {
          map[id] = false;
        }
      }
    }

    return map;
  }

  int? _coerceId(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  int? _readMethodId(Map<String, dynamic> item) {
    return _coerceId(
      item['payment_method_id'] ??
          item['paymentMethodId'] ??
          item['payment_method'] ??
          item['method_id'] ??
          item['id'],
    );
  }

  bool? _readEnrolledFlag(Map<String, dynamic> item) {
    final candidates = [
      item['is_enrolled'],
      item['palm_vein_enrolled'],
      item['is_palm_enrolled'],
      item['palmEnrolled'],
      item['enrolled'],
      item['status'],
    ];

    for (final value in candidates) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final lowered = value.toLowerCase().trim();
        if (lowered == 'enrolled') return true;
        if (lowered == 'not_enrolled') return false;
        if (lowered == 'true' || lowered == '1') return true;
        if (lowered == 'false' || lowered == '0') return false;
      }
    }

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
          l10n.t('palm_vein'),
          style: ATextTheme.textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<_PalmVeinData>(
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
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final methods = data.paymentMethods;

          if (methods.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.t('no_payment_methods_found'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.t('palm_vein'),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: methods.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final method = methods[index];
                      final enrolled =
                          data.enrolledByMethod[method.id] ??
                          (method.cardId != null
                              ? data.enrolledByMethod[method.cardId]
                              : null) ??
                          false;
                      return _PalmPaymentMethodCard(
                        method: method,
                        enrolled: enrolled,
                        onEnroll: enrolled
                            ? null
                            : () => _showEnrollSheet(context, method),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEnrollSheet(BuildContext context, PaymentMethod method) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.t('not_currently_enrolled'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              height: 28 / 18,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.t('enroll_palm_vein_description'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF4B5563),
                        height: 23 / 14,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          context.push(
                            AppRoutes.paymentMethodsPalmEnrollPath,
                            extra: {
                              'payment_method_id': method.id,
                              'card_id': method.cardId,
                            },
                          );
                        },
                        child: Text(l10n.t('enroll_now')),
                      ),
                    ),
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

class _PalmVeinData {
  final UserModel user;
  final List<PaymentMethod> paymentMethods;
  final Map<int, bool> enrolledByMethod;

  const _PalmVeinData({
    required this.user,
    required this.paymentMethods,
    required this.enrolledByMethod,
  });
}

class _PalmPaymentMethodCard extends StatelessWidget {
  final PaymentMethod method;
  final bool enrolled;
  final VoidCallback? onEnroll;

  const _PalmPaymentMethodCard({
    required this.method,
    required this.enrolled,
    required this.onEnroll,
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
    final maskedCard = _maskAccountNumber(method.cardNumber);

    final badgeText = enrolled ? l10n.t('enrolled') : l10n.t('not_enrolled');
    final badgeColor =
        enrolled ? const Color(0xFF00AA44) : const Color(0xFFB91C1C);
    final badgeBg = enrolled
        ? const Color(0xFF00AA44).withAlpha(26)
        : const Color(0xFFB91C1C).withAlpha(26);

    return InkWell(
      onTap: onEnroll,
      borderRadius: BorderRadius.circular(16),
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
                  Text(
                    method.cardHolderName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    maskedCard,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
