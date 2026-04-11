import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:palmpay/app_routes.dart';
import 'package:palmpay/l10n/app_localizations.dart';

class AppNavigation {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.loadingPath,
    routes: AppRoutes.routes(
      tabShellBuilder: (context, state, navigationShell) {
        return _TabbedScaffold(navigationShell: navigationShell);
      },
    ),
  );
}

class _TabbedScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _TabbedScaffold({required this.navigationShell});

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottomTheme = theme.bottomNavigationBarTheme;

    final activeColor = bottomTheme.selectedItemColor ?? theme.primaryColor;
    const inactiveColor = Color(0xFF9CA3AF);

    final selectedLabelStyle =
        bottomTheme.selectedLabelStyle ??
        const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.5,
        );

    final unselectedLabelStyle =
        bottomTheme.unselectedLabelStyle ??
        const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.5,
        );

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        height: 73,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BottomNavItem(
                label: l10n.t('nav_home'),
                isActive: navigationShell.currentIndex == 0,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                selectedLabelStyle: selectedLabelStyle,
                unselectedLabelStyle: unselectedLabelStyle,
                activeIconSize: const Size(20, 18),
                inactiveIconSize: const Size(18, 15.75),
                icon: Icons.home_outlined,
                onTap: () => _onTap(0),
              ),
              _BottomNavItem(
                label: l10n.t('nav_analytics'),
                isActive: navigationShell.currentIndex == 1,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                selectedLabelStyle: selectedLabelStyle,
                unselectedLabelStyle: unselectedLabelStyle,
                activeIconSize: const Size(20, 18),
                inactiveIconSize: const Size(18, 15.75),
                icon: Icons.analytics_outlined,
                onTap: () => _onTap(1),
              ),
              _BottomNavItem(
                label: l10n.t('nav_card'),
                isActive: navigationShell.currentIndex == 2,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                selectedLabelStyle: selectedLabelStyle,
                unselectedLabelStyle: unselectedLabelStyle,
                activeIconSize: const Size(20, 18),
                inactiveIconSize: const Size(18, 15.75),
                icon: Icons.credit_card_outlined,
                onTap: () => _onTap(2),
              ),
              _BottomNavItem(
                label: l10n.t('nav_settings'),
                isActive: navigationShell.currentIndex == 3,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                selectedLabelStyle: selectedLabelStyle,
                unselectedLabelStyle: unselectedLabelStyle,
                activeIconSize: const Size(20, 18),
                inactiveIconSize: const Size(18, 15.75),
                icon: Icons.settings_outlined,
                onTap: () => _onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final TextStyle selectedLabelStyle;
  final TextStyle unselectedLabelStyle;
  final Size activeIconSize;
  final Size inactiveIconSize;
  final IconData icon;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.selectedLabelStyle,
    required this.unselectedLabelStyle,
    required this.activeIconSize,
    required this.inactiveIconSize,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;
    final iconSize = isActive ? activeIconSize : inactiveIconSize;
    final textStyle = isActive ? selectedLabelStyle : unselectedLabelStyle;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: iconSize.width,
              height: iconSize.height,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Icon(icon, color: color),
              ),
            ),
            const SizedBox(height: 6),
            Text(label, style: textStyle.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
