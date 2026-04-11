import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palmpay/app_routes.dart';
import 'package:palmpay/utils/constants/image_text.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/services/api_service.dart';
import 'package:palmpay/widgets/language_chip.dart';

import 'package:palmpay/features/settings/providers/notification_refresh_provider.dart';
import 'package:palmpay/features/settings/providers/profile_refresh_provider.dart';
import 'package:palmpay/features/authentication/models/profile/user_model.dart';

/// Custom app bar with hamburger menu, title, avatar, and logout
class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: const SizedBox.shrink(),
      leadingWidth: 0,
      title: Text(
        l10n.t('app_name'),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.0,
          letterSpacing: -0.5,
          color: Color(0xFF333333),
        ),
      ),
      centerTitle: true,
      actions: [
        const Padding(
          padding: EdgeInsetsDirectional.only(end: 8),
          child: LanguageChip(compact: true),
        ),
        const _NotificationAction(),
        const _ProfileAvatarAction(),
      ],
    );
  }
}

class _NotificationAction extends ConsumerWidget {
  const _NotificationAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationRefreshProvider);

    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getUnreadNotificationsCount(),
      builder: (context, snapshot) {
        final unreadCount = (snapshot.data?['unread_count'] as num?)?.toInt() ?? 0;

        return GestureDetector(
          onTap: () => context.push(AppRoutes.notificationsPath),
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsetsDirectional.only(end: 12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                    color: const Color(0xFFF9FAFB),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    size: 20,
                    color: Color(0xFF4B5563),
                  ),
                ),
                if (unreadCount > 0)
                  PositionedDirectional(
                    top: -1,
                    end: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileAvatarAction extends ConsumerStatefulWidget {
  const _ProfileAvatarAction();

  @override
  ConsumerState<_ProfileAvatarAction> createState() =>
      _ProfileAvatarActionState();
}

class _ProfileAvatarActionState extends ConsumerState<_ProfileAvatarAction> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
    ref.listenManual<int>(profileRefreshProvider, (previous, next) {
      setState(() {
        _future = _load();
      });
    });
  }

  Future<List<dynamic>> _load() {
    return Future.wait<dynamic>([
      ApiService.getUserDetails(),
      ApiService.getProfileImage(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        String? url;
        final data = snapshot.data;
        if (data != null && data.length >= 2) {
          final user = data[0];
          final imageRes = data[1];

          if (imageRes is Map<String, dynamic>) {
            final v = imageRes['image_url'] ?? imageRes['imageUrl'];
            if (v is String && v.trim().isNotEmpty) {
              url = ApiService.normalizePublicImageUrl(v);
            }
          }

          if (url == null &&
              user is UserModel &&
              (user.image?.trim().isNotEmpty ?? false)) {
            url = ApiService.normalizePublicImageUrl(user.image);
          }
        }

        final ImageProvider avatarProvider = (url == null)
            ? const AssetImage(AImageText.palmPayLogo)
            : NetworkImage(url);

        return GestureDetector(
          onTap: () => context.go(AppRoutes.settingsPath),
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsetsDirectional.only(end: 20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              color: const Color(0xFFF3F4F6),
              image: DecorationImage(
                image: avatarProvider,
                fit: BoxFit.cover,
                onError: (_, __) {},
              ),
            ),
          ),
        );
      },
    );
  }
}
