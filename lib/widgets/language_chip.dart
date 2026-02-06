import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_provider.dart';

class LanguageChip extends ConsumerWidget {
  final bool compact;

  const LanguageChip({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);

    final selected = locale.languageCode;

    Future<void> setLang(String code) async {
      if (selected == code) return;

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const _LanguageLoadingDialog();
        },
      );

      try {
        await ref.read(localeProvider.notifier).setLanguageCode(code);
      } finally {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
    }

    final chipTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: compact ? 11 : 12,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangChoice(
            label: 'AR',
            tooltip: l10n.t('arabic'),
            isSelected: selected == 'ar',
            onTap: () => setLang('ar'),
            textStyle: chipTextStyle,
          ),
          const SizedBox(width: 4),
          _LangChoice(
            label: 'EN',
            tooltip: l10n.t('english'),
            isSelected: selected == 'en',
            onTap: () => setLang('en'),
            textStyle: chipTextStyle,
          ),
        ],
      ),
    );
  }
}

class _LanguageLoadingDialog extends StatelessWidget {
  const _LanguageLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 18),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context).t('changing_language'),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.start,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangChoice extends StatelessWidget {
  final String label;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;
  final TextStyle? textStyle;

  const _LangChoice({
    required this.label,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isSelected ? const Color(0xFF238EC2) : Colors.transparent;
    final fg = isSelected ? Colors.white : const Color(0xFF4B5563);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: textStyle?.copyWith(color: fg) ?? TextStyle(color: fg),
          ),
        ),
      ),
    );
  }
}
