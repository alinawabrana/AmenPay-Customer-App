import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/services/api_service.dart';
import 'package:palmpay/utils/constants/image_text.dart';
import 'package:palmpay/widgets/language_chip.dart';

import 'package:palmpay/features/settings/providers/profile_refresh_provider.dart';

/// Custom app bar with hamburger menu, title, avatar, and logout
class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    ref.watch(profileRefreshProvider);

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

        /// Profile Avatar
        FutureBuilder<Map<String, dynamic>>(
          future: ApiService.getProfileImage(),
          builder: (context, snapshot) {
            String? url;
            final data = snapshot.data;
            final v = (data == null)
                ? null
                : (data['image_url'] ?? data['imageUrl']);
            if (v is String && v.trim().isNotEmpty) {
              url = ApiService.normalizePublicImageUrl(v);
            }

            final ImageProvider imageProvider = (url == null)
                ? const AssetImage(AImageText.palmPayLogo)
                : NetworkImage(url);

            return Container(
              width: 36,
              height: 36,
              margin: const EdgeInsetsDirectional.only(end: 20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
              ),
              child: (url == null)
                  ? ClipOval(
                      child: Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.person,
                          size: 20,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    )
                  : null,
            );
          },
        ),
      ],
    );
  }
}
