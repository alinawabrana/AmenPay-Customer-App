import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palmpay/app_routes.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/services/api_service.dart';
import 'package:palmpay/utils/themes/text_theme.dart';

import '../../authentication/models/profile/user_model.dart';

class PalmVeinScreen extends StatefulWidget {
  const PalmVeinScreen({super.key});

  @override
  State<PalmVeinScreen> createState() => _PalmVeinScreenState();
}

class _PalmVeinScreenState extends State<PalmVeinScreen> {
  late final Future<_PalmVeinData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_PalmVeinData> _load() async {
    final results = await Future.wait([
      ApiService.getUserDetails(),
      ApiService.getUserCards(),
    ]);

    final user = results[0] as UserModel;
    final userCardsJson = results[1] as Map<String, dynamic>;

    final enrolled = _inferPalmEnrollment(userCardsJson);

    return _PalmVeinData(user: user, enrolled: enrolled);
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

          if (!data.enrolled) {
            return Center(
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.t('not_currently_enrolled'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        height: 28 / 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.t('enroll_palm_vein_description'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF4B5563),
                        height: 23 / 14,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 220,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => context.push(
                          AppRoutes.paymentMethodsPalmEnrollPath,
                        ),
                        child: Text(l10n.t('enroll_now')),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  padding: const EdgeInsetsDirectional.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00AA44).withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.t('enrolled'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                            color: Color(0xFF00AA44),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          data.user.fullname,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 20 / 14,
                            letterSpacing: -0.5,
                            color: const Color(0xFF333333),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.t('palm_vein_ready'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF4B5563),
                    height: 23 / 14,
                    letterSpacing: -0.5,
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

class _PalmVeinData {
  final UserModel user;
  final bool enrolled;

  const _PalmVeinData({required this.user, required this.enrolled});
}
